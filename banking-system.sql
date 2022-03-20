-- creating the database for bank
CREATE DATABASE banking_system;

-- bank table
CREATE TABLE bank(
    bank_id SERIAL PRIMARY KEY,
    bank_name VARCHAR(100) NOT NULL,
    bank_address TEXT NOT NULL
);

-- branch table
CREATE TABLE branch(
    branch_id SERIAL PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL,
    branch_address TEXT NOT NULL,
    bank_id INT NOT NULL,
    CONSTRAINT bank_fk FOREIGN KEY (bank_id) REFERENCES bank (bank_id)
);

-- employee table
CREATE TABLE employee(
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    emp_address TEXT NOT NULL,
    emp_salary INT NOT NULL check(emp_salary >= 10000 AND emp_salary <= 1000000),
    branch_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id)
);

-- account table
CREATE TABLE account(
    account_no SERIAL PRIMARY KEY,
    account_type VARCHAR(25) NOT NULL check(account_type = “savings” || account_type = “checkings”),
    balance MONEY NOT NULL check (balance >= 500.0),
    branch_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id)
);

-- loan table
CREATE TABLE loan(
    loan_id SERIAL PRIMARY KEY,
    loan_type VARCHAR(25) NOT NULL check(loan_type = ”personal” || loan_type = ”business” || loan_type = ”home” || loan_type = ”student” || loan_type = ”automobile”),
    amount MONEY NOT NULL check(amount >= 1000.0),
    interest_rate FLOAT NOT NULL check(interest_rate >= 3.0 && interest_rate <= 12.5),
    branch_id INT NOT NULL,
    emp_id INT NOT NULL,
    CONSTRAINT branch_fk FOREIGN KEY (branch_id) REFERENCES branch (branch_id),
    CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id),
)

-- login table
CREATE TABLE access(
       login_id SERIAL PRIMARY KEY,
       username VARCHAR(100) NOT NULL,
       password VARCHAR(50) NOT NULL
)

-- customer table
CREATE TABLE customer(
    cust_id SERIAL PRIMARY KEY,
    cust_name VARCHAR(100) NOT NULL,
    cust_address TEXT NOT NULL,
    cust_age INT NOT NULL check(cust_age >= 18),
    emp_id INT NOT NULL,
    login_id INT NOT NULL,
    CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id),
    CONSTRAINT access_fk FOREIGN KEY (login_id) REFERENCES access (login_id)
)

-- customer-phone table
CREATE TABLE customer_phoneno(
    cust_id INT,
    cust_phoneno INT check (cust_phoneno >= 1000000000 AND cust_phoneno <= 9999999999),
    PRIMARY KEY (cust_id, cust_phoneno),
    CONSTRAINT cont_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id)
)

-- customer-account table
CREATE TABLE customer_account(
    cust_id INT,
    account_no INT,
    PRIMARY KEY (cust_id, account_no),
    CONSTRAINT cacu_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id),
    CONSTRAINT caac_fc FOREIGN KEY (account_no) REFERENCES account (account_no)
)

-- customer-loan table
CREATE TABLE customer_loan(
    cust_id INT,
    loan_id INT,
    PRIMARY KEY (cust_id, loan_id),
    CONSTRAINT cust_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id),
    CONSTRAINT loan_fk FOREIGN KEY (loan_id) REFERENCES loan (loan_id)
)

-- TODO : payment table
CREATE TABLE payment(
       pay_id SERIAL PRIMARY KEY,
       pay_amount MONEY NOT NULL check(pay_amount >= 100.0)
       -- amount left to pay
       pay_date DATETIME NOT NULL,
       -- function to check if paydate has not elapsed
       loan_id INT NOT NULL,
       CONSTRAINT loan_fk FOREIGN KEY (loan_id) REFERENCES loan (loan_id)
)

-- transaction table
CREATE TABLE transactions(
       trans_id SERIAL PRIMARY KEY,
       trans_type VARCHAR(50) NOT NULL check(trans_type = "deposit" || trans_type = "withdraw" || trans_type = "transfer")
       trans_amt MONEY NOT NULL check(trans_amt >= 100.0)
       trans_date DATETIME NOT NULL,
       account_no INT NOT NULL,
       r_account_no INT DEFAULT NULL, -- for reciever account when the tracnsaction is of the type "transfer"
       cust_id INT NOT NULL,
       emp_id INT NOT NULL,
       login_id INT NOT NULL,
       CONSTRAINT acc_fk FOREIGN KEY (account_no) REFERENCES account (account_no),
       CONSTRAINT cust_fk FOREIGN KEY (cust_id) REFERENCES customer (cust_id),
       CONSTRAINT emp_fk FOREIGN KEY (emp_id) REFERENCES employee (emp_id),
       CONSTRAINT login_fk FOREIGN KEY (login_id) REFERENCES access (login_id),
)

-- login-account table
CREATE TABLE access_login(
       login_id INT NOT NULL,
       account_no INT NOT NULL,
       (login_id, account_no) PRIMARY KEY,
       CONSTRAINT login_fk FOREIGN KEY (login_id) REFERENCES access (login_id),
       CONSTRAINT acc_fk FOREIGN KEY (account_no) REFERENCES account (account_no)
)
