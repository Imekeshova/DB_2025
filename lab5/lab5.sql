-- ==========================================================
-- Database Constraints - LabWork5
-- Name: <IMEKESHOVA MALIKA>
-- Student ID: <24B031819>
-- Date: 2025-10-13
-- ===========================
DROP TABLE IF EXISTS order_details_ecom CASCADE;
DROP TABLE IF EXISTS orders_ecom CASCADE;
DROP TABLE IF EXISTS products_ecom CASCADE;
DROP TABLE IF EXISTS customers_ecom CASCADE;

DROP TABLE IF EXISTS order_items_fk CASCADE;
DROP TABLE IF EXISTS orders_fk CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

DROP TABLE IF EXISTS library_books CASCADE;
DROP TABLE IF EXISTS library_publishers CASCADE;
DROP TABLE IF EXISTS library_authors CASCADE;

DROP TABLE IF EXISTS employees_dept CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

DROP TABLE IF EXISTS student_courses CASCADE;

DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS course_enrollments CASCADE;

DROP TABLE IF EXISTS customers_nn CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;

DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS products_catalog CASCADE;
DROP TABLE IF EXISTS employees_chk CASCADE;

-- =========================================
-- Part 1: CHECK Constraints
-- =========================================

-- Task 1.1: Basic CHECK Constraint (employees)
-- age must be 18..65; salary > 0
CREATE TABLE employees_chk (
  employee_id   INTEGER,
  first_name    TEXT,
  last_name     TEXT,
  age           INTEGER CHECK (age BETWEEN 18 AND 65),
  salary        NUMERIC CHECK (salary > 0)
);

-- Valid inserts (≥2 rows)
INSERT INTO employees_chk VALUES
(1,'John','Smith',30, 70000),
(2,'Sarah','Johnson',45, 90000);

-- Invalid inserts (commented; each should FAIL its CHECK)
-- INSERT INTO employees_chk VALUES (3,'Too','Young',17, 50000);     -- FAIL: age < 18
-- INSERT INTO employees_chk VALUES (4,'Too','Old',66,  50000);      -- FAIL: age > 65
-- INSERT INTO employees_chk VALUES (5,'Bad','Salary',25, 0);        -- FAIL: salary > 0

-- Quick test
SELECT COUNT(*) AS ok_rows_1_1 FROM employees_chk; -- EXPECTED: 2


-- Task 1.2: Named CHECK Constraint (products_catalog)
-- valid_discount: regular_price > 0, discount_price > 0, discount_price < regular_price
CREATE TABLE products_catalog (
  product_id      INTEGER,
  product_name    TEXT,
  regular_price   NUMERIC,
  discount_price  NUMERIC,
  CONSTRAINT valid_discount CHECK (
    regular_price > 0
    AND discount_price > 0
    AND discount_price < regular_price
  )
);

-- Valid inserts
INSERT INTO products_catalog VALUES
(101,'Mouse', 6000, 4500),
(102,'Keyboard', 20000, 15000);

-- Invalid inserts (commented)
-- INSERT INTO products_catalog VALUES (103,'ZeroReg', 0, 1000);      -- FAIL: regular_price > 0
-- INSERT INTO products_catalog VALUES (104,'ZeroDisc', 5000, 0);      -- FAIL: discount_price > 0
-- INSERT INTO products_catalog VALUES (105,'BadDisc', 5000, 7000);    -- FAIL: discount < regular

-- Test
SELECT COUNT(*) AS ok_rows_1_2 FROM products_catalog; -- EXPECTED: 2


-- Task 1.3: Multiple Column CHECK (bookings)
-- num_guests 1..10; check_out_date > check_in_date
CREATE TABLE bookings (
  booking_id     INTEGER,
  check_in_date  DATE,
  check_out_date DATE,
  num_guests     INTEGER,
  CONSTRAINT guests_range CHECK (num_guests BETWEEN 1 AND 10),
  CONSTRAINT valid_stay CHECK (check_out_date > check_in_date)
);

-- Valid inserts
INSERT INTO bookings VALUES
(1, DATE '2025-01-10', DATE '2025-01-12', 2),
(2, DATE '2025-02-01', DATE '2025-02-05', 4);

