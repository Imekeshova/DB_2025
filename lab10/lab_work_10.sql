-- 3.1
-- Reset tables and recreate the initial dataset

DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

-- Insert initial rows
INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);


-- 3.2
-- Basic transaction example with COMMIT
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
COMMIT;

SELECT * FROM accounts;

-- a) Resulting balances:
-- Alice: 1000 - 100 = 900
-- Bob: 500 + 100 = 600

-- b) Both UPDATE statements must be executed inside one transaction
--    because transferring money is one atomic action. Splitting it
--    would risk leaving the system inconsistent if something fails.

-- c) Without a transaction, a crash between the two operations
--    would cause Alice to lose 100 while Bob gains nothing,
--    creating an incorrect account state.



-- 3.3
-- ROLLBACK example
BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';  -- before rollback
ROLLBACK;

SELECT * FROM accounts WHERE name = 'Alice';  -- after rollback

-- a) After the UPDATE but before ROLLBACK, Alice temporarily shows 500.
-- b) After ROLLBACK, her balance is restored to the original 1000.
-- c) ROLLBACK is useful when:
--    - the wrong row was changed
--    - the amount was incorrect
--    - a check/validation failed
--    - an unexpected error occurred
--    It undoes all modifications made in the transaction.



-- 3.4
-- Working with SAVEPOINTS
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
SAVEPOINT sp_transfer;

UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';

-- Incorrect receiver → revert only this part
ROLLBACK TO sp_transfer;

-- Correct receiver
UPDATE accounts SET balance = balance + 100 WHERE name = 'Wally';

COMMIT;

SELECT * FROM accounts;

-- a) Final balances after COMMIT:
--    Alice: 900
--    Bob: unchanged → 500
--    Wally: 750 + 100 = 850

-- b) Bob briefly received the funds, but that update was undone
--    when we rolled back to the savepoint.

-- c) SAVEPOINT allows rolling back only part of a transaction,
--    which is more convenient than restarting the whole thing.



-- 3.5  TASK 4 — Isolation Levels (requires 2 terminals)
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
-- Repeat after Terminal 2 commits
COMMIT;

-- TERMINAL 2:
BEGIN;
DELETE FROM products WHERE shop='Joe''s Shop';
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Fanta', 3.50);
COMMIT;

-- Scenario A — READ COMMITTED:
-- a) Terminal 1 sees:
--    Before Terminal 2 COMMIT: Coke, Pepsi
--    After Terminal 2 COMMIT: only Fanta

-- Scenario B — SERIALIZABLE:
-- b) Terminal 1 continues to see the original result (Coke, Pepsi)
--    even after Terminal 2 commits.

-- c) Explanation:
--    READ COMMITTED: each SELECT reads the latest committed version.
--    SERIALIZABLE: the transaction behaves as if it runs alone.



-- 3.6
-- Phantom Read Demonstration
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
-- Repeat after Terminal 2 inserts a new product
COMMIT;

-- TERMINAL 2:
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;

-- a) Terminal 1 does NOT see the new row from Terminal 2.
--    REPEATABLE READ prevents the result set from changing.

-- b) A phantom read occurs when a repeated query returns
--    additional rows that were not present during the first read.

-- c) Only SERIALIZABLE fully prevents phantom reads.



-- 3.7
-- Dirty Read Demonstration

-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
-- Repeat while Terminal 2 modifies data (without commit)
-- And again after Terminal 2 rolls back
COMMIT;

-- TERMINAL 2:
BEGIN;
UPDATE products SET price = 99.99 WHERE product='Fanta';
ROLLBACK;

-- a) Yes, Terminal 1 may see the temporary value 99.99.
--    This is a dirty read: data becomes visible before commit.

-- b) A dirty read is reading uncommitted changes from another transaction.

-- c) READ UNCOMMITTED is unsafe because it exposes values that
--    may be rolled back and never actually exist in the database.



-- 4. INDEPENDENT EXERCISE 1
-- Conditional transfer: Bob → Wally ($200) if Bob has enough funds

DO $$
DECLARE
    bob_balance DECIMAL;
BEGIN
    SELECT balance INTO bob_balance FROM accounts WHERE name='Bob';

    IF bob_balance >= 200 THEN
        UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
        UPDATE accounts SET balance = balance + 200 WHERE name='Wally';
        RAISE NOTICE 'Transfer completed successfully.';
    ELSE
        RAISE NOTICE 'Transfer aborted: insufficient balance.';
    END IF;
END $$;

SELECT * FROM accounts;



-- 4. INDEPENDENT EXERCISE 2
-- Demonstration of using multiple savepoints

BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Demo Shop', 'Tea', 1.00);

SAVEPOINT sp_first;

UPDATE products SET price = 2.50 WHERE product='Tea';

SAVEPOINT sp_second;

DELETE FROM products WHERE product='Tea';

-- Roll back to the first savepoint → undo the delete + price update
ROLLBACK TO sp_first;

COMMIT;

SELECT * FROM products;



-- 4. INDEPENDENT EXERCISE 3
-- Two users withdrawing at the same time (conceptual example)

-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name='Alice';
COMMIT;

-- TERMINAL 2:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name='Alice';
COMMIT;

-- Under SERIALIZABLE, one of the transactions would be rolled back.



-- 4. INDEPENDENT EXERCISE 4
-- MAX < MIN anomaly demonstration

-- Without transactions (incorrect):
SELECT MAX(price) FROM products WHERE shop='Joe''s Shop';
-- Meanwhile, another session modifies the table → inconsistent results possible

-- Correct:
BEGIN;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
COMMIT;



-- 5. Self-Assessment Answers
/*
1. ACID:
   - Atomic: operations run as an all-or-nothing unit.
   - Consistent: database rules remain satisfied.
   - Isolated: parallel transactions do not interfere.
   - Durable: committed data persists after failures.

2. COMMIT makes all changes permanent.
   ROLLBACK discards all changes made in the transaction.

3. SAVEPOINT allows partial rollback instead of cancelling the entire transaction.

4. Isolation Levels:
   - Read Uncommitted: allows dirty reads.
   - Read Committed: no dirty reads.
   - Repeatable Read: prevents non-repeatable reads.
   - Serializable: prevents all anomalies.

5. Dirty read = viewing uncommitted data; allowed in Read Uncommitted.

6. Non-repeatable read: data changes between two reads of the same row.

7. Phantom read: new rows appear in repeated queries; prevented by Serializable.

8. READ COMMITTED is faster and more scalable for busy systems.

9. Transactions ensure correct results when multiple users access data concurrently.

10. Uncommitted modifications vanish if the system crashes.
*/


/*
Conclusion:

During this lab, I explored how SQL transactions ensure data integrity
when multiple operations occur at the same time. I learned the role of the
ACID principles—atomicity, consistency, isolation, and durability—
and how each of them contributes to keeping the database reliable.

I also practiced using the core transaction statements:
BEGIN, COMMIT, ROLLBACK, and SAVEPOINT,
and observed how different isolation levels affect concurrent behavior.
*/
