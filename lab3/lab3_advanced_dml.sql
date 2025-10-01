-- На случай перезапуска
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE  IF EXISTS temp_employees CASCADE;

-- PART A
-- 1
CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name  TEXT NOT NULL,
    department TEXT,
    salary     INTEGER,
    hire_date  DATE,
    status     TEXT NOT NULL DEFAULT 'Active'  -- строковый DEFAULT в одинарных кавычках
);

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   TEXT NOT NULL UNIQUE,          -- UNIQUE нужен для ON CONFLICT (dept_name)
    budget      INTEGER,
    manager_id  INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name TEXT,
    dept_id      INTEGER REFERENCES departments(dept_id) ON DELETE SET NULL,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- PART B

-- 2
-- Вставляем сотрудника, задавая только 4 поля
-- emp_id = DEFAULT — автоинкремент (SERIAL);
-- остальные поля (salary, hire_date, status) будут NULL/DEFAULT
INSERT INTO employees (emp_id, first_name, last_name, department, salary)
VALUES (DEFAULT, 'Malika', 'Imekeshova', 'IT', '100000');

-- 2nd data
INSERT INTO employees (emp_id, first_name, last_name, department, salary)
VALUES (DEFAULT, 'Madina', 'Zangirova', 'HR', '20000');

-- FOR CHECK 2
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM employees
ORDER BY emp_id;

-- 3
-- salary не указываем станет NULL
-- так же status не указываем станет 'Active' из DEFAULT
INSERT INTO employees (first_name, last_name, department, salary ,hire_date)
VALUES ('Elza', 'Yanke', 'HR',52000 ,CURRENT_DATE);

-- FOR CHECK 3
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM employees
ORDER BY emp_id DESC
LIMIT 5;

-- 4
-- Вставляем 3 отдела за один запрос
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
  ('IT',    120000, NULL),
  ('HR',     80000, NULL),
  ('Sales', 150000, NULL)
ON CONFLICT (dept_name) DO NOTHING;

-- FOR CHECK 4
SELECT dept_id, dept_name, budget, manager_id
FROM departments
ORDER BY dept_id;

--5
INSERT INTO  employees (first_name, last_name, department, salary, hire_date)
VALUES ('Nurasyl', 'Taimas', 'IT', CAST(75000 * 1.1 AS INTEGER), '2019-05-10');

--FOR CHECK 5
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM employees
ORDER BY emp_id DESC
LIMIT 5;

--6
-- Создаём пустую TEMP-таблицу с той же структурой КАК employees
CREATE TEMP TABLE temp_employees AS
SELECT *
FROM employees
WHERE 1 = 0;   -- копируем схему без данных

-- 6.2 Копируем в неё всех IT сотрудников
INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

--FOR CHECK 6
SELECT COUNT(*) AS it_rows FROM temp_employees;
-- Посмотреть последние записи
SELECT emp_id, first_name, last_name, department, salary, hire_date, status
FROM temp_employees
ORDER BY emp_id DESC
LIMIT 10;


--PART C

--7
-- UPDATE: +10% к зарплате
UPDATE employees
SET salary = CAST(salary * 1.10 AS INTEGER) --приведение к INTEGER
WHERE salary IS NOT NULL
RETURNING emp_id, (salary / 1.10)::INTEGER AS old_salary, salary AS new_salary;


--FOR CHECK 7
SELECT emp_id, first_name, last_name, department, salary
FROM employees
ORDER BY emp_id;

--8
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01'
RETURNING emp_id, first_name, last_name, salary, hire_date, status;

-- FOR CHECK 8
SELECT emp_id, first_name, last_name, salary, hire_date, status
FROM employees
ORDER BY emp_id;

-- 9) CASE в категории (перезаписывает department)
UPDATE employees
SET department = CASE
  WHEN salary > 80000 THEN 'Management'
  WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
  ELSE 'Junior'
END
WHERE salary IS NOT NULL
RETURNING emp_id, salary, department; -- CHECK 9a

-- CHECK 9b
SELECT emp_id, first_name, last_name, salary, department
FROM employees
ORDER BY emp_id;
-- (чтобы 11 сработал по именам категорий)
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Management',0,NULL), ('Senior',0,NULL), ('Junior',0,NULL)
ON CONFLICT (dept_name) DO NOTHING
RETURNING dept_id, dept_name, budget;              -- CHECK 9c