-- Invalid inserts (commented)
-- INSERT INTO bookings VALUES (3, DATE '2025-03-10', DATE '2025-03-09', 2);  -- FAIL: checkout before checkin
-- INSERT INTO bookings VALUES (4, DATE '2025-04-01', DATE '2025-04-03', 0);  -- FAIL: num_guests < 1
-- INSERT INTO bookings VALUES (5, DATE '2025-04-01', DATE '2025-04-03', 11); -- FAIL: num_guests > 10

-- Test
SELECT COUNT(*) AS ok_rows_1_3 FROM bookings; -- EXPECTED: 2


-- Task 1.4: Testing CHECK Constraints — (уже сделано в 1.1–1.3)
-- 1) валидные INSERT есть
-- 2) невалидные INSERT закомментированы
-- 3) объяснение в комментариях к каждой строке

-- =========================================
-- Part 2: NOT NULL Constraints
-- =========================================

-- Task 2.1: NOT NULL Implementation (customers)
CREATE TABLE customers_nn (
  customer_id        INTEGER NOT NULL,
  email              TEXT    NOT NULL,
  phone              TEXT,               -- nullable
  registration_date  DATE    NOT NULL
);

-- Valid inserts
INSERT INTO customers_nn VALUES
(1,'anna@example.com',   '+7-777-111-22-33', DATE '2025-10-01'),
(2,'brian@example.com',  NULL,               DATE '2025-10-02');

-- Invalid inserts (commented)
-- INSERT INTO customers_nn VALUES (NULL,'x@y.com',NULL, DATE '2025-10-01'); -- FAIL: customer_id NOT NULL
-- INSERT INTO customers_nn VALUES (3,NULL,NULL, DATE '2025-10-01');         -- FAIL: email NOT NULL
-- INSERT INTO customers_nn VALUES (4,'c@y.com',NULL, NULL);                 -- FAIL: registration_date NOT NULL

-- Test
SELECT COUNT(*) AS ok_rows_2_1 FROM customers_nn; -- EXPECTED: 2


-- Task 2.2: Combining Constraints (inventory)
CREATE TABLE inventory (
  item_id      INTEGER  NOT NULL,
  item_name    TEXT     NOT NULL,
  quantity     INTEGER  NOT NULL CHECK (quantity >= 0),
  unit_price   NUMERIC  NOT NULL CHECK (unit_price > 0),
  last_updated TIMESTAMP NOT NULL
);

-- Valid inserts
INSERT INTO inventory VALUES
(10,'USB-C Cable', 200, 1500,  NOW()),
(11,'Mouse',        50, 4500,  NOW());

-- Invalid inserts (commented)
-- INSERT INTO inventory VALUES (12,'BadQty', -1, 100, NOW());   -- FAIL: quantity >= 0
-- INSERT INTO inventory VALUES (13,'BadPrice', 10, 0, NOW());   -- FAIL: unit_price > 0
-- INSERT INTO inventory VALUES (NULL,'NoID', 1, 100, NOW());    -- FAIL: item_id NOT NULL

-- Test
SELECT COUNT(*) AS ok_rows_2_2 FROM inventory; -- EXPECTED: 2


-- Task 2.3: Testing NOT NULL — (покрыто выше)
-- валидные вставки есть, NULL в NOT NULL закомментированы, NULL в nullable (phone) показан для customers_nn


-- =========================================
-- Part 3: UNIQUE Constraints
-- =========================================

-- Task 3.1: Single Column UNIQUE (users)
CREATE TABLE users (
  user_id     INTEGER,
  username    TEXT UNIQUE,
  email       TEXT UNIQUE,
  created_at  TIMESTAMP
);

-- Valid inserts
INSERT INTO users VALUES
(1,'ann','ann@example.com', NOW()),
(2,'brian','brian@example.com', NOW());

-- Invalid inserts (commented)
-- INSERT INTO users VALUES (3,'ann','new@example.com', NOW());        -- FAIL: username unique
-- INSERT INTO users VALUES (4,'john','ann@example.com', NOW());       -- FAIL: email unique

-- Test
SELECT COUNT(*) AS ok_rows_3_1 FROM users; -- EXPECTED: 2


-- Task 3.2: Multi-Column UNIQUE (course_enrollments)
CREATE TABLE course_enrollments (
  enrollment_id INTEGER,
  student_id    INTEGER,
  course_code   TEXT,
  semester      TEXT,
  UNIQUE (student_id, course_code, semester)
);

-- Valid inserts (2 разных комбинации)
INSERT INTO course_enrollments VALUES
(1, 101, 'CS101', 'Fall-2025'),
(2, 101, 'CS102', 'Fall-2025');

