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


---DEF7---
-- PART A: Basic View Creation
-- TASK 1: Employee Directory View
CREATE OR REPLACE VIEW employee_directory AS
SELECT
    e.emp_name,
    d.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High Earner'
        ELSE 'Standard'
    END AS status
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- TASK 2: Project Summary View
CREATE OR REPLACE VIEW project_summary AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    CASE
        WHEN p.budget > 80000 THEN 'Large'
        WHEN p.budget > 50000 THEN 'Medium'
        ELSE 'Small'
    END AS project_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

-- PART B: View Modifications
-- TASK 3.1: Modify employee_directory (add dept_category)
CREATE OR REPLACE VIEW employee_directory AS
SELECT
    e.emp_name,
    d.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High Earner'
        ELSE 'Standard'
    END AS status,
    CASE
        WHEN d.dept_name ILIKE '%IT%' OR d.dept_name ILIKE '%Development%' THEN 'Technical'
        ELSE 'Non-Technical'
    END AS dept_category
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- TASK 3.2: Rename project_summary to project_overview
ALTER VIEW project_summary RENAME TO project_overview;

-- TASK 3.3: Drop the project_overview view
DROP VIEW IF EXISTS project_overview;

-- PART C: Materialized Views
-- TASK 4: Create and Refresh Materialized View
DROP MATERIALIZED VIEW IF EXISTS dept_summary;
CREATE MATERIALIZED VIEW dept_summary AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    COUNT(p.project_id) AS project_count,
    COALESCE(SUM(p.budget), 0) AS total_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name
WITH DATA;

-- (для обновления после вставки)
-- REFRESH MATERIALIZED VIEW dept_summary;

-- PART D: Role-Based Access Control
-- TASK 5: Create Roles and Users

-- Step 1: Basic Roles
DROP ROLE IF EXISTS viewer_role;
DROP ROLE IF EXISTS editor_role;
CREATE ROLE viewer_role NOLOGIN;
CREATE ROLE editor_role NOLOGIN;

GRANT SELECT ON employee_directory TO viewer_role;
GRANT SELECT ON departments TO viewer_role;

GRANT SELECT ON employees, departments, projects TO editor_role;
GRANT INSERT, UPDATE ON employees TO editor_role;

-- Step 2: Manager Role
DROP ROLE IF EXISTS manager_role;
CREATE ROLE manager_role NOLOGIN;
GRANT editor_role TO manager_role;
GRANT DELETE ON employees TO manager_role;
GRANT UPDATE ON projects TO manager_role;

-- Step 3: Create Users
DROP ROLE IF EXISTS alice_viewer;
DROP ROLE IF EXISTS bob_editor;
DROP ROLE IF EXISTS carol_manager;

CREATE ROLE alice_viewer WITH LOGIN PASSWORD 'view123';
CREATE ROLE bob_editor WITH LOGIN PASSWORD 'edit456';
CREATE ROLE carol_manager WITH LOGIN PASSWORD 'mgr789';

GRANT viewer_role TO alice_viewer;
GRANT editor_role TO bob_editor;
GRANT manager_role TO carol_manager;

-- PART A: Basic View Creation
-- TASK 1: Employee Directory View
CREATE OR REPLACE VIEW employee_directory AS
SELECT
    e.emp_name,
    d.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High Earner'
        ELSE 'Standard'
    END AS status
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- TASK 2: Project Summary View
CREATE OR REPLACE VIEW project_summary AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    CASE
        WHEN p.budget > 80000 THEN 'Large'
        WHEN p.budget > 50000 THEN 'Medium'
        ELSE 'Small'
    END AS project_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;

-- PART B: View Modifications
-- TASK 3.1: Modify employee_directory (add dept_category)
CREATE OR REPLACE VIEW employee_directory AS
SELECT
    e.emp_name,
    d.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High Earner'
        ELSE 'Standard'
    END AS status,
    CASE
        WHEN d.dept_name ILIKE '%IT%' OR d.dept_name ILIKE '%Development%' THEN 'Technical'
        ELSE 'Non-Technical'
    END AS dept_category
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;

-- TASK 3.2: Rename project_summary to project_overview
ALTER VIEW project_summary RENAME TO project_overview;

-- TASK 3.3: Drop the project_overview view
DROP VIEW IF EXISTS project_overview;

-- PART C: Materialized Views
-- TASK 4: Create and Refresh Materialized View
DROP MATERIALIZED VIEW IF EXISTS dept_summary;
CREATE MATERIALIZED VIEW dept_summary AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    COUNT(p.project_id) AS project_count,
    COALESCE(SUM(p.budget), 0) AS total_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_name
WITH DATA;

-- (для обновления после вставки)
-- REFRESH MATERIALIZED VIEW dept_summary;

-- PART D: Role-Based Access Control
-- TASK 5: Create Roles and Users

-- Step 1: Basic Roles
DROP ROLE IF EXISTS viewer_role;
DROP ROLE IF EXISTS editor_role;
CREATE ROLE viewer_role NOLOGIN;
CREATE ROLE editor_role NOLOGIN;

GRANT SELECT ON employee_directory TO viewer_role;
GRANT SELECT ON departments TO viewer_role;

GRANT SELECT ON employees, departments, projects TO editor_role;
GRANT INSERT, UPDATE ON employees TO editor_role;

-- Step 2: Manager Role
DROP ROLE IF EXISTS manager_role;
CREATE ROLE manager_role NOLOGIN;
GRANT editor_role TO manager_role;
GRANT DELETE ON employees TO manager_role;
GRANT UPDATE ON projects TO manager_role;

-- Step 3: Create Users
DROP ROLE IF EXISTS alice_viewer;
DROP ROLE IF EXISTS bob_editor;
DROP ROLE IF EXISTS carol_manager;

CREATE ROLE alice_viewer WITH LOGIN PASSWORD 'view123';
CREATE ROLE bob_editor WITH LOGIN PASSWORD 'edit456';
CREATE ROLE carol_manager WITH LOGIN PASSWORD 'mgr789';

GRANT viewer_role TO alice_viewer;
GRANT editor_role TO bob_editor;
GRANT manager_role TO carol_manager;


---TASK 3.1---
DROP VIEW IF EXISTS employee_directory;

CREATE VIEW employee_directory AS
SELECT
    e.emp_name,
    d.dept_name,
    d.location,
    e.salary,
    CASE
        WHEN e.salary > 55000 THEN 'High Earner'
        ELSE 'Standard'
    END AS status,
    CASE
        WHEN d.dept_name ILIKE '%IT%' OR d.dept_name ILIKE '%Development%' THEN 'Technical'
        ELSE 'Non-Technical'
    END AS dept_category
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
ORDER BY d.dept_name, e.emp_name;



