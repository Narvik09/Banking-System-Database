-- creating the database for bank
-- CREATE DATABASE banking_system;

-- command to run the entire file : psql -U <user> -d <database> -f <filepath>

-- updated bank table
CREATE TABLE bank(
    bank_id SERIAL unique,
    bank_name VARCHAR(100),
    bank_address TEXT,
    CONSTRAINT bank_pkey PRIMARY KEY (bank_name, bank_address)
);

-- updated branch table
CREATE TABLE branch(
    branch_id SERIAL unique,
    branch_name VARCHAR(100),
    branch_address TEXT,
    bank_id INT NOT NULL,
    CONSTRAINT branch_pkey PRIMARY KEY (branch_name, branch_address),
    CONSTRAINT bank_fk FOREIGN KEY (bank_id) REFERENCES bank (bank_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- employee table
CREATE TABLE employee(
    emp_id SERIAL unique,
    emp_name VARCHAR(100),
    emp_address TEXT,
    emp_salary INT NOT NULL check(emp_salary >= 10000 AND emp_salary <= 1000000),
    branch_id INT NOT NULL,
    CONSTRAINT employee_pkey PRIMARY KEY (emp_name, emp_address),
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- account table
CREATE TABLE account(
    account_no SERIAL PRIMARY KEY,
    account_type VARCHAR(25) NOT NULL check(account_type = 'savings' OR account_type = 'checkings'),
    balance NUMERIC(12, 2) NOT NULL check (balance >= 500.0),
    branch_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- loan table
CREATE TABLE loan(
    loan_id SERIAL PRIMARY KEY,
    loan_type VARCHAR(25) NOT NULL check(loan_type = 'personal' OR loan_type = 'business' OR loan_type = 'home' OR loan_type = 'student' OR loan_type = 'automobile'),
    amount NUMERIC(12, 2) NOT NULL check(amount >= 1000.0),
    interest_rate NUMERIC(4, 2) NOT NULL check(interest_rate >= 3.0 AND interest_rate <= 12.5),
    branch_id INT NOT NULL,
    emp_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- updated login table --> corrected username constraint
CREATE TABLE access(
    login_id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(50) NOT NULL
);

-- updated customer table --> made cust_id unique; (cust_name, cust_address) as PK
CREATE TABLE customer(
    cust_id SERIAL unique,
    cust_name VARCHAR(100),
    cust_address TEXT,
    cust_DOB DATE NOT NULL check(date_part('year', AGE(cust_DOB)) >= 18), -- change this to DOB and take difference
    emp_id INT NOT NULL,
    login_id INT NOT NULL,
    CONSTRAINT customer_pkey PRIMARY KEY (cust_name, cust_address),
    CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT access_fk FOREIGN KEY (login_id) REFERENCES access (login_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- updated customer-phone table --> fixed cust_phoneno constraints
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

-- payment table
CREATE TABLE payment(
       pay_id SERIAL PRIMARY KEY,
       pay_amount NUMERIC(12, 2) NOT NULL check(pay_amount >= 100.0),
       pay_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
       loan_id INT NOT NULL,
       CONSTRAINT loan_fk FOREIGN KEY (loan_id) REFERENCES loan (loan_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- transaction table
CREATE TABLE transactions(
       trans_id SERIAL PRIMARY KEY,
       trans_type VARCHAR(50) NOT NULL check(trans_type = 'deposit' OR trans_type = 'withdraw' OR trans_type = 'transfer'),
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

-- function that takes in customer's login and password and returns account no if exists
CREATE OR REPLACE FUNCTION customer_login(uname VARCHAR(100), pass VARCHAR(50))
RETURNS TABLE (
    account_number INT
)
AS $customer_login$
BEGIN
    RETURN QUERY
    SELECT account_no FROM (account NATURAL JOIN (access_account NATURAL JOIN access)) WHERE username = uname AND password = pass;
END;
$customer_login$ LANGUAGE plpgsql;

-- procedure to create an account
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
    SELECT * INTO temp_uname FROM CAST(md5(random()::TEXT) AS VARCHAR(100));
    SELECT * INTO temp_pass FROM CAST(md5(random()::TEXT) AS VARCHAR(50));
    SELECT * INTO temp_len FROM array_length(c_phone, 1);
    IF (temp_len = 1 OR temp_len = 2) THEN
    BEGIN
        INSERT INTO access (username, password) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
        INSERT INTO customer (cust_name, cust_address, cust_DOB, emp_id, login_id) VALUES (c_name, c_add, c_DOB, e_id, temp_lid) RETURNING cust_id INTO temp_cid;
        INSERT INTO customer_phoneno (cust_id, cust_phoneno) SELECT temp_cid, UNNEST(c_phone);
        INSERT INTO account (account_type, balance, branch_id) VALUES (a_type, 500, b_id) RETURNING account_no INTO temp_ano;
        INSERT INTO access_account VALUES (temp_lid, temp_ano);
        INSERT INTO customer_account VALUES (temp_cid, temp_ano);
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

-- function to view balance
CREATE OR REPLACE FUNCTION view_balance(id INT)
RETURNS void
AS $view_balance$
DECLARE
    temp_balance NUMERIC(12, 2);
BEGIN
    IF EXISTS (SELECT balance FROM account WHERE account_no = id) THEN
       SELECT balance INTO temp_balance FROM account WHERE account_no = id;
       RAISE NOTICE 'Balance amount in the account : %', temp_balance;
    ELSE
       RAISE NOTICE 'Account does not exist. Check input account number!';
    END IF;
END;
$view_balance$ LANGUAGE plpgsql;

-- procedure to withdraw money from account
CREATE OR REPLACE PROCEDURE withdraw_amount(id INT, amt NUMERIC(12, 2))
AS $withdraw_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
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
$withdraw_amount$ LANGUAGE plpgsql;

-- procedure to deposit money
-- use login ID and Amount
CREATE OR REPLACE PROCEDURE deposit_amount(id INT, amt NUMERIC(12, 2))
AS $deposit_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
BEGIN
    IF EXISTS (SELECT balance FROM account WHERE account_no = id) THEN
       SELECT balance INTO temp_amt FROM account WHERE account_no = id;
       IF (amt <= 10000000) THEN
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
        RAISE NOTICE 'Cannot deposit this amount! Enter less than 10000000';
       END IF;
    ELSE
        RAISE NOTICE 'Account doesnot exist. Check input account number!';
    END IF;
END;
$deposit_amount$ LANGUAGE plpgsql;

-- procedure to update login and password
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
$update_creds$ LANGUAGE plpgsql;

-- function / procedure to show transaction log
CREATE OR REPLACE FUNCTION show_transaction_log(id INT)
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
    IF EXISTS (SELECT account_no FROM account WHERE account_no = id) THEN
       RETURN QUERY
       SELECT trans_id, trans_type, trans_amt, trans_date, r_account_no, emp_id FROM transactions
       WHERE account_no = id;
    ELSE
       RAISE NOTICE 'Account number not found! Check and try again';
    END IF;
END;
$show_transaction_log$ LANGUAGE plpgsql;

-- procedure to transfer amount to another account
CREATE OR REPLACE PROCEDURE transfer_amount(sender_id INT, receiver_id INT, amt NUMERIC(12, 2))
AS $transfer_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
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
$transfer_amount$ LANGUAGE plpgsql;

-- some things for loans :(

-- procedure to add an employee

-- function to check who all a particular employee assists
-- emp_id
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

-- procedure to update customer info
-- cust_id
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


-- role for customer

create role customer password 'customer';

create user Sharon password 'sharon';
GRANT customer to Sharon;

-- role for employee

create role employee password 'employee';

create user Tanu password 'tanu';
create user Deepesh password 'deepesh';

GRANT employee to Tanu;
GRANT employee to Deepesh;

-- role for branch_admin

create role branch_admin password 'branch_admin';

create user DBA password 'dba';

GRANT branch_admin to DBA;

-- function to create view for a specific customer

CREATE OR REPLACE FUNCTION create_view_cust_details(uname VARCHAR(50), pword VARCHAR(50))
RETURNS void
AS $create_view_cust_details$
DECLARE
    log_id INT;
BEGIN
    IF EXISTS (SELECT login_id FROM access WHERE username = uname and password = pword) THEN
       SELECT login_id INTO log_id FROM access WHERE username = uname and password = pword;
       CREATE OR REPLACE VIEW view_for_custid as (select cust_name, cust_address, cust_phoneno from (customer natural JOIN cust_phoneno) where login_id = log_id );
       GRANT select on view_cust_details to customer;
       RAISE NOTICE 'Temporary view called "view_cust_details" for account no : % has been created!', id;
    ELSE
       RAISE NOTICE 'Account does not exist. Check input account number!';
    END IF;
END;
$create_view_cust_details$ LANGUAGE plpgsql;

-- for employees

GRANT all on customer, customer_account, customer_phoneno, account, transactions, access_account, to employee;


GRANT execute ON FUNCTION show_transaction_log, view_balance,
employee_assists TO employee;

GRANT execute ON PROCEDURE update_customer, deposit_amount, withdraw_amount,
transfer_amount, update_creds TO employee;

-- for Branch admin

GRANT all on branch, employee, customer, account, access_account, customer_account to branch_admin;

GRANT execute ON FUNCTION show_transaction_log, view_balance, employee_assists TO branch_admin;

GRANT execute ON PROCEDURE update_customer, update_employee, deposit_amount, withdraw_amount,
transfer_amount, update_creds TO branch_admin;

-- permissions for sequences
GRANT all on transactions_trans_id_seq to employee, branch_admin;
GRANT all on access_login_id_seq, account_account_no_seq, customer_cust_id_seq to employee;
GRANT all on access_login_id_seq, account_account_no_seq, customer_cust_id_seq, employee_emp_id_seq to employee;


/*
ROLES

Customer
- cust_id
- cust_name
- cust_add
- cust_phoneno
- account_no

Do we create a func which creates a view for the
given id and grants select permission?


Employee
- customer
- customer_account
- customer_phoneno
- account
- transactions

GRANT execute ON FUNCTION view_balance TO employee;
GRANT execute ON PROCEDURE update_customer TO employee;

- show_transaction_log /
- view_balance /
- employee_assists /
- update_customer /
- deposit_amount /
- withdraw_amount /
- transfer_amount /
- update_creds /

Branch admin
- branch
- employee
- customer
- account

- show_transaction_log
- view_balance
- employee_assists
- update_customer
- update_employee
- deposit_amount /
- withdraw_amount /
- transfer_amount /
- update_creds /

*/
