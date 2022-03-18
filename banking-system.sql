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
    CONSTRAINT bran_fk FOREIGN KEY (bank_id)
    REFERENCES bank (bank_id)
);

-- employee table
CREATE TABLE employee(
    emp_id SERIAL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    emp_address TEXT NOT NULL,
    emp_salary INT NOT NULL check(emp_salary >= 10000 AND emp_salary <= 1000000),
    branch_id INT NOT NULL,
    CONSTRAINT emp_fk FOREIGN KEY (branch_id)
    REFERENCES branch (branch_id)
);

-- account table
CREATE TABLE account(
    account_no SERIAL PRIMARY KEY,
    account_type VARCHAR(25) NOT NULL check(account_type = “savings” || account_type = “checkings”),
    balance FLOAT NOT NULL check (balance >= 500.0),
    branch_id INT NOT NULL,
    CONSTRAINT acc_fk FOREIGN KEY (branch_id)
    REFERENCES branch (branch_id)
);

-- loan table
CREATE TABLE loan(
    loan_id SERIAL PRIMARY KEY,
    loan_type VARCHAR(25) NOT NULL check(loan_type = ”personal” || loan_type = ”business” || loan_type = ”home” || loan_type = ”student” || loan_type = ”automobile”),
    amount FLOAT NOT NULL check(amount >= 1000.0),
    interest_rate FLOAT NOT NULL check(interest_rate >= 3.0 && interest_rate <= 12.5),
    branch_id INT NOT NULL,
    CONSTRAINT loan_fk FOREIGN KEY (branch_id)
    REFERENCES branch (branch_id)
)

-- customer table
CREATE TABLE customer(
    cust_id SERIAL PRIMARY KEY,
    cust_name VARCHAR(100) NOT NULL,
    cust_address TEXT NOT NULL,
    cust_age INT NOT NULL check(cust_age >= 18),
    emp_id INT NOT NULL,
    CONSTRAINT cust_fk FOREIGN KEY (emp_id)
    REFERENCES employee (emp_id)
)

-- customer-phone table
CREATE TABLE customer_phoneno(
    cust_id INT,
    cust_phoneno INT check (cust_phoneno >= 1000000000 AND cust_phoneno <= 9999999999),
    PRIMARY KEY (cust_id, cust_phoneno),
    CONSTRAINT cont_fk FOREIGN KEY (cust_id)
    REFERENCES customer (cust_id)
)

-- customer-account table
CREATE TABLE customer_account(
    cust_id INT,
    account_no INT,
    PRIMARY KEY (cust_id, account_no),
    CONSTRAINT cacu_fk FOREIGN KEY (cust_id)
    REFERENCES customer (cust_id),
    CONSTRAINT caac_fc FOREIGN KEY (account_no)
    REFERENCES account (account_no)
)

-- customer-loan table
CREATE TABLE customer_loan(
    cust_id INT,
    loan_id INT,
    PRIMARY KEY (cust_id, loan_id),
    CONSTRAINT clcu_fk FOREIGN KEY (cust_id)
    REFERENCES customer (cust_id),
    CONSTRAINT cllo_fk FOREIGN KEY (loan_id)
    REFERENCES loan (loan_id)
)

-- TODO : payment table
