-- creating the database for bank
CREATE DATABASE banking_system;

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
    cust_age INT NOT NULL check(cust_age >= 18),
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
   c_age INT,
   c_phone BIGINT,
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
BEGIN
    SELECT * INTO temp_uname FROM CAST(md5(random()::TEXT) AS VARCHAR(100));
    SELECT * INTO temp_pass FROM CAST(md5(random()::TEXT) AS VARCHAR(50));
    INSERT INTO access (username, password) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
    INSERT INTO customer (cust_name, cust_address, cust_age, emp_id, login_id) VALUES (c_name, c_add, c_age, e_id, temp_lid) RETURNING cust_id INTO temp_cid;
    INSERT INTO customer_phoneno VALUES (temp_cid, c_phone);
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
$create_account$ LANGUAGE plpgsql;

-- function to view balance
CREATE OR REPLACE FUNCTION view_balance(id INT)
AS $view_balance$
BEGIN
    SELECT balance FROM account WHERE account_no = id;
END;
$view_balance$ LANGUAGE plpgsql

-- procedure to withdraw money from account
CREATE OR REPLACE PROCEDURE withdraw_amount(id INT, amt NUMERIC(12, 2))
AS $withdraw_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
BEGIN
    SELECT balance INTO temp_amt FROM account WHERE account_no = id;
    IF (temp_amt >= (amt + 500)) THEN
       UPDATE account SET balance = balance - amt WHERE account_no = id;
       INSERT INTO transaction (trans_type, trans_amt, trans_date, account_no, cust_id, emp_id, login_id) VALUES

       ('withdraw', amt, now()::timestamp, id, )
    ELSE
       RAISE NOTICE 'Insufficient balance in account! Balance amount : %', temp_amt;
    END IF;
END;
$withdraw_amount$ LANGUAGE plpgsql;

-- procedure to deposit money
CREATE OR REPLACE PROCEDURE deposit_amount(id INT, amt NUMERIC(12, 2))
AS $deposit_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
BEGIN
    SELECT balance INTO temp_amt FROM account WHERE account_no = id;
    IF () THEN
       -- some check for depositing
       -- add entry into transaction table
    ELSE
        RAISE NOTICE 'Some error occured. Try again later!'
    END IF;
END;
$deposit_amount$ LANGUAGE plpgsql;

-- procedure to update login and password
CREATE OR REPLACE PROCEDURE update_creds(id INT, prev_uname VARCHAR(100), prev_pass VARCHAR(50), new_uname VARCHAR(100), new_pass VARCHAR(50))
AS $update_creds$
BEGIN

END;
$update_creds$ LANGUAGE plpgsql;

-- function / procedure to show transaction log
CREATE OR REPLACE PROCEDURE show_transaction_log(id INT)
AS $show_transaction_log$
BEGIN

END;
$show_transaction_log$ LANGUAGE plpgsql;

-- procedure to transfer amount to another account
CREATE OR REPLACE PROCEDURE transfer_amount(sender_id INT, reciever_id INT, amt  NUMERIC(12, 2))
AS $transfer_amount$
BEGIN

END;
$transfer_amount$ LANGUAGE plpgsql;

-- some things for loans :(
