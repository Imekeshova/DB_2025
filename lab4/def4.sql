
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS branches CASCADE;

CREATE TABLE branches (
    branch_code VARCHAR(10) PRIMARY KEY,
    branch_name VARCHAR(100),
    city VARCHAR(100),
    manager_name VARCHAR(100),
    employee_count INTEGER
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    account_holder VARCHAR(100),
    account_type VARCHAR(20),
    balance NUMERIC(14,2),
    opening_date DATE,
    branch_code VARCHAR(10) REFERENCES branches(branch_code),
    status VARCHAR(20)
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    account_id INTEGER REFERENCES accounts(account_id),
    transaction_date DATE,
    amount NUMERIC(14,2),
    transaction_type VARCHAR(20),
    description VARCHAR(255)
);
INSERT INTO branches (branch_code, branch_name, city, manager_name, employee_count) VALUES
('BR01', 'Central Branch', 'Almaty', 'Aruzhan K.', 20);


INSERT INTO accounts (account_holder, account_type, balance, opening_date, branch_code, status) VALUES
('John Smith', 'Savings', 1500.50, '2022-01-10', 'BR001', 'Active'),
('Sarah Johnson', 'Checking', 2300.00, '2021-11-20', 'BRc1', 'active');

INSERT INTO transactions (account_id, transaction_date, amount, transaction_type, description) VALUES
(1, '2024-01-15', 200.00, 'Deposit', 'Monthly deposit'),
(1, '2024-02-15', -50.00, 'Withdrawal', 'ATM withdrawal');


-- Task A1
SELECT
    UPPER(account_holder) AS account_holder_upper,
    SUBSTRING(branch_code FROM 1 FOR 5) AS branch_prefix,
    account_type || ' ' || status AS account_status
FROM accounts;

-- Task A2
SELECT
    account_id,
    account_holder,
    CASE
        WHEN balance > 100000 THEN 'High Value'
        WHEN balance BETWEEN 10000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM accounts;




-- Task A3
SELECT *
FROM accounts
WHERE LOWER(account_holder) LIKE '%a%';


-- Task B1
SELECT *
FROM transactions
WHERE amount BETWEEN 500 AND 5000
  AND transaction_type = 'Withdrawal';



-- Task B2
SELECT
    account_id,
    account_holder,
    balance,
    balance * 1.025 AS balance_with_interest
FROM accounts
WHERE account_type = 'Savings';

-- Task B3
SELECT *
FROM branches
WHERE employee_count > 10
   OR city = 'New York';





-- Task B4
SELECT *
FROM transactions
WHERE description IS NULL
   OR description = '';

-- Task C1
SELECT
    account_id,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY account_id;




-- Task C2
SELECT
    branch_code,
    COUNT(*) AS total_accounts
FROM accounts
GROUP BY branch_code
HAVING COUNT(*) > 5;

-- Task C3
SELECT
    account_type,
    AVG(balance) AS avg_balance
FROM accounts
GROUP BY account_type;

-- Task C4
SELECT
    transaction_date,
    SUM(amount) AS total_deposits
FROM transactions
WHERE transaction_type = 'Deposit'
GROUP BY transaction_date;

-- Task D1
SELECT *
FROM accounts a
WHERE EXISTS (
    SELECT 1
    FROM transactions t
    WHERE t.account_id = a.account_id
);

-- Task D2
SELECT *
FROM accounts
WHERE balance > ANY (
    SELECT balance
    FROM accounts
    WHERE branch_code = 'BR001'
);
