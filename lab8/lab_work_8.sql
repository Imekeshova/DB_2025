
---LAB WORK 8---
----------------------------
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;


--Create tables
CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(100),
 dept_id INT,
 salary DECIMAL(10,2),
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
 proj_id INT PRIMARY KEY,
 proj_name VARCHAR(100),
 budget DECIMAL(12,2),
 dept_id INT,
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
-- Insert sample data
INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');
INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

---2.1---
CREATE INDEX emp_salary_idx ON employees(salary);
-- 2.1 List all indexes on employees table
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
--How many indexes exist on the employees table? (Hint: PRIMARY KEY creates an automatic index)
---Typically, the employees table has at least two indexes: one automatically created for the PRIMARY KEY (e.g., employees_pkey) and the emp_salary_idx you created manually. The exact number depends on the output of the pg_indexes query.

---2.2---
CREATE INDEX emp_dept_idx ON employees(dept_id);
--2.2 This query should use the index
SELECT * FROM employees WHERE dept_id = 101;
--Why is it beneficial to index foreign key columns?
--Indexing foreign key columns speeds up lookups and JOIN operations, making queries on related tables much faster. It also helps PostgreSQL efficiently check referential integrity during updates and delete

---2.3---
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--Which indexes were created automatically?
--Indexes created automatically include those generated for PRIMARY KEY and UNIQUE constraints, such as employees_pkey. All other indexes were created manually through SQL commands.

---3.1---
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
--3.1 This query can use the multicolumn index
SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
--Would this index be useful for a query filtering only by salary?
--No, because salary is the second column in the index. PostgreSQL can only efficiently use a multicolumn index starting from the leftmost column (dept_id).

---3.2---
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
-- 3.2 Query 1
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
-- 3.2 Query 2
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
--Does the order of columns in a multicolumn index matter?
--Yes, the order matters because PostgreSQL reads the index from left to right. An index is most effective when the first column in the index is used in the query’s filter conditions.


---4.1---
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- -- This should fail
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--What error message did you receive?
--The insert fails with: ERROR: duplicate key value violates unique constraint "emp_email_unique_idx". PostgreSQL prevents inserting a row with an email that already exists in the unique index.

---4.2---
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;
--4,2
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
--Did PostgreSQL automatically create an index? What type?
--Yes, PostgreSQL automatically created a unique B-tree index to enforce the UNIQUE constraint on the phone column. The index name is usually something like employees_phone_key.

---5.1---
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);
--4.2
SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
--How does this index help with ORDER BY queries?
--The index stores salary values in descending order, allowing PostgreSQL to return rows already sorted. This avoids an extra sorting step and speeds up ORDER BY queries on large tables.

---5.2---
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);
--5.2
SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;
--How does this index help?
--It allows PostgreSQL to read rows in the desired NULL-first order directly from the index. This reduces or eliminates the need for an explicit sort during query execution.

---6.1---
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));
--6.1 This query can use the expression index
SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
--Without this index, how would PostgreSQL search for names case-insensitively?
--Without the expression index, PostgreSQL would usually perform a sequential scan and evaluate LOWER(emp_name) for every row, which is slow on large tables. Creating the index lets the planner perform an index scan using the precomputed lowercase values.

---6.2---
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;
--6.2
CREATE INDEX emp_hire_year_idx ON employees((EXTRACT(YEAR FROM hire_date)));
-- Test
SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;
--How does this help?
--Indexing the extracted year lets queries that filter by year use the index instead of scanning all rows, speeding up year-based searches. This is useful when many queries group or filter by the hire year.

---7.1---
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

-- 7.1  Verify
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

--Rename verified by listing indexes.
--After renaming, employees_salary_index should appear in the pg_indexes output for the employees table.

---7.2---
DROP INDEX emp_salary_dept_idx;


--Why might you want to drop an index?
--You drop indexes that are rarely used because they consume disk space and slow down INSERT/UPDATE/DELETE operations. Removing unused or redundant indexes reduces maintenance overhead and can improve write performance.

---7.3---
REINDEX INDEX employees_salary_index;


--When is REINDEX useful?
--Use REINDEX after massive bulk inserts or deletes, when an index is bloated, or after major data changes/corruption. It rebuilds the index structure to reclaim space and restore optimal performance.

---8.1---
-- 8.1 Index for the WHERE clause (partial index)
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

-- Index for the JOIN (assumed created earlier)
-- CREATE INDEX emp_dept_idx ON employees(dept_id);

-- Index for ORDER BY (assumed created earlier)
-- CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

--  8.1 Test the query (EXPLAIN to check plan)
EXPLAIN ANALYZE
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

---8.2---
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;
-- 8.2 Test the partial index
EXPLAIN ANALYZE
SELECT proj_name, budget
FROM projects
WHERE budget > 80000;
--What's the advantage of a partial index compared to a regular index?
--A partial index only stores entries for rows matching the WHERE condition, so it is smaller and faster to scan for that subset. This reduces storage and maintenance overhead while giving fast lookups for the targeted queries.

