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

----LAB7----
---IMEKESHOVA_MALIKA---
--TASK 2.1---
CREATE OR REPLACE VIEW employee_details AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  d.dept_name,
  d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

--TEST 2.1---
SELECT * FROM employee_details ORDER BY emp_id;


--TASK 2.2---
CREATE OR REPLACE VIEW dept_statistics AS
SELECT
  d.dept_id,
  d.dept_name,
  COUNT(e.emp_id)                                  AS employee_count,
  ROUND(COALESCE(AVG(e.salary), 0)::numeric, 2)     AS average_salary,
  COALESCE(MAX(e.salary), 0)                        AS max_salary,
  COALESCE(MIN(e.salary), 0)                        AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

--TEST 2.2---
SELECT * FROM dept_statistics ORDER BY employee_count DESC;


--TASK 2.3---
CREATE OR REPLACE VIEW project_overview AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  p.dept_id,
  COALESCE(d.dept_name, 'Unassigned')              AS dept_name,
  d.location,
  COALESCE(ec.team_size, 0)                         AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS team_size
  FROM employees
  GROUP BY dept_id
) ec ON p.dept_id = ec.dept_id;

--TEST 2.3---
SELECT * FROM project_overview ORDER BY project_id;


--TASK 2.4---
CREATE OR REPLACE VIEW high_earners AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

--TEST 2.4---
SELECT * FROM high_earners ORDER BY salary DESC;


--TASK 3.1---
CREATE OR REPLACE VIEW employee_details AS
SELECT
  e.emp_id,
  e.emp_name,
  e.salary,
  d.dept_name,
  d.location,
  CASE
    WHEN e.salary > 60000 THEN 'High'
    WHEN e.salary > 50000 THEN 'Medium'
    ELSE 'Standard'
  END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

--TEST 3.1---
SELECT * FROM employee_details ORDER BY emp_id;

--TASK 3.2--
ALTER VIEW IF EXISTS  high_earners RENAME TO top_performers;

--TEST 3.2---
SELECT * FROM top_performers ORDER BY salary DESC;

--TASK 3.3---
CREATE TEMPORARY VIEW temp_view AS
SELECT
  emp_id,
  emp_name,
  salary,
  dept_id
FROM employees
WHERE salary < 50000;

--TEST 3.3---
SELECT * FROM temp_view ORDER BY emp_id;

--DROP temp view
DROP VIEW IF EXISTS temp_view;

--TASK 4.1---
CREATE OR REPLACE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

--TEST 4.1---
SELECT * FROM employee_salaries ORDER BY emp_id;

--TASK 4.2---
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

--VERIFY 4.2---
SELECT * FROM employees WHERE emp_name = 'John Smith';

--TASK 4.3---
-- Insert new employee Alice Johnson through the view
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

--TEST 4.3---
SELECT * FROM employees WHERE emp_id = 6;

--TEST 4.4---
CREATE OR REPLACE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

--VERIFY 4.4---
-- After the failed insert above, confirm Bob Wilson is NOT in employees
SELECT * FROM employees WHERE emp_id = 7;

---TASK 5.1---
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
  d.dept_id,
  d.dept_name,
  COALESCE(e.emp_count, 0)          AS total_employees,
  COALESCE(e.total_salaries, 0)     AS total_salaries,
  COALESCE(p.project_count, 0)      AS total_projects,
  COALESCE(p.total_budget, 0)       AS total_project_budget
FROM departments d
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS emp_count, SUM(salary) AS total_salaries
  FROM employees
  GROUP BY dept_id
) e ON d.dept_id = e.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS project_count, SUM(budget) AS total_budget
  FROM projects
  GROUP BY dept_id
) p ON d.dept_id = p.dept_id
WITH DATA;

--TEST 5.1---
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

--TASK 5.2---
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

--TEST 5.2 (before refresh)---
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

--REFRESH and test again---
REFRESH MATERIALIZED VIEW dept_summary_mv;

--TEST 5.2 (after refresh)---
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

--TASK 5.3---
CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id ON dept_summary_mv (dept_id);

--5.3--Concurrent refresh (note: cannot run inside a transaction block)
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

--TEST 5.3---
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;


DROP MATERIALIZED VIEW IF EXISTS project_stats_mv;
--TASK 5.4---
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv;

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT
  p.project_id,
  p.project_name,
  p.budget,
  COALESCE(d.dept_name, 'Unassigned') AS dept_name,
  COALESCE(ec.team_size, 0) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN (
  SELECT dept_id, COUNT(*) AS team_size
  FROM employees
  GROUP BY dept_id
) ec ON p.dept_id = ec.dept_id
WITH NO DATA;

REFRESH MATERIALIZED VIEW project_stats_mv;
SELECT * FROM project_stats_mv ORDER BY project_id;

--TEST 5.4 (querying BEFORE population, will show expected error)
SELECT * FROM project_stats_mv;

-- Now populate it
REFRESH MATERIALIZED VIEW project_stats_mv;

--TEST 5.4 (after refresh)
SELECT * FROM project_stats_mv ORDER BY project_id;


-- TASK 6.1 ---
DROP ROLE IF EXISTS analyst;
DROP ROLE IF EXISTS data_viewer;
DROP ROLE IF EXISTS report_user;

CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user WITH LOGIN PASSWORD 'report456';

-- View roles
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';


-- TASK 6.2 ---
DROP ROLE IF EXISTS db_creator;
DROP ROLE IF EXISTS user_manager;
DROP ROLE IF EXISTS admin_user;

