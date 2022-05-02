-- creating the database for bank
-- CREATE DATABASE banking_system;

-- command to run the entire file : psql -U <user> -d <database> -f <filepath>

-- bank table
CREATE TABLE bank(
    bank_id SERIAL,
    bank_name VARCHAR(100) NOT NULL,
    bank_address TEXT NOT NULL,
    CONSTRAINT bank_pkey PRIMARY KEY (bank_id)
);

-- branch table
CREATE TABLE branch(
    branch_id SERIAL,
    branch_name VARCHAR(100) NOT NULL,
    branch_address TEXT NOT NULL,
    bank_id INT NOT NULL,
    CONSTRAINT branch_pkey PRIMARY KEY (branch_id),
    CONSTRAINT bank_fk FOREIGN KEY (bank_id) REFERENCES bank (bank_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- login/access table
CREATE TABLE access(
    login_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(50) NOT NULL
);

-- employee table
CREATE TABLE employee(
    emp_id SERIAL,
    emp_name VARCHAR(100) NOT NULL,
    emp_address TEXT NOT NULL,
    emp_salary INT NOT NULL check(emp_salary >= 10000 AND emp_salary <= 1000000),
    emp_DOB DATE NOT NULL check(date_part('year', AGE(emp_DOB)) >= 18),
    branch_id INT NOT NULL,
    login_id INT NOT NULL,
    CONSTRAINT employee_pkey PRIMARY KEY (emp_id),
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT access_fk FOREIGN KEY (login_id) REFERENCES access (login_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- account table
CREATE TABLE account(
    account_no SERIAL PRIMARY KEY,
    account_type VARCHAR(25) NOT NULL check(account_type = 'savings' OR account_type = 'checkings' OR account_type = 'loan'),
    balance NUMERIC(12, 2) NOT NULL,
    branch_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- loan table
CREATE TABLE loan(
    loan_id SERIAL PRIMARY KEY,
    loan_type VARCHAR(25) NOT NULL check(loan_type = 'personal' OR loan_type = 'business' OR loan_type = 'home' OR loan_type = 'student' OR loan_type = 'automobile'),
    loan_status INT, -- If active 1, else 0
    amount NUMERIC(12, 2) NOT NULL check(amount >= 1000.0 AND amount <=10000000.0),
    interest_rate NUMERIC(4, 2) NOT NULL check(interest_rate >= 3.0 AND interest_rate <= 12.5),
    branch_id INT NOT NULL,
    emp_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- customer table
CREATE TABLE customer(
    cust_id SERIAL unique,
    cust_name VARCHAR(100) NOT NULL,
    cust_address TEXT NOT NULL,
    cust_DOB DATE NOT NULL check(date_part('year', AGE(cust_DOB)) >= 18), -- change this to DOB and take difference
    emp_id INT NOT NULL,
    login_id INT NOT NULL,
    CONSTRAINT customer_pkey PRIMARY KEY (cust_id),
    CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT access_fk FOREIGN KEY (login_id) REFERENCES access (login_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- customer-phone table
CREATE TABLE customer_phoneno(
    cust_id INT,
    cust_phoneno VARCHAR(10) UNIQUE check (cust_phoneno ~* '\d\d\d\d\d\d\d\d\d\d'),
    PRIMARY KEY (cust_id, cust_phoneno),
    CONSTRAINT cont_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- customer-account table
CREATE TABLE customer_account(
    cust_id INT,
    account_no INT,
    PRIMARY KEY (cust_id, account_no),
    CONSTRAINT cust_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT acc_fc FOREIGN KEY (account_no) REFERENCES account (account_no) ON UPDATE CASCADE ON DELETE CASCADE
);

-- customer-loan table
CREATE TABLE customer_loan(
    cust_id INT,
    loan_id INT,
    PRIMARY KEY (cust_id, loan_id),
    CONSTRAINT cust_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT loan_fk FOREIGN KEY (loan_id) REFERENCES loan (loan_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- branch-loan table
CREATE TABLE branch_loan(
    branch_id INT,
    loan_id INT,
    PRIMARY KEY (branch_id, loan_id),
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT loan_fk FOREIGN KEY (loan_id) REFERENCES loan (loan_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- payment table
CREATE TABLE payment(
       pay_id SERIAL PRIMARY KEY,
       pay_amount NUMERIC(12, 2) NOT NULL check(pay_amount >= 100.0),
       pay_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
       loan_interest NUMERIC(4, 2) NOT NULL,
       loan_id INT NOT NULL,
       CONSTRAINT loan_fk FOREIGN KEY (loan_id) REFERENCES loan (loan_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- transaction table
CREATE TABLE transactions(
       trans_id SERIAL PRIMARY KEY,
       trans_type VARCHAR(50) NOT NULL check(trans_type = 'deposit' OR trans_type = 'withdraw' OR trans_type = 'transfer' OR trans_type = 'loan payment'),
       trans_amt NUMERIC(12, 2) NOT NULL check(trans_amt >= 100.0),
       trans_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
       account_no INT NOT NULL,
       r_account_no INT DEFAULT NULL, -- for reciever account when the tracnsaction is of the type "transfer"
       cust_id INT NOT NULL,
       emp_id INT NOT NULL,
       login_id INT NOT NULL,
       CONSTRAINT acc_fk FOREIGN KEY (account_no) REFERENCES account (account_no) ON UPDATE CASCADE ON DELETE CASCADE,
       CONSTRAINT cust_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE,
       CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT,
       CONSTRAINT login_fk FOREIGN KEY (login_id) REFERENCES access (login_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- login-account table
CREATE TABLE access_account(
       login_id INT NOT NULL,
       account_no INT NOT NULL,
       PRIMARY KEY (login_id, account_no),
       CONSTRAINT login_fk FOREIGN KEY (login_id) REFERENCES access (login_id) ON UPDATE CASCADE ON DELETE RESTRICT,
       CONSTRAINT acc_fk FOREIGN KEY (account_no) REFERENCES account (account_no) ON UPDATE CASCADE ON DELETE CASCADE
);

-- procedure to create an account
-- input : name, address, DOB, phone nos, account type, emp id, branch id
CREATE OR REPLACE PROCEDURE create_account(
   c_name VARCHAR(100),
   c_add TEXT,
   c_DOB DATE,
   c_phone VARCHAR(10)[],
   a_type VARCHAR(25),
   e_id INT,
   b_id INT
)
AS $create_account$
DECLARE
    temp_lid INT;
    temp_ano INT;
    temp_cid INT;
    temp_uname VARCHAR(100);
    temp_pass VARCHAR(50);
    temp_len INT;
BEGIN
    -- creating username and password
    SELECT * INTO temp_uname FROM CAST(md5(random()::TEXT) AS VARCHAR(100));
    SELECT * INTO temp_pass FROM CAST(md5(random()::TEXT) AS VARCHAR(50));
    SELECT * INTO temp_len FROM array_length(c_phone, 1);
    -- checking number of phone numbers
    IF (temp_len = 1 OR temp_len = 2) THEN
    BEGIN
        INSERT INTO access (username, password) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
        INSERT INTO customer (cust_name, cust_address, cust_DOB, emp_id, login_id) VALUES (c_name, c_add, c_DOB, e_id, temp_lid) RETURNING cust_id INTO temp_cid;
        INSERT INTO customer_phoneno (cust_id, cust_phoneno) SELECT temp_cid, UNNEST(c_phone);
        INSERT INTO account (account_type, balance, branch_id) VALUES (a_type, 500, b_id) RETURNING account_no INTO temp_ano;
        INSERT INTO access_account VALUES (temp_lid, temp_ano);
        INSERT INTO customer_account VALUES (temp_cid, temp_ano);
        EXECUTE 'CREATE USER "'||c_name||'"';
        EXECUTE 'GRANT customer TO "'||c_name||'"';
        RAISE NOTICE 'Sucessfully create account! Please note down the following credentials :
          Account number : %
          Customer ID : %
          Username : %
          Password : %',
          temp_ano, temp_cid, temp_uname, temp_pass;
    END;
    ELSE
        RAISE NOTICE 'Only 1 or 2 phone numbers are allowed!';
    END IF;
END;
$create_account$ LANGUAGE plpgsql;

-- procedure to add an employee
-- input : name, address, salary, DOB, branch_id
CREATE OR REPLACE PROCEDURE add_employee(
    emp_name VARCHAR(100),
    emp_add TEXT,
    emp_salary INT,
    emp_DOB DATE,
    b_id INT
)
AS $add_employee$
DECLARE
    temp_lid INT;
    temp_eid INT;
    temp_uname VARCHAR(100);
    temp_pass VARCHAR(50);
BEGIN
    -- creating username and password
    SELECT * INTO temp_uname FROM CAST(md5(random()::TEXT) AS VARCHAR(100));
    SELECT * INTO temp_pass FROM CAST(md5(random()::TEXT) AS VARCHAR(50));
    BEGIN
        INSERT INTO access (username, password) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
        INSERT INTO employee (emp_name, emp_address, emp_salary, emp_DOB, branch_id, login_id) VALUES (emp_name, emp_add, emp_salary, emp_DOB, b_id, temp_lid) RETURNING emp_id INTO temp_eid;
        EXECUTE 'CREATE USER "'||emp_name||'"';
        EXECUTE 'GRANT employee TO "'||emp_name||'"';
        RAISE NOTICE 'Sucessfully added employee! Please note down the following credentials :
          Employee ID : %
          Username : %
          Password : %',
          temp_eid, temp_uname, temp_pass;
    END;
END;
$add_employee$ LANGUAGE plpgsql;

-- procedure to withdraw money from account
-- input : account no, amount, username, password
CREATE OR REPLACE PROCEDURE withdraw_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), pword VARCHAR(50))
AS $withdraw_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
    BEGIN
       IF EXISTS (SELECT balance FROM account WHERE account_no = id) THEN
          SELECT balance INTO temp_amt FROM account WHERE account_no = id;
          IF (temp_amt >= (amt + 500) AND amt <= 10000000) THEN
          BEGIN
            UPDATE account SET balance = balance - amt WHERE account_no = id;
            SELECT cust_id INTO temp_cid FROM customer_account WHERE account_no = id;
            SELECT emp_id INTO temp_eid FROM customer WHERE cust_id = temp_cid;
            SELECT login_id INTO temp_lid FROM access_account WHERE account_no = id;
            INSERT INTO transactions (trans_type, trans_amt, trans_date, account_no, cust_id, emp_id, login_id) VALUES
            ('withdraw', amt, now()::timestamp, id, temp_cid, temp_eid, temp_lid);
            RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt - amt);
          END;
          ELSE
            RAISE NOTICE 'Insufficient balance in account! Balance amount : %', temp_amt;
          END IF;
       ELSE
          RAISE NOTICE 'Account doesnot exist. Check input account number!';
       END IF;
   END;
   ELSE
       RAISE NOTICE 'Cannot find account number. Check username and password!';
   END IF;
END;
$withdraw_amount$ LANGUAGE plpgsql
SECURITY DEFINER;

-- procedure to deposit money
-- input : accout no, amount, username, password
CREATE OR REPLACE PROCEDURE deposit_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), pword VARCHAR(50))
AS $deposit_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
    BEGIN
        IF EXISTS (SELECT balance FROM account WHERE account_no = id) THEN
            SELECT balance INTO temp_amt FROM account WHERE account_no = id;
            IF (amt >= 500 AND amt <= 10000000) THEN
            BEGIN
                UPDATE account SET balance = balance + amt WHERE account_no = id;
                SELECT cust_id INTO temp_cid FROM customer_account WHERE account_no = id;
                SELECT emp_id INTO temp_eid FROM customer WHERE cust_id = temp_cid;
                SELECT login_id INTO temp_lid FROM access_account WHERE account_no = id;
                INSERT INTO transactions (trans_type, trans_amt, trans_date, account_no, cust_id, emp_id, login_id) VALUES
                ('deposit', amt, now()::timestamp, id, temp_cid, temp_eid, temp_lid);
                RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt + amt);
            END;
            ELSE
                RAISE NOTICE 'Cannot deposit this amount! Enter amount between 500 and 10000000';
            END IF;
        ELSE
            RAISE NOTICE 'Account doesnot exist. Check input account number!';
        END IF;
    END;
    ELSE
        RAISE NOTICE 'Cannot find account number. Check username and password!';
    END IF;
END;
$deposit_amount$ LANGUAGE plpgsql
SECURITY DEFINER;

-- procedure to transfer amount to another account
-- input : s_acc, r_acc, amt, username, password
CREATE OR REPLACE PROCEDURE transfer_amount(sender_id INT, receiver_id INT, amt NUMERIC(12, 2), uname VARCHAR(50), pword VARCHAR(50))
AS $transfer_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
    BEGIN
        IF EXISTS (SELECT account_no FROM access_account WHERE account_no = sender_id) AND EXISTS (SELECT account_no FROM access_account WHERE account_no = receiver_id) THEN
            SELECT balance INTO temp_amt FROM account WHERE account_no = sender_id;
            IF (temp_amt >= (amt + 500) AND amt <= 10000000) THEN
            BEGIN
                UPDATE account SET balance = balance - amt WHERE account_no = sender_id;
                UPDATE account SET balance = balance + amt WHERE account_no = receiver_id;
                SELECT cust_id INTO temp_cid FROM customer_account WHERE account_no = sender_id;
                SELECT emp_id INTO temp_eid FROM customer WHERE cust_id = temp_cid;
                SELECT login_id INTO temp_lid FROM access_account WHERE account_no = sender_id;
                INSERT INTO transactions (trans_type, trans_amt, trans_date, account_no, r_account_no, cust_id, emp_id, login_id) VALUES
                ('transfer', amt, now()::timestamp, sender_id, receiver_id, temp_cid, temp_eid, temp_lid);
                RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt - amt);
            END;
            ELSE
                RAISE NOTICE 'Unexpected error! Check account balance and withdrawal amount!';
            END IF;
        ELSE
            RAISE NOTICE 'Account numbers not found! Check and try again';
        END IF;
    END;
    ELSE
        RAISE NOTICE 'Cannot find account number! Check username and password!';
    END IF;
END;
$transfer_amount$ LANGUAGE plpgsql
SECURITY DEFINER;

-- procedure to create a loan account
-- input : name, add .... loan amt, loan type, loan interest 
CREATE OR REPLACE PROCEDURE create_loan_account(
   c_name VARCHAR(100),
   c_add TEXT,
   c_DOB DATE,
   c_phone VARCHAR(10)[],
   a_type VARCHAR(25),
   e_id INT,
   b_id INT,
   l_amt INT,
   l_type VARCHAR(25),
   l_int NUMERIC(4,2)
)
AS $create_account$
DECLARE
    temp_lid INT;
    temp_ano INT;   -- acc number
    temp_cid INT;   -- cust num
    temp_uname VARCHAR(100);    -- user name
    temp_pass VARCHAR(50);      -- password
    temp_len INT;               -- to store how many phone numbers are there
    temp_loanid INT;
BEGIN
    SELECT * INTO temp_uname FROM CAST(md5(random()::TEXT) AS VARCHAR(100));
    SELECT * INTO temp_pass FROM CAST(md5(random()::TEXT) AS VARCHAR(50));
    SELECT * INTO temp_len FROM array_length(c_phone, 1);
    IF ((temp_len = 1 OR temp_len = 2) AND l_amt >=1000.0 AND l_amt <= 10000000.0) THEN
       BEGIN
        -- this part is for account and customer table
        INSERT INTO access (username, password) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
        INSERT INTO customer (cust_name, cust_address, cust_DOB, emp_id, login_id) VALUES (c_name, c_add, c_DOB, e_id, temp_lid) RETURNING cust_id INTO temp_cid;
        INSERT INTO customer_phoneno (cust_id, cust_phoneno) SELECT temp_cid, UNNEST(c_phone);
        INSERT INTO account (account_type, balance, branch_id) VALUES (a_type, -l_amt - 24*l_int, b_id) RETURNING account_no INTO temp_ano;
        INSERT INTO access_account VALUES (temp_lid, temp_ano);
        INSERT INTO customer_account VALUES (temp_cid, temp_ano);
        -- loan table shit
        INSERT INTO loan (loan_type, loan_status, amount, interest_rate, branch_id, emp_id) VALUES (l_type, 1, l_amt, l_int, b_id, e_id) RETURNING loan_id INTO temp_loanid;
        INSERT INTO customer_loan (cust_id, loan_id) VALUES (temp_cid, temp_loanid);
        INSERT INTO branch_loan(branch_id, loan_id) VALUES (b_id, temp_loanid);
        SELECT cust_name INTO c_name FROM customer WHERE cust_id = temp_cid;
        EXECUTE 'CREATE USER "'||c_name||'"';
        EXECUTE 'GRANT customer TO "'||c_name||'"';
        RAISE NOTICE 'Sucessfully create account! Please note down the following credentials :
          Account number : %
          Customer ID : %
          Username : %
          Password : %
          Account type : %
          Loan ID : %',
          temp_ano, temp_cid, temp_uname, temp_pass, a_type, temp_loanid;
       END;
    ELSE
       BEGIN
        IF(temp_len >= 3) THEN
            RAISE NOTICE 'Only 1 or 2 phone numbers are allowed!';
        ELSE
            RAISE NOTICE 'You are only allowed to loan between 1000 to 10000000!';
        END IF;
       END;
    END IF;
END;
$create_account$ LANGUAGE plpgsql;

-- procedure to PAY LOANS
-- input : account_no, loan_id and amount
CREATE OR REPLACE PROCEDURE pay_loan(acc_no INT, lo_id INT, amt NUMERIC(12, 2))
AS $deposit_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_interest NUMERIC(4, 2);
    temp_cid INT;
    temp_lo_id INT;
    temp_eid INT;
    temp_lid INT;
    temp_aid INT;
    temp_l_status INT;
BEGIN
    IF EXISTS (SELECT cust_id FROM customer_loan WHERE loan_id = lo_id AND cust_id =  (SELECT cust_id FROM customer_account where account_no = acc_no)) THEN
        SELECT balance INTO temp_amt FROM account WHERE account_no = acc_no;
        SELECT loan_status INTO temp_l_status FROM loan WHERE loan_id = lo_id;
        SELECT interest_rate INTO temp_interest FROM loan WHERE loan_id = lo_id;
        -- SELECT loan_amt INTO tempFROM loan WHERE loan_id = lo_id
        IF (temp_l_status = 1) THEN
        BEGIN
            IF (amt>=1000.0 AND amt <= 10000000.0 AND -1*temp_amt >= amt) THEN
               BEGIN
                UPDATE account SET balance = balance + amt WHERE account_no = acc_no;
                SELECT cust_id INTO temp_cid FROM customer_account WHERE account_no = acc_no;
                SELECT emp_id INTO temp_eid FROM customer WHERE cust_id = temp_cid;
                SELECT login_id INTO temp_lid FROM access_account WHERE account_no = acc_no;
                INSERT INTO transactions (trans_type, trans_amt, trans_date, account_no, cust_id, emp_id, login_id) VALUES
                ('loan payment', amt, now()::timestamp, acc_no, temp_cid, temp_eid, temp_lid);
                INSERT INTO payment(pay_amount, pay_date, loan_id, loan_interest) VALUES (amt, now()::timestamp, lo_id, temp_interest);
                RAISE NOTICE 'Successfull Loan Payment! Amount left to pay : %', -1 * (temp_amt + amt);
                IF(temp_amt + amt >=0) THEN
                    UPDATE loan set loan_status = 0 where loan_id = lo_id;
                END IF;
               END;
            ELSE
                RAISE NOTICE 'Exceeding loan amount to be paid!';
            END IF;
        END;
        ELSE
            RAISE NOTICE 'This loan is no longer active!';
        END IF;
    ELSE
        RAISE NOTICE 'Given account number and loan id do not share a loan. Check input account number and loan id!';
    END IF;
END;
$deposit_amount$ LANGUAGE plpgsql;

-- procedure to update login and password
-- input : account no, prev uname, prev pass, new uname, new pass
CREATE OR REPLACE PROCEDURE update_creds(id INT, prev_uname VARCHAR(100), prev_pass VARCHAR(50), new_uname VARCHAR(100), new_pass VARCHAR(50))
AS $update_creds$
DECLARE
    temp_lid INT;
BEGIN
    IF EXISTS (SELECT login_id FROM access_account WHERE account_no = id) THEN
    BEGIN
        SELECT login_id INTO temp_lid FROM access_account WHERE account_no = id;
        UPDATE access SET username = new_uname, password = new_pass WHERE username = prev_uname AND password = prev_pass;
    END;
    ELSE
        RAISE NOTICE 'Account number not found! Check and try again';
    END IF;
END;
$update_creds$ LANGUAGE plpgsql
SECURITY DEFINER;

-- procedure to update customer info
-- input : customer id, add, phone no
CREATE OR REPLACE PROCEDURE update_customer(id INT, address TEXT = NULL, phone_no VARCHAR(10)[] = NULL)
AS $update_customer$
DECLARE
    temp_len INT;
BEGIN
    SELECT * INTO temp_len FROM array_length(phone_no, 1);
    IF (address IS NOT NULL) THEN
       UPDATE customer SET cust_address = address WHERE cust_id = id;
    END IF;
    IF temp_len = 1 OR temp_len = 2 THEN
       DELETE FROM customer_phoneno WHERE cust_id = id;
       INSERT INTO customer_phoneno(cust_id, cust_phoneno) SELECT id, UNNEST(phone_no);
    ELSE
        RAISE NOTICE 'Only 1 or 2 phone numbers are allowed!';
    END IF;
END;
$update_customer$ LANGUAGE plpgsql;

-- procedure to update employee info
-- input : emp id, add, salary
CREATE OR REPLACE PROCEDURE update_employee(id INT, address TEXT = NULL, salary INT = NULL)
AS $update_employee$
BEGIN
    IF (address IS NOT NULL) THEN
       UPDATE employee SET emp_address = address WHERE emp_id = id;
    END IF;
    IF (salary IS NOT NULL) THEN
       UPDATE employee SET emp_salary = salary WHERE emp_id = id;
    END IF;
END;
$update_employee$ LANGUAGE plpgsql;

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

-- role for customer
CREATE ROLE customer password 'customer';
-- role for employee
CREATE ROLE employee password 'employee';
-- role for branch_admin
CREATE ROLE branch_admin password 'branch_admin';

-- for employees
GRANT ALL ON customer, customer_account, customer_phoneno, account, transactions, payment, access_account, loan, customer_loan, branch_loan TO employee;
GRANT EXECUTE ON FUNCTION show_transaction_log, view_balance, employee_assists TO employee;
GRANT EXECUTE ON PROCEDURE update_customer, deposit_amount, withdraw_amount, transfer_amount, update_creds, pay_loan, create_loan_account TO employee;

-- for Branch admin
GRANT ALL ON branch, employee, customer, customer_account, customer_phoneno, account, transactions, payment, access_account, loan, customer_loan, branch_loan TO branch_admin;
GRANT EXECUTE ON FUNCTION show_transaction_log, view_balance, employee_assists TO branch_admin;
GRANT EXECUTE ON PROCEDURE update_customer, update_employee, deposit_amount, withdraw_amount, transfer_amount, update_creds, pay_loan, create_loan_account TO branch_admin;

-- function to create customer specific view.
-- input : username and password
CREATE OR REPLACE FUNCTION create_view_cust_details(uname VARCHAR(50), pword VARCHAR(50))
RETURNS void
AS $create_view_cust_details$
DECLARE
    log_id INT;
    c_name VARCHAR(100);
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
       SELECT login_id INTO log_id FROM access WHERE username = uname AND password = pword;
       EXECUTE 'CREATE OR REPLACE VIEW customer_view AS (SELECT cust_name, cust_address, cust_DOB, cust_phoneno FROM (customer NATURAL JOIN customer_phoneno) WHERE customer.login_id = '||log_id||')';
       SELECT cust_name INTO c_name FROM customer WHERE login_id = log_id;
       EXECUTE 'GRANT SELECT ON customer_view TO "'||c_name||'"';
       RAISE NOTICE 'Temporary view called "customer_view" for customer has been created!';
    ELSE
       RAISE NOTICE 'Customer does not exist in database. Check username and password!';
    END IF;
END;
$create_view_cust_details$ LANGUAGE plpgsql
SECURITY DEFINER;

-- function to create employee specific view.
-- input : username and password
CREATE OR REPLACE FUNCTION create_view_emp_details(uname VARCHAR(50), pword VARCHAR(50))
RETURNS void
AS $create_view_emp_details$
DECLARE
    log_id INT;
    e_name VARCHAR(100);
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
       SELECT login_id INTO log_id FROM access WHERE username = uname AND password = pword;
       EXECUTE 'CREATE OR REPLACE VIEW employee_view AS (SELECT emp_name, emp_address, emp_DOB, emp_salary FROM employee WHERE login_id = '||log_id||')';
       SELECT emp_name INTO e_name FROM employee WHERE login_id = log_id;
       EXECUTE 'GRANT SELECT ON employee_view TO "'||e_name||'"';
       RAISE NOTICE 'Temporary view called "employee_view" for employee has been created!';
    ELSE
       RAISE NOTICE 'Employee does not exist in database. Check username and password!';
    END IF;
END;
$create_view_emp_details$ LANGUAGE plpgsql
SECURITY DEFINER;

-- function to create loan payments view
-- input : username and password
CREATE OR REPLACE FUNCTION create_view_loan_payments(uname VARCHAR(50), pword VARCHAR(50))
RETURNS void
AS $$
DECLARE
    log_id INT;
    c_id INT;
    c_name VARCHAR(100);
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname AND password = pword) THEN
        SELECT login_id INTO log_id FROM access WHERE username = uname and password = pword;
        SELECT cust_id into c_id from customer where login_id = log_id;
        EXECUTE 'CREATE OR REPLACE VIEW loanpayments_view AS (SELECT * from (loan natural JOIN payment) where loan_id = (SELECT loan_id FROM customer_loan WHERE cust_id = '||c_id||'))';
        SELECT cust_name INTO c_name FROM customer WHERE login_id = log_id;
        EXECUTE 'GRANT SELECT ON loanpayments_view TO "'||c_name||'"';
        RAISE NOTICE 'Temporary view called "loanpayment_view" for customer has been created!';
    ELSE
       RAISE NOTICE 'Customer does not exist in database. Check username and password!';
    END IF;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER;

-- indexes 
CREATE INDEX ON access USING BTREE(username, password);
CREATE INDEX ON transactions USING BTREE(trans_date);
CREATE INDEX ON payment USING BTREE(loan_id, pay_date);
