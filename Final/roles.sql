-- role for customer
CREATE ROLE customer password 'customer';
-- role for employee
CREATE ROLE employee password 'employee';
-- role for branch_admin
CREATE ROLE branch_admin password 'branch_admin';

-- for employees
GRANT ALL ON customer, customer_account, customer_phoneno, account, transactions, payment, access_account, loan, customer_loan, branch_loan TO employee;
GRANT EXECUTE ON FUNCTION show_transaction_log, show_payment_log, view_balance, employee_assists TO employee;
GRANT EXECUTE ON PROCEDURE update_customer, deposit_amount, withdraw_amount, transfer_amount, update_creds, pay_loan, create_loan_account, create_account TO employee;

-- for Branch admin
GRANT ALL ON branch, employee, customer, customer_account, customer_phoneno, account, transactions, payment, access_account, loan, customer_loan, branch_loan TO branch_admin;
GRANT EXECUTE ON FUNCTION show_transaction_log, show_payment_log, view_balance, employee_assists TO branch_admin;
GRANT EXECUTE ON PROCEDURE update_customer, update_employee, create_account, deposit_amount, withdraw_amount, transfer_amount, update_creds, pay_loan, create_loan_account, add_employee TO branch_admin;