CREATE ROLE db_creator WITH CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager WITH CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user WITH SUPERUSER LOGIN PASSWORD 'admin999';


-- TASK 6.3 ---
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;


-- TASK 6.4 ---
-- create group roles
DROP ROLE IF EXISTS hr_team;
DROP ROLE IF EXISTS finance_team;
DROP ROLE IF EXISTS it_team;

CREATE ROLE hr_team NOLOGIN;
CREATE ROLE finance_team NOLOGIN;
CREATE ROLE it_team NOLOGIN;

-- create individual users
DROP ROLE IF EXISTS hr_user1;
DROP ROLE IF EXISTS hr_user2;
DROP ROLE IF EXISTS finance_user1;

CREATE ROLE hr_user1 WITH LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 WITH LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 WITH LOGIN PASSWORD 'fin001';

-- assign members to groups
GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

-- grant privileges to groups
GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;


-- TASK 6.5 ---
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;


-- TASK 6.6 ---
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

-- TASK 7.1 ---
DROP ROLE IF EXISTS read_only;
DROP ROLE IF EXISTS junior_analyst;
DROP ROLE IF EXISTS senior_analyst;

CREATE ROLE read_only NOLOGIN;
CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

-- grant select on existing tables/views in public
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

-- make junior and senior members of read_only
GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

-- grant extra privileges to senior_analyst
GRANT INSERT, UPDATE ON employees TO senior_analyst;


-- TASK 7.2 ---
DROP ROLE IF EXISTS project_manager;
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';

-- transfer ownership (use IF EXISTS to avoid errors if object missing)
ALTER VIEW IF EXISTS dept_statistics OWNER TO project_manager;
ALTER TABLE IF EXISTS projects OWNER TO project_manager;

-- check ownership (user can run this SELECT)
-- SELECT tablename, tableowner FROM pg_tables WHERE schemaname = 'public';


-- TASK 7.3 ---
DROP ROLE IF EXISTS temp_owner;
CREATE ROLE temp_owner WITH LOGIN PASSWORD 'temp123';

-- create temp_table owned by current user, then transfer to temp_owner
DROP TABLE IF EXISTS temp_table;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

-- reassign and drop owned objects, then drop role
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE IF EXISTS temp_owner;


-- TASK 7.4 ---
-- safe clean & recreate hr_team and finance_team (minimal)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hr_team') THEN
    REVOKE ALL PRIVILEGES ON employees FROM hr_team;
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM hr_team;
    REASSIGN OWNED BY hr_team TO CURRENT_USER;
    DROP OWNED BY hr_team;
    DROP ROLE hr_team;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'finance_team') THEN
    REVOKE ALL PRIVILEGES ON employees FROM finance_team;
    REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM finance_team;
    REASSIGN OWNED BY finance_team TO CURRENT_USER;
    DROP OWNED BY finance_team;
    DROP ROLE finance_team;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- recreate roles and views
CREATE ROLE hr_team NOLOGIN;
CREATE ROLE finance_team NOLOGIN;

CREATE OR REPLACE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

CREATE OR REPLACE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON hr_employee_view TO hr_team;
GRANT SELECT ON finance_employee_view TO finance_team;

---TASK 8.1---
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
  d.dept_name,
  d.location,
  COALESCE(e.emp_count,0)                                AS employee_count,
  ROUND(COALESCE(e.avg_salary,0)::numeric,2)             AS average_salary,
  COALESCE(p.project_count,0)                            AS active_projects,
  COALESCE(p.total_budget,0)                             AS total_project_budget,
  ROUND(COALESCE(p.total_budget,0)::numeric / NULLIF(COALESCE(e.emp_count,0),0),2) AS budget_per_employee
FROM departments d
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS emp_count, AVG(salary) AS avg_salary
  FROM employees e WHERE e.dept_id = d.dept_id
) e ON true
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS project_count, SUM(budget) AS total_budget
  FROM projects p WHERE p.dept_id = d.dept_id
) p ON true;
---8.2 TASK---
ALTER TABLE projects ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
  p.project_name,
  p.budget,
  COALESCE(d.dept_name,'Unassigned') AS dept_name,
  p.created_date,
CASE
    WHEN p.budget > 150000 THEN 'Critical Review Required'
    WHEN p.budget > 100000 THEN 'Management Approval Needed'
    ELSE 'Standard Process'
  END AS approval_status
FROM projects p
LEFT JOIN departments d On p.dept_id = d.dept_id
WHERE p.budget > 75000;

----8.3 TASK ---
DROP ROLE IF EXISTS viewer_role;
CREATE ROLE viewer_role NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

DROP ROLE IF EXISTS entry_role;
CREATE ROLE entry_role NOLOGIN;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

DROP ROLE IF EXISTS analyst_role;
CREATE ROLE analyst_role NOLOGIN;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

DROP ROLE IF EXISTS manager_role;
CREATE ROLE manager_role NOLOGIN;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

DROP ROLE IF EXISTS alice;
CREATE ROLE alice WITH LOGIN PASSWORD 'alice123';
GRANT viewer_role TO alice;

DROP ROLE IF EXISTS bob;
CREATE ROLE bob WITH LOGIN PASSWORD 'bob123';
GRANT analyst_role TO bob;

DROP ROLE IF EXISTS charlie;
CREATE ROLE charlie WITH LOGIN PASSWORD 'charlie123';
GRANT manager_role TO charlie;





