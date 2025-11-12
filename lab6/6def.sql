----------------------------
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS projects CASCADE;

-- Create table: employees
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(50),
 dept_id INT,
 salary DECIMAL(10, 2)
);
-- Create table: departments
CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
-- Create table: projects
CREATE TABLE projects (
 project_id INT PRIMARY KEY,
 project_name VARCHAR(50),
 dept_id INT,
 budget DECIMAL(10, 2)
);

-- Insert data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);
-- Insert data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');
-- Insert data into projects
INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);


--TASK 2.1--
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;
-- There are 5 employees and 4 departments in the database.
-- The result of a CROSS JOIN contains N × M rows.
-- Therefore, 5 × 4 = 20 rows in total.

--TASK 2.2--
--A)2.2 Comma notation
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;
--B)2.2 INNER JOIN with TRUE condition
SELECT  e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

--TASK 2.3-- Practical CROSS JOIN
SELECT  e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p;


-- TASK 3.1: Basic INNER JOIN with ON
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;
-- There are 4 rows in the result.
-- Tom Brown is not included because his dept_id is NULL,
-- and INNER JOIN only returns rows that have matching values in both tables.

-- TASK 3.2: INNER JOIN with USING
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);
-- Same 4 rows as in Task 3.1.
-- The difference: USING merges the column dept_id (no duplicates in output),
-- while ON keeps both e.dept_id and d.dept_id if they were selected.

-- TASK 3.3: NATURAL INNER JOIN
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;
-- Same result as USING (4 rows).
-- NATURAL JOIN automatically joins on all columns with the same name (here dept_id).
-- Be careful: if more columns have the same name, they will be joined automatically too.

-- TASK 3.4: Multi-table INNER JOIN
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;
-- 6 rows are returned.
-- Employees are shown with their department and each project belonging to that department.
-- Tom Brown is not included because he has no department.


--TASK 4.1-- Basic LEFT JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;
-- Tom Brown appears in the result with NULL values for department columns.

--TASK 4.2-- LEFT JOIN with USING
SELECT emp_name, dept_id, dept_name
FROM employees
LEFT JOIN departments USING (dept_id);
-- Same output as Task 4.1 but with a single dept_id column.

--TASK 4.3-- Find Unmatched Records
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;
-- Returns employees who are not assigned to any department (Tom Brown).

--TASK 4.4-- LEFT JOIN with Aggregation
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
-- Shows all departments and the number of employees in each.
-- Departments with no employees show a count of 0.

--TASK 5.1-- Basic RIGHT JOIN
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;
-- Shows all departments, including those without employees.

--TASK 5.2-- Converted to LEFT JOIN
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;
-- Same result as the RIGHT JOIN.

--TASK 5.3-- Departments Without Employees
SELECT d.dept_name, d.location
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;
-- Returns only departments that have no employees.


--TASK 6.1-- Basic FULL JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
-- NULL on the left = departments without employees.
-- NULL on the right = employees without departments.

--TASK 6.2-- FULL JOIN with Projects
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

--TASK 6.3-- Find Orphaned Records
SELECT
 CASE
  WHEN e.emp_id IS NULL THEN 'Department without employees'
  WHEN d.dept_id IS NULL THEN 'Employee without department'
 END AS record_status,
 e.emp_name,
 d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;
-- FULL JOIN keeps all rows from both tables.
-- The CASE labels which side is missing:
-- e.emp_id IS NULL → department has no employees
-- d.dept_id IS NULL → employee has no department
-- The WHERE filters only these unmatched rows.

-- TASK 7.1 -- Filter in ON clause (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- TASK 7.2 -- Filter in WHERE clause (LEFT JOIN)
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- The condition is moved to the WHERE clause.
-- The filter is applied AFTER the join.
-- Only employees whose departments are in Building A remain;
-- employees without departments or from other locations are excluded.

-- TASK 7.3 -- ON vs WHERE with INNER JOIN
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

--7.3
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
-- For INNER JOIN the two queries return identical results,
-- because INNER JOIN removes unmatched rows automatically,
-- so it does not matter whether the filter is placed in ON or WHERE.


-- TASK 8.1 -- Multiple Joins with Different Types
SELECT
  d.dept_name,
  e.emp_name,
  e.salary,
  p.project_name,
  p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
-- This query demonstrates combining multiple LEFT JOINs.
-- Starting from departments (d):
--   1. LEFT JOIN employees (e): keeps all departments even if no employees exist.
--   2. LEFT JOIN projects (p): keeps departments even if no projects exist.
-- The result shows every department, its employees (if any),
-- and all projects associated with that department.
-- If a department has no employees or projects, those columns appear as NULL.

-- TASK 8.2 -- Self Join (Employee -> Manager)
ALTER TABLE employees ADD COLUMN IF NOT EXISTS manager_id INT;

-- Example data for manager relationships
UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

--8.2
SELECT
  e.emp_name AS employee,
  m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
-- A self-join joins the same table to itself.
-- 'e' represents the employee; 'm' represents their manager.
-- The join condition matches each employee’s manager_id
-- to another employee’s emp_id.
-- The LEFT JOIN ensures all employees are shown,
-- even those who do not have a manager (manager column = NULL).

-- TASK 8.3 -- Departments with Average Salary > 50000
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;
-- This query calculates the average salary per department.
-- GROUP BY groups employees by their department.
-- HAVING filters those groups where the average salary exceeds 50,000.
-- Only departments with employees and avg_salary > 50000 appear in the result.



--DEF
--1 TASK
SELECT e.emp_name, e.salary, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_name = 'IT';

--TASK 2
SELECT d.dept_name, COUNT(p.project_id) AS project_count
FROM departments d
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name;

--TASK 2
SELECT d.dept_name, COUNT(p.project_id) AS project_count
FROM departments d
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name;

--TASK 3
SELECT p.project_name, p.budget
FROM projects p
WHERE dept_id IS NULL;

--TASK 4
SELECT e.emp_name, p.project_name, p.budget
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id
WHERE d.dept_name = 'IT';

--TASK 5
SELECT d.dept_name,  SUM(p.budget) AS total_budget
FROM departments d
INNER JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING SUM(p.budget) > 10000;



--TASK 4--
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;


--TASK 2--
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       COUNT(p.project_id) AS project_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;

--TASK 3--
SELECT d.dept_name,
       SUM(e.salary) AS total_salaries,
       SUM(p.budget) AS total_budgets
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;

--TASK 5--
SELECT d.dept_name,
       COUNT(e.emp_id) AS emp_count,
       COUNT(p.project_id) AS proj_count,
       CASE
         WHEN COUNT(e.emp_id) = 0 AND COUNT(p.project_id) = 0 THEN 'Empty'
         WHEN COUNT(e.emp_id) = 0 THEN 'Needs Employees'
         WHEN COUNT(p.project_id) = 0 THEN 'Needs Projects'
         ELSE 'Active'
       END AS status
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name;