-- Invalid insert (commented) — дубликат той же комбинации
-- INSERT INTO course_enrollments VALUES (3, 101, 'CS101', 'Fall-2025'); -- FAIL: unique (student_id, course_code, semester)

-- Test
SELECT COUNT(*) AS ok_rows_3_2 FROM course_enrollments; -- EXPECTED: 2


-- Task 3.3: Named UNIQUE Constraints (modify users: already unique; show named + test)
-- Пересоздадим таблицу users с ИМЕНОВАННЫМИ ограничениями
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
  user_id     INTEGER,
  username    TEXT,
  email       TEXT,
  created_at  TIMESTAMP,
  CONSTRAINT unique_username UNIQUE (username),
  CONSTRAINT unique_email    UNIQUE (email)
);

-- Valid inserts
INSERT INTO users VALUES
(1,'kate','kate@example.com', NOW()),
(2,'mike','mike@example.com', NOW());

-- Invalid inserts (commented) — проверка именованных UNIQUE
-- INSERT INTO users VALUES (3,'kate','kate2@example.com', NOW()); -- FAIL: unique_username
-- INSERT INTO users VALUES (4,'max','mike@example.com', NOW());   -- FAIL: unique_email

-- Test
SELECT COUNT(*) AS ok_rows_3_3 FROM users; -- EXPECTED: 2


-- =========================================
-- Part 4: PRIMARY KEY Constraints
-- =========================================

-- Task 4.1: Single Column Primary Key (departments)
CREATE TABLE departments (
  dept_id    INTEGER PRIMARY KEY,
  dept_name  TEXT NOT NULL,
  location   TEXT
);

-- Valid inserts (≥3)
INSERT INTO departments VALUES
(10,'IT','Almaty'),
(20,'HR','Astana'),
(30,'Sales','Shymkent');

-- Invalid inserts (commented)
-- INSERT INTO departments VALUES (10,'Duplicate','City'); -- FAIL: duplicate PK
-- INSERT INTO departments VALUES (NULL,'NullPK','City');  -- FAIL: PK cannot be NULL

-- Test
SELECT COUNT(*) AS ok_rows_4_1 FROM departments; -- EXPECTED: 3


-- Task 4.2: Composite Primary Key (student_courses)
CREATE TABLE student_courses (
  student_id      INTEGER,
  course_id       INTEGER,
  enrollment_date DATE,
  grade           TEXT,
  PRIMARY KEY (student_id, course_id)
);

-- Valid inserts
INSERT INTO student_courses VALUES
(5001, 1, DATE '2025-09-01', 'A'),
(5001, 2, DATE '2025-09-01', 'B');

-- Invalid insert (commented) — дубликат составного PK
-- INSERT INTO student_courses VALUES (5001, 1, DATE '2025-09-02', 'A-'); -- FAIL: duplicate PK (student_id,course_id)

-- Test
SELECT COUNT(*) AS ok_rows_4_2 FROM student_courses; -- EXPECTED: 2


-- Task 4.3: Comparison Exercise
-- UNIQUE vs PRIMARY KEY:
-- 1) PK = уникальный идентификатор строки, всегда NOT NULL, только один PK на таблицу.
-- 2) UNIQUE гарантирует уникальность, но допускает NULL (зависит от СУБД) и таких ограничений может быть много.
-- Single vs Composite PK: одиночный — когда одна колонка достаточно идентифицирует запись; составной — когда нужен набор колонок.
-- Почему только один PK: потому что у таблицы может быть только один «главный» ключ, но уникальных ограничений может быть несколько.


-- =========================================
-- Part 5: FOREIGN KEY Constraints
-- =========================================

-- Task 5.1: Basic Foreign Key (employees_dept → departments)
CREATE TABLE employees_dept (
  emp_id    INTEGER PRIMARY KEY,
  emp_name  TEXT NOT NULL,
  dept_id   INTEGER REFERENCES departments(dept_id),
  hire_date DATE
);

-- Valid inserts
INSERT INTO employees_dept VALUES
(1,'Alice',10, DATE '2024-01-10'),
(2,'Bob',  20, DATE '2024-02-20');

-- Invalid (commented) — dept_id не существует
-- INSERT INTO employees_dept VALUES (3,'Charlie',999, DATE '2024-03-30'); -- FAIL: FK departments

