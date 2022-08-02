-- function to view balance
-- input : account no, uname, pass
CREATE OR REPLACE FUNCTION view_balance(id INT, uname VARCHAR(50), pword VARCHAR(50))
RETURNS void
AS $view_balance$
DECLARE
    temp_balance NUMERIC(12, 2);
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
    BEGIN
       IF EXISTS (SELECT balance FROM account WHERE account_no = id) THEN
          SELECT balance INTO temp_balance FROM account WHERE account_no = id;
          RAISE NOTICE 'Balance amount in the account : %', temp_balance;
       ELSE
          RAISE NOTICE 'Account doesnot exist. Check input account number!';
       END IF;
    END;
    ELSE
        RAISE NOTICE 'Cannot find account number. Check username and password!';
    END IF;
END;
$view_balance$ LANGUAGE plpgsql
SECURITY DEFINER;

-- function to check who all a particular employee assists
-- input : emp ID
CREATE OR REPLACE FUNCTION employee_assists(id INT)
RETURNS TABLE (
    customer_id INT,
    customer_name VARCHAR(100),
    account_no INT
)
AS $employee_assists$
BEGIN
    IF EXISTS (SELECT id FROM customer WHERE emp_id = id) THEN
        RETURN QUERY
        SELECT customer.cust_id, customer.cust_name, customer_account.account_no FROM (customer NATURAL JOIN customer_account) WHERE emp_id = id;
    ELSE
        RAISE NOTICE 'Employee does not assist any customer!';
    END IF;
END;
$employee_assists$ LANGUAGE plpgsql;

-- function to show transaction log
-- input : account no, start, end, uname, pass
CREATE OR REPLACE FUNCTION show_transaction_log(id INT, startDate DATE, endDate DATE, uname VARCHAR(50), pword VARCHAR(50))
RETURNS TABLE (
    transaction_id INT,
    transaction_type VARCHAR(50),
    transaction_amount NUMERIC(12, 2),
    transaction_date TIMESTAMP WITHOUT TIME ZONE,
    receiver_account_no INT,
    employee_id INT
)
AS $show_transaction_log$
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
    BEGIN
        IF EXISTS (SELECT account_no FROM account WHERE account_no = id) THEN
           RETURN QUERY
           SELECT trans_id, trans_type, trans_amt, trans_date, r_account_no, emp_id FROM transactions
           WHERE account_no = id AND trans_date BETWEEN startDate AND endDate;
        ELSE
            RAISE NOTICE 'Account number not found! Check and try again';
        END IF;
    END;
    ELSE
        RAISE NOTICE 'Cannot find account number! Check username and password!';
    END IF;
END;
$show_transaction_log$ LANGUAGE plpgsql
SECURITY DEFINER;

-- function to show payment log
-- input : loan ID, start, end, uname, pass
CREATE OR REPLACE FUNCTION show_payment_log(id INT, startDate DATE, endDate DATE, uname VARCHAR(50), pword VARCHAR(50))
RETURNS TABLE (
    payment_amount NUMERIC(12, 2),
    payment_date TIMESTAMP WITHOUT TIME ZONE,
    interest NUMERIC(4, 2)
)
AS $show_payment_log$
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
    BEGIN
        IF EXISTS (SELECT loan_id FROM payment WHERE loan_id = id) THEN
           RETURN QUERY
           SELECT pay_amount, pay_date, loan_interest FROM payment
           WHERE loan_id = id AND pay_date BETWEEN startDate AND endDate;
        ELSE
           RAISE NOTICE 'Loan ID not found! Check and try again';
        END IF;
    END;
    ELSE
        RAISE NOTICE 'Cannot find loan ID! Check username and password!';
    END IF;
END;
$show_payment_log$ LANGUAGE plpgsql
SECURITY DEFINER;

-- TRIGGERS
CREATE OR REPLACE FUNCTION check_interest()
RETURNS trigger
AS $check_interest$
DECLARE
    interest_percent NUMERIC(4,2);
BEGIN
    SELECT interest_rate INTO interest_percent FROM loan WHERE loan_id = new.loan_id;
    IF (interest_percent > new.loan_interest OR interest_percent < new.loan_interest) THEN
        RAISE NOTICE 'Incorrect interest rate!';
    END IF;
    RETURN NEW;
END;
$check_interest$ LANGUAGE plpgsql;

CREATE trigger loan_update
BEFORE INSERT
ON payment
FOR EACH row
EXECUTE PROCEDURE check_interest();

