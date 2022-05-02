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
