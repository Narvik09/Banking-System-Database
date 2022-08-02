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