-- Test join
SELECT e.emp_id, e.emp_name, d.dept_name
FROM employees_dept e
LEFT JOIN departments d ON d.dept_id = e.dept_id
ORDER BY e.emp_id;
-- EXPECT: Alice->IT, Bob->HR


-- Task 5.2: Multiple Foreign Keys — библиотека
CREATE TABLE library_authors (
  author_id   INTEGER PRIMARY KEY,
  author_name TEXT NOT NULL,
  country     TEXT
);
CREATE TABLE library_publishers (
  publisher_id   INTEGER PRIMARY KEY,
  publisher_name TEXT NOT NULL,
  city           TEXT
);
CREATE TABLE library_books (
  book_id     INTEGER PRIMARY KEY,
  title       TEXT NOT NULL,
  author_id   INTEGER REFERENCES library_authors(author_id),
  publisher_id INTEGER REFERENCES library_publishers(publisher_id),
  publication_year INTEGER,
  isbn        TEXT UNIQUE
);

-- Sample data (authors, publishers, books)
INSERT INTO library_authors VALUES
(1,'Erich Gamma','Switzerland'),
(2,'Robert Martin','USA');

INSERT INTO library_publishers VALUES
(1,'Addison-Wesley','Boston'),
(2,'Prentice Hall','New Jersey');

INSERT INTO library_books VALUES
(100,'Design Patterns', 1, 1, 1994, '978-0-201-63361-0'),
(101,'Clean Code',      2, 2, 2008, '978-0-13-235088-4');

-- Invalid (commented)
-- INSERT INTO library_books VALUES (102,'No Author', 999, 1, 2020, '123'); -- FAIL: FK author
-- INSERT INTO library_books VALUES (103,'Dup ISBN',  1,   1, 2020, '978-0-13-235088-4'); -- FAIL: UNIQUE isbn

-- Test
SELECT b.title, a.author_name, p.publisher_name, b.isbn
FROM library_books b
JOIN library_authors a   ON a.author_id = b.author_id
JOIN library_publishers p ON p.publisher_id = b.publisher_id
ORDER BY b.book_id;


-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
  category_id   INTEGER PRIMARY KEY,
  category_name TEXT NOT NULL
);
CREATE TABLE products_fk (
  product_id   INTEGER PRIMARY KEY,
  product_name TEXT NOT NULL,
  category_id  INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);
CREATE TABLE orders_fk (
  order_id   INTEGER PRIMARY KEY,
  order_date DATE NOT NULL
);
CREATE TABLE order_items_fk (
  item_id    INTEGER PRIMARY KEY,
  order_id   INTEGER REFERENCES orders_fk(order_id) ON DELETE CASCADE,
  product_id INTEGER REFERENCES products_fk(product_id),
  quantity   INTEGER CHECK (quantity > 0)
);

-- Sample data
INSERT INTO categories VALUES (1,'Electronics'),(2,'Books');
INSERT INTO products_fk VALUES (10,'USB-C Cable',1),(11,'Novel',2);
INSERT INTO orders_fk VALUES (1001, DATE '2025-10-01');
INSERT INTO order_items_fk VALUES (1,1001,10,2),(2,1001,11,1);

-- Tests:
-- (1) Try delete category with products (RESTRICT)
-- DELETE FROM categories WHERE category_id = 1; -- EXPECT: FAIL (RESTRICT) — есть products_fk с category_id=1

-- (2) Delete an order and observe CASCADE on order_items
-- DELETE FROM orders_fk WHERE order_id = 1001;
-- SELECT COUNT(*) AS items_after_cascade FROM order_items_fk WHERE order_id = 1001;
-- EXPECT after delete: 0

-- (3) Комментарии выше фиксируют поведение


-- =========================================
-- Part 6: Practical Application — E-commerce
-- =========================================

-- 6.1 Design & Implement

-- Clean old if re-run (already dropped at top). Create tables:
CREATE TABLE customers_ecom (
  customer_id       INTEGER PRIMARY KEY,
  name              TEXT    NOT NULL,
  email             TEXT    NOT NULL UNIQUE,
  phone             TEXT,
  registration_date DATE    NOT NULL
);

