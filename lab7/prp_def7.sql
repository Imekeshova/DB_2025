-- Part A: View Creation

-- Task 1: employee_summary
DROP VIEW IF EXISTS employee_summary;
CREATE OR REPLACE VIEW employee_summary AS
SELECT
  e.emp_name,
  d.dept_name,
  e.salary,
  ROUND(
    CASE
      WHEN e.salary > 60000 THEN e.salary * 0.10
      WHEN e.salary > 50000 THEN e.salary * 0.05
      ELSE 0
    END, 2
  ) AS performance_bonus
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Task 2: dept_project_summary (materialized, WITH DATA)
DROP MATERIALIZED VIEW IF EXISTS dept_project_summary;
CREATE MATERIALIZED VIEW dept_project_summary AS
SELECT
  d.dept_name,
  COALESCE(p.project_count, 0)      AS total_projects,
  COALESCE(p.total_budget, 0)       AS total_budget,
  ROUND(COALESCE(p.avg_budget, 0)::numeric, 2) AS avg_budget,
  CASE
    WHEN COALESCE(p.total_budget, 0) > 200000 THEN 'High Investment'
    WHEN COALESCE(p.total_budget, 0) > 100000 THEN 'Medium Investment'
    ELSE 'Standard Investment'
  END AS status
FROM departments d
LEFT JOIN (
  SELECT dept_id,
         COUNT(*) AS project_count,
         SUM(budget) AS total_budget,
         AVG(budget) AS avg_budget
  FROM projects
  GROUP BY dept_id
) p ON d.dept_id = p.dept_id
WITH DATA;

-- Test (Task 2)
-- SELECT * FROM dept_project_summary ORDER BY total_budget DESC;


-- Part B: Role-Based Access Control

-- Task 3: Create Role Hierarchy and Users
DROP ROLE IF EXISTS readonly_role;
DROP ROLE IF EXISTS data_entry_role;
DROP ROLE IF EXISTS john_viewer;
DROP ROLE IF EXISTS mary_editor;

CREATE ROLE readonly_role NOLOGIN;
CREATE ROLE data_entry_role NOLOGIN;

GRANT SELECT ON employee_summary TO readonly_role;
GRANT SELECT ON departments TO readonly_role;

GRANT readonly_role TO data_entry_role;
GRANT INSERT ON employees TO data_entry_role;

CREATE ROLE john_viewer WITH LOGIN PASSWORD 'view123';
CREATE ROLE mary_editor WITH LOGIN PASSWORD 'edit456';

GRANT readonly_role TO john_viewer;
GRANT data_entry_role TO mary_editor;


-- Task 4: Modify and Revoke Access
REVOKE INSERT ON employees FROM data_entry_role;
GRANT UPDATE (salary) ON employees TO data_entry_role;
REVOKE data_entry_role FROM mary_editor;
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