-- CHECK 9d
SELECT dept_id, dept_name, budget
FROM departments
ORDER BY dept_id;

--ADD FOR 10TH TASK
UPDATE employees
SET status = 'Inactive', department = 'TempDept'
WHERE first_name = 'Madina' AND last_name = 'Zangirova'
RETURNING emp_id, first_name, last_name, department, status;

-- 10) UPDATE с DEFAULT (department → NULL, т.к. DEFAULT не задан)
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive'
RETURNING emp_id, department, status;                                    -- CHECK 10a

-- CHECK 10b
SELECT emp_id, first_name, last_name, department, status
FROM employees
ORDER BY emp_id;


-- 11) UPDATE с подзапросом: бюджет = 120% от средней зарплаты в отделе
UPDATE departments d
SET budget = CAST(s.avg_salary * 1.20 AS INTEGER)
FROM (
  SELECT e.department AS dept_name, AVG(e.salary) AS avg_salary
  FROM employees e
  WHERE e.department IS NOT NULL AND e.salary IS NOT NULL
  GROUP BY e.department
) s
WHERE d.dept_name = s.dept_name
RETURNING d.dept_id, d.dept_name, d.budget;                              -- CHECK 11a

-- CHECK 11b
SELECT dept_id, dept_name, budget
FROM departments
ORDER BY dept_id;

-- (for 12 (точно затронул записи, добавим 1 сотрудника Sales))
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('SALES','Kairat','Sales',40000,'2024-01-01')
RETURNING emp_id, first_name, last_name, department, salary;             -- CHECK pre-12

-- 12) UPDATE нескольких колонок (только для Sales)
UPDATE employees
SET salary = CAST(salary * 1.15 AS INTEGER),
    status = 'Promoted'
WHERE department = 'Sales'
RETURNING emp_id, salary, status;              -- CHECK 12a

-- CHECK 12b
SELECT emp_id, first_name, last_name, department, salary, status
FROM employees
ORDER BY emp_id;


--PART D

-- 13) Удаляем сотрудников со статусом 'Terminated'
DELETE FROM employees
WHERE status = 'Terminated';

-- FOR CHECK 13
SELECT emp_id, first_name, last_name, status
FROM employees
ORDER BY emp_id;

-- 14) Удаляем сотрудников с зарплатой < 40000, датой найма > '2023-01-01' и NULL department
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- FOR CHECK 14
SELECT emp_id, first_name, last_name, salary, hire_date, department
FROM employees
ORDER BY emp_id;

-- 15) Удаляем отделы, которые не используются сотрудниками
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

-- FOR CHECK 15
SELECT dept_id, dept_name, budget
FROM departments
ORDER BY dept_id;


-- ПОДГОТОВКА ДЛЯ П.16 (гарантируем валидный dept_id для FK)
-- Если вдруг нет ни одного отдела — создадим один
INSERT INTO departments (dept_name, budget, manager_id)
SELECT 'LegacyDept', 0, NULL
WHERE NOT EXISTS (SELECT 1 FROM departments);

-- Добавим проект со старой датой, привязав к существующему отделу
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
SELECT 'Legacy CRM System', d.dept_id, DATE '2022-01-01', DATE '2022-12-31', 60000
FROM departments d
ORDER BY d.dept_id
LIMIT 1;

-- 16) Удаляем проекты с end_date < '2023-01-01' и возвращаем удалённые строки
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING project_id, project_name, end_date;

-- FOR CHECK 16
SELECT project_id, project_name, end_date
FROM projects
ORDER BY project_id;



-- 17) Добавляем сотрудника с NULL salary и NULL department
INSERT INTO employees (first_name, last_name, salary, department, hire_date)
VALUES ('Null', 'Employee', NULL, NULL, CURRENT_DATE);

-- FOR CHECK 17
SELECT emp_id, first_name, last_name, salary, department
FROM employees
ORDER BY emp_id;

-- 18) Обновляем department на 'Unassigned', где он равен NULL
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- FOR CHECK 18
SELECT emp_id, first_name, last_name, department
FROM employees
ORDER BY emp_id;

-- 19) Удаляем всех сотрудников, у которых salary IS NULL или department IS NULL
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- FOR CHECK 19
SELECT emp_id, first_name, last_name, salary, department
FROM employees
ORDER BY emp_id;


--PART D

