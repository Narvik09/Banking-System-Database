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