CREATE TABLE products_ecom (
  product_id      INTEGER PRIMARY KEY,
  name            TEXT    NOT NULL,
  description     TEXT,
  price           NUMERIC NOT NULL CHECK (price >= 0),
  stock_quantity  INTEGER NOT NULL CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
  order_id     INTEGER PRIMARY KEY,
  customer_id  INTEGER NOT NULL REFERENCES customers_ecom(customer_id) ON DELETE RESTRICT,
  order_date   DATE    NOT NULL,
  total_amount NUMERIC NOT NULL CHECK (total_amount >= 0),
  status       TEXT    NOT NULL CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details_ecom (
  order_detail_id INTEGER PRIMARY KEY,
  order_id        INTEGER NOT NULL REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
  product_id      INTEGER NOT NULL REFERENCES products_ecom(product_id),
  quantity        INTEGER NOT NULL CHECK (quantity > 0),
  unit_price      NUMERIC NOT NULL CHECK (unit_price >= 0)
);

-- Sample data (≥5 per table)

-- customers_ecom (5)
INSERT INTO customers_ecom VALUES
(1,'Anna Adams','anna@shop.com','+7-777-111-22-33', DATE '2025-09-20'),
(2,'Brian Brooks','brian@shop.com',NULL,            DATE '2025-09-21'),
(3,'Celia Cruz','celia@shop.com','+7-705-000-00-00',DATE '2025-09-22'),
(4,'David Diaz','david@shop.com',NULL,              DATE '2025-09-23'),
(5,'Emma Evans','emma@shop.com','+7-700-123-45-67', DATE '2025-09-24');

-- products_ecom (5)
INSERT INTO products_ecom VALUES
(10,'USB-C Cable','1m cable',      1500, 200),
(11,'Wireless Mouse','Optical',    4500,  50),
(12,'Keyboard','Mechanical',      20000,  15),
(13,'Laptop Stand','Aluminum',     9000,  30),
(14,'Webcam','1080p',              8000,  25);

-- orders_ecom (5)
INSERT INTO orders_ecom VALUES
(1001,1, DATE '2025-10-01', 0,'pending'),
(1002,2, DATE '2025-10-02', 0,'processing'),
(1003,3, DATE '2025-10-03', 0,'pending'),
(1004,4, DATE '2025-10-04', 0,'shipped'),
(1005,5, DATE '2025-10-05', 0,'delivered');

-- order_details_ecom (≥5; заодно посчитаем total_amount через UPDATE)
INSERT INTO order_details_ecom VALUES
(1,1001,10,2,1500),  -- 2 x cable = 3000
(2,1001,11,1,4500),  -- + mouse = 4500  -> order 1001 total=7500
(3,1002,12,1,20000), -- order 1002 total=20000
(4,1003,13,2,9000),  -- order 1003 total=18000
(5,1004,14,1,8000),  -- order 1004 total=8000
(6,1005,12,1,20000); -- order 1005 total=20000

-- Recalculate totals from details (демонстрация согласованности)
UPDATE orders_ecom o
SET total_amount = d.sum_amount
FROM (
  SELECT order_id, SUM(quantity * unit_price) AS sum_amount
  FROM order_details_ecom
  GROUP BY order_id
) d
WHERE d.order_id = o.order_id;

-- Tests (constraints working)
-- UNIQUE email:
-- INSERT INTO customers_ecom VALUES (6,'Dup','anna@shop.com',NULL, CURRENT_DATE); -- FAIL: unique email

-- price/stock non-negative:
-- INSERT INTO products_ecom VALUES (15,'Bad','x', -1, 10);  -- FAIL: price >= 0
-- INSERT INTO products_ecom VALUES (16,'Bad2','x', 10, -5); -- FAIL: stock >= 0

-- order status list:
-- INSERT INTO orders_ecom VALUES (1006,1, CURRENT_DATE, 0,'unknown'); -- FAIL: status IN (...)

-- quantity positive:
-- INSERT INTO order_details_ecom VALUES (7,1001,10,0,1500); -- FAIL: quantity > 0

-- FK RESTRICT: нельзя удалить customer, если есть orders
-- DELETE FROM customers_ecom WHERE customer_id = 1; -- EXPECT: FAIL

-- FK CASCADE: удалить заказ — удалятся его детали
-- DELETE FROM orders_ecom WHERE order_id = 1001;
-- SELECT COUNT(*) AS details_after_cascade FROM order_details_ecom WHERE order_id = 1001;
-- EXPECT: 0

-- Show final orders
SELECT order_id, customer_id, total_amount, status FROM orders_ecom ORDER BY order_id;