---8.3---
EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 52000;
--Does the output show an "Index Scan" or a "Seq Scan"? What does this tell you?
--If you see Index Scan (or Bitmap Index Scan), the index is being used and the query benefits from the index. If you see Seq Scan, PostgreSQL chose a full table scan, which means the planner estimated scanning the table was cheaper than using the index (possibly due to low selectivity or stale statistics).


---9.1---
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
-- 9.1 Test
EXPLAIN ANALYZE
SELECT * FROM departments WHERE dept_name = 'IT';
--When should you use a HASH index instead of a B-tree index?
--Use a HASH index only for simple equality lookups when you need slightly faster equality performance and you know your workload fits it. In most cases B-tree is preferable because it supports range queries and is more generally useful.


---9.2---
-- B-tree index
CREATE INDEX proj_name_btree_idx ON projects(proj_name);

-- Hash index
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

-- 9.2 Tests
EXPLAIN ANALYZE SELECT * FROM projects WHERE proj_name = 'Website Redesign';
EXPLAIN ANALYZE SELECT * FROM projects WHERE proj_name > 'Database';


---10.1---
SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
--Which index is the largest? Why?
--The largest index is usually the one covering the most rows or the one with many included columns (or a bloated index). Large indexes appear when the indexed column is highly selective for many rows or when the index has not been vacuumed/reindexed after heavy modifications.


---10.2---
-- Drop the duplicate hash index if not needed
DROP INDEX IF EXISTS proj_name_hash_idx;
-- Drop other unnecessary indexes as identified
-- DROP INDEX IF EXISTS some_unused_index;

--Why drop unnecessary indexes?
--Dropping duplicate or rarely used indexes saves disk space and reduces write overhead on INSERT/UPDATE/DELETE operations. It also simplifies maintenance and can improve overall write performance.


---10.3---
CREATE VIEW index_documentation AS
SELECT
  tablename,
  indexname,
  indexdef,
  'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';
--10.3
SELECT * FROM index_documentation;
--What this view does:
--The view documents all indexes whose names include "salary" and provides a short purpose note, so you can quickly see which salary-related indexes exist and why they were created.

-- Summary Questions
-- 1.
-- What is the default index type in PostgreSQL?
-- The default index type is B-tree.
--2.
-- Name three scenarios where you should create an index:
-- Columns frequently used in WHERE clauses.
-- Columns used in JOIN conditions (foreign keys).
-- Columns used in ORDER BY or range queries (dates/numbers).
-- 3.
-- Name two scenarios where you should NOT create an index:
-- On columns with very low selectivity (e.g., almost all rows share the same value).
-- On small tables or on columns that are updated extremely frequently.
-- 4.
-- What happens to indexes when you INSERT, UPDATE, or DELETE data?
-- Indexes must be updated to reflect the change: inserts add index entries, updates modify index entries (delete+insert if key changes), and deletes remove index entries — this adds write overhead.
-- 5.
-- How can you check if a query is using an index?
-- Use EXPLAIN or EXPLAIN ANALYZE and look for Index Scan, Index Only Scan, or Bitmap Index Scan. If you see Seq Scan, the index was not used.




--Additional Challenges--

-- Additional Challenge 1: Index to optimize finding employees hired in a specific month
ALTER TABLE employees ADD COLUMN IF NOT EXISTS hire_date DATE;

CREATE INDEX IF NOT EXISTS emp_hire_month_idx
ON employees ((DATE_PART('month', hire_date)::int));

---2 add---
-- Additional Challenge 2: Composite UNIQUE index on dept_id and email
ALTER TABLE employees ADD COLUMN IF NOT EXISTS email VARCHAR(100);

CREATE UNIQUE INDEX IF NOT EXISTS emp_dept_email_unique_idx
ON employees (dept_id, email);


---3 add---
-- Additional Challenge 3: Compare performance with and without indexes

-- Before the index (take a screenshot)
EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 52000;

-- Create index to optimize the query
CREATE INDEX IF NOT EXISTS emp_salary_filter_idx
ON employees (salary) WHERE salary > 50000;

-- After the index (take a screenshot)
EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 52000;

---4 add---
-- Additional Challenge 4: Covering index for a specific query
-- Covers: SELECT emp_name, salary FROM employees WHERE salary > 50000;

CREATE INDEX IF NOT EXISTS emp_salary_covering_idx
ON employees (salary) INCLUDE (emp_name, dept_id);



-- Task 1: Optimize User Watch History
CREATE INDEX idx_watch_history_user_watch_date ON watch_history (user_id, watch_date DESC);


-- Task 2: Expression Index for Search
CREATE INDEX idx_videos_title_normalized ON videos (lower(trim(title)));

-- SELECT that would utilize this index
SELECT video_id, title
FROM videos
WHERE lower(trim(title)) = 'some title';


-- Task 3: Drop redundant index
DROP INDEX IF EXISTS wh_user_idx;



-- Task 4: Partial index for completed views
CREATE INDEX idx_wh_completed_user_video_date ON watch_history (user_id, video_id, watch_date)
WHERE completed = TRUE;