-- 20) INSERT with RETURNING: вернуть emp_id и полное имя
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Return', 'Demo', 'IT', 60000, CURRENT_DATE)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

-- FOR CHECK 20
SELECT emp_id, first_name, last_name, department, salary
FROM employees
ORDER BY emp_id DESC
LIMIT 5;

-- 21) UPDATE with RETURNING: +5000 для отдела IT, вернуть id, old/new
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT' AND salary IS NOT NULL
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

-- FOR CHECK 21
SELECT emp_id, first_name, last_name, department, salary
FROM employees
WHERE department = 'IT'
ORDER BY emp_id;

-- 22) DELETE with RETURNING (все колонки): hire_date < '2020-01-01'
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- FOR CHECK 22
SELECT emp_id, first_name, last_name, hire_date, status
FROM employees
ORDER BY emp_id;

--PART G
-- 23) Conditional INSERT (WHERE NOT EXISTS)
WITH candidate AS (
  SELECT 'Cond'::TEXT AS first_name,
         'Insert'::TEXT AS last_name,
         'IT'::TEXT     AS department,
         45000::INT     AS salary,
         CURRENT_DATE   AS hire_date
)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT c.first_name, c.last_name, c.department, c.salary, c.hire_date
FROM candidate c
WHERE NOT EXISTS (
  SELECT 1 FROM employees e
  WHERE e.first_name = c.first_name AND e.last_name = c.last_name
)
RETURNING emp_id, first_name, last_name;

-- FOR CHECK 23
SELECT emp_id, first_name, last_name
FROM employees
WHERE first_name = 'Cond' AND last_name = 'Insert';


-- 24) UPDATE with JOIN logic via subqueries: бюджет >100000 → +10%, иначе +5%
UPDATE employees e
SET salary = CAST(
  salary * CASE
    WHEN (SELECT d.budget FROM departments d WHERE d.dept_name = e.department) > 100000
      THEN 1.10 ELSE 1.05
  END AS INTEGER
)
WHERE salary IS NOT NULL AND e.department IS NOT NULL
RETURNING emp_id, salary;

-- FOR CHECK 24
SELECT emp_id, first_name, last_name, department, salary
FROM employees
ORDER BY emp_id;

-- 25) Bulk: вставить 5 сотрудников одним INSERT, затем всем +10% одним UPDATE
INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
  ('Bulk','One','Management', 30000, CURRENT_DATE),
  ('Bulk','Two','Management', 31000, CURRENT_DATE),
  ('Bulk','Three','Management', 32000, CURRENT_DATE),
  ('Bulk','Four','Management', 33000, CURRENT_DATE),
  ('Bulk','Five','Management', 34000, CURRENT_DATE);

UPDATE employees
SET salary = CAST(salary * 1.10 AS INTEGER)
WHERE first_name = 'Bulk'
RETURNING emp_id, salary;

-- FOR CHECK 25
SELECT emp_id, first_name, last_name, department, salary
FROM employees
WHERE first_name = 'Bulk'
ORDER BY emp_id;

-- 26) Data migration: архив 'employee_archive' ← все 'Inactive', затем удалить из основной
CREATE TABLE IF NOT EXISTS employee_archive AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive'
RETURNING emp_id, first_name, last_name;

-- FOR CHECK 26
SELECT COUNT(*) AS archived_rows FROM employee_archive;

-- 27) Complex: +30 дней к end_date, где budget > 50000 И у связанного отдела >3 сотрудников
-- (на всякий случай создадим проект для 'Management', если его ещё нет)
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
SELECT 'Mgmt Big Project', d.dept_id, CURRENT_DATE, CURRENT_DATE + INTERVAL '10 days', 60000
FROM departments d
WHERE d.dept_name = 'Management'
  AND NOT EXISTS (SELECT 1 FROM projects p WHERE p.project_name = 'Mgmt Big Project');

UPDATE projects p
SET end_date = COALESCE(end_date, CURRENT_DATE) + INTERVAL '30 days'
WHERE p.budget > 50000
  AND EXISTS (
    SELECT 1 FROM departments d
    WHERE d.dept_id = p.dept_id
      AND (SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_name) > 3
  )
RETURNING project_id, project_name, end_date;

-- FOR CHECK 27
SELECT project_id, project_name, end_date
FROM projects
WHERE project_name = 'Mgmt Big Project';




