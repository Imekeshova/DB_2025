-- ================================
-- Part 1: Multiple Database Management


-- ================================
-- Task 1.1: Database Creation with Parameters
-- ================================

-- Создание базы university_main
DROP DATABASE IF EXISTS university_main;
CREATE DATABASE university_main
  TEMPLATE = template0
  ENCODING = 'UTF8';
ALTER DATABASE university_main OWNER TO CURRENT_USER;

-- Создание базы university_archive
DROP DATABASE IF EXISTS university_archive;
CREATE DATABASE university_archive
  TEMPLATE = template0
  CONNECTION LIMIT = 50;

-- Для шаблонной базы university_test сначала снимаем статус шаблона
UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'university_test';
DROP DATABASE IF EXISTS university_test;
CREATE DATABASE university_test
  IS_TEMPLATE = TRUE
  CONNECTION LIMIT = 10;

-- ================================
-- Task 1.2: Database Backup Creation
-- ================================

-- Сначала удаляем, если база university_backup уже существует
DROP DATABASE IF EXISTS university_backup;

-- Создаем новую базу на основе university_main
CREATE DATABASE university_backup
    TEMPLATE university_main
    ENCODING 'UTF8'
    CONNECTION LIMIT 50;


-- ================================
-- Part 2: Core Tables
-- ================================

-- Удаляем таблицы с CASCADE, чтобы удалить зависимости
DROP TABLE IF EXISTS student_records CASCADE;
DROP TABLE IF EXISTS class_schedule CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS professors CASCADE;

-- Students
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    middle_name VARCHAR(30),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(4,2) DEFAULT 0.00,
    is_active BOOLEAN,
    graduation_year SMALLINT,
    student_status VARCHAR(20) DEFAULT 'ACTIVE',
    advisor_id INTEGER   -- связь с professors (FK добавим ниже)
);

-- Professors
CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(14,2),
    is_tenured BOOLEAN DEFAULT FALSE,
    years_experience SMALLINT,
    department_code CHAR(5),
    research_area TEXT,
    last_promotion_date DATE,
    department_id INTEGER -- связь с departments
);

-- Courses
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code VARCHAR(10),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT DEFAULT 3,
    max_enrollment INTEGER,
    course_fee NUMERIC(10,2),
    is_online BOOLEAN,
    created_at TIMESTAMP WITHOUT TIME ZONE,
    prerequisite_course_id INTEGER,
    difficulty_level SMALLINT,
    lab_required BOOLEAN DEFAULT FALSE,
    department_id INTEGER -- связь с departments
);

-- Class Schedule
CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    classroom VARCHAR(30),
    room_capacity INTEGER,
    session_type VARCHAR(15),
    equipment_needed TEXT
);

-- Student Records
CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    grade CHAR(2),
    last_updated TIMESTAMP
);

-- ================================
-- Part 4: Supporting Tables and Lookups
-- ================================

-- Departments
DROP TABLE IF EXISTS departments CASCADE;
CREATE TABLE departments (
  department_id serial PRIMARY KEY,
  department_name varchar(100),
  department_code char(5),
  building varchar(50),
  phone varchar(15),
  budget numeric(12,2),
  established_year integer
);

-- Library Books
DROP TABLE IF EXISTS library_books CASCADE;
CREATE TABLE library_books (
  book_id serial PRIMARY KEY,
  isbn char(13),
  title varchar(200),
  author varchar(100),
  publisher varchar(100),
  publication_date date,
  price numeric(8,2),
  is_available boolean,
  acquisition_timestamp timestamp
);

-- Student Book Loans
DROP TABLE IF EXISTS student_book_loans CASCADE;
CREATE TABLE student_book_loans (
  loan_id serial PRIMARY KEY,
  student_id integer,
  book_id integer,
  loan_date date,
  due_date date,
  return_date date,
  fine_amount numeric(8,2),
  loan_status varchar(20)
);

-- Grade Scale
DROP TABLE IF EXISTS grade_scale CASCADE;
CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2) NOT NULL,
    min_percentage DECIMAL(4,1) CHECK (min_percentage >= 0),
    max_percentage DECIMAL(4,1) CHECK (max_percentage <= 100),
    gpa_points DECIMAL(3,2) CHECK (gpa_points >= 0),
    description TEXT
);

-- Semester Calendar
DROP TABLE IF EXISTS semester_calendar CASCADE;
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20) NOT NULL,
    academic_year INT CHECK (academic_year >= 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN DEFAULT FALSE
);

-- ================================
-- Part 5: Table Deletion and Cleanup
-- ================================

-- Drop databases safely
UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'university_test';
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

-- Create new database using university_main as template
DROP DATABASE IF EXISTS university_backup;
CREATE DATABASE university_backup
    TEMPLATE university_main
    ENCODING 'UTF8'
    CONNECTION LIMIT 50;
