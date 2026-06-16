-- ============================================================
-- ULK Academic Activity and Resource Management System
-- Phase 4: PostgreSQL Implementation
-- Course: Advanced Database Management
-- Lecturer: KAMATE KATENDE TIMOTHEE
-- ============================================================

-- ============================================================
-- SECTION 1: USER DEFINED TYPES & COMPOSITE TYPES
-- ============================================================

CREATE TYPE address_type AS (
    street      VARCHAR(100),
    city        VARCHAR(50),
    district    VARCHAR(50)
);

CREATE TYPE contact_info AS (
    email           VARCHAR(100),
    emergency_phone VARCHAR(20)
);

-- ============================================================
-- SECTION 2: BASE / PARENT TABLES
-- ============================================================

-- Person (superclass for Student and Lecturer)
CREATE TABLE Person (
    person_id    SERIAL PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    gender       VARCHAR(10),
    dob          DATE,
    address      address_type,
    contacts     contact_info,
    phone_numbers TEXT[]          -- Array attribute
);

-- Faculty
CREATE TABLE Faculty (
    faculty_id   SERIAL PRIMARY KEY,
    faculty_name VARCHAR(100) NOT NULL
);

-- Department
CREATE TABLE Department (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    faculty_id      INTEGER REFERENCES Faculty(faculty_id)
);

-- ============================================================
-- SECTION 3: SPECIALISED TABLES (INHERITANCE)
-- ============================================================

-- Student inherits from Person
CREATE TABLE Student (
    registration_number VARCHAR(20) UNIQUE,
    year_of_study       INTEGER CHECK (year_of_study BETWEEN 1 AND 7),
    department_id       INTEGER REFERENCES Department(department_id)
) INHERITS (Person);

-- Lecturer inherits from Person
CREATE TABLE Lecturer (
    staff_number  VARCHAR(20) UNIQUE,
    qualification VARCHAR(100),
    rank          VARCHAR(50),
    department_id INTEGER REFERENCES Department(department_id)
) INHERITS (Person);

-- ============================================================
-- SECTION 4: ACADEMIC SPACE (GENERALISATION)
-- ============================================================

-- AcademicSpace (parent of Classroom and Laboratory)
CREATE TABLE AcademicSpace (
    space_id  SERIAL PRIMARY KEY,
    building  VARCHAR(50),
    capacity  INTEGER
);

-- Classroom inherits from AcademicSpace
CREATE TABLE Classroom (
    room_number VARCHAR(20)
) INHERITS (AcademicSpace);

-- Laboratory inherits from AcademicSpace
CREATE TABLE Laboratory (
    lab_name   VARCHAR(100),
    equipment  JSONB           -- JSONB attribute for flexible equipment list
) INHERITS (AcademicSpace);

-- ============================================================
-- SECTION 5: CORE ACADEMIC TABLES
-- ============================================================

-- Course
CREATE TABLE Course (
    course_id    SERIAL PRIMARY KEY,
    course_code  VARCHAR(20)  UNIQUE NOT NULL,
    course_name  VARCHAR(100) NOT NULL,
    credits      INTEGER      CHECK (credits > 0),
    department_id INTEGER     REFERENCES Department(department_id)
);

-- Enrollment (Student M:N Course)
CREATE TABLE Enrollment (
    enrollment_id   SERIAL PRIMARY KEY,
    student_id      INTEGER NOT NULL,
    course_id       INTEGER NOT NULL REFERENCES Course(course_id),
    enrollment_date DATE    DEFAULT CURRENT_DATE,
    UNIQUE (student_id, course_id)
);

-- LecturerCourse (Lecturer M:N Course)
CREATE TABLE LecturerCourse (
    lc_id       SERIAL PRIMARY KEY,
    lecturer_id INTEGER NOT NULL,
    course_id   INTEGER NOT NULL REFERENCES Course(course_id),
    UNIQUE (lecturer_id, course_id)
);

-- Schedule (Course scheduled in Classroom)
CREATE TABLE Schedule (
    schedule_id  SERIAL PRIMARY KEY,
    course_id    INTEGER REFERENCES Course(course_id),
    space_id     INTEGER,           -- references Classroom or Laboratory
    day_of_week  VARCHAR(10),
    start_time   TIME,
    end_time     TIME,
    semester     VARCHAR(20)
);

-- Attendance
CREATE TABLE Attendance (
    attendance_id   SERIAL PRIMARY KEY,
    student_id      INTEGER NOT NULL,
    schedule_id     INTEGER REFERENCES Schedule(schedule_id),
    attend_date     DATE    DEFAULT CURRENT_DATE,
    status          VARCHAR(10) CHECK (status IN ('Present','Absent','Late'))
);

-- ============================================================
-- SECTION 6: RESEARCH TABLES
-- ============================================================

-- ResearchProject
CREATE TABLE ResearchProject (
    project_id   SERIAL PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    start_date   DATE,
    end_date     DATE,
    status       VARCHAR(30)  DEFAULT 'Active',
    metadata     JSONB        -- JSONB for flexible research metadata
);

-- Supervision (Aggregation: Lecturer supervises StudentResearchProject)
CREATE TABLE Supervision (
    supervision_id  SERIAL PRIMARY KEY,
    lecturer_id     INTEGER NOT NULL,
    project_id      INTEGER NOT NULL REFERENCES ResearchProject(project_id),
    student_id      INTEGER NOT NULL,
    start_date      DATE    DEFAULT CURRENT_DATE,
    notes           TEXT,
    UNIQUE (lecturer_id, project_id, student_id)
);

-- ============================================================
-- SECTION 7: EVENTS & RESOURCES
-- ============================================================

-- AcademicEvent
CREATE TABLE AcademicEvent (
    event_id     SERIAL PRIMARY KEY,
    event_name   VARCHAR(150) NOT NULL,
    event_date   DATE,
    location     VARCHAR(100),
    organizer_id INTEGER      -- references Lecturer
);

-- EventParticipation (Category / Union type: Student ∪ Lecturer)
CREATE TABLE EventParticipation (
    participation_id SERIAL PRIMARY KEY,
    event_id         INTEGER NOT NULL REFERENCES AcademicEvent(event_id),
    participant_id   INTEGER NOT NULL,
    participant_type VARCHAR(10) NOT NULL CHECK (participant_type IN ('Student','Lecturer')),
    UNIQUE (event_id, participant_id, participant_type)
);

-- Resource
CREATE TABLE Resource (
    resource_id   SERIAL PRIMARY KEY,
    resource_name VARCHAR(100) NOT NULL,
    quantity      INTEGER      CHECK (quantity >= 0),
    department_id INTEGER      REFERENCES Department(department_id)
);

-- ============================================================
-- SECTION 8: INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX idx_student_dept      ON Student(department_id);
CREATE INDEX idx_lecturer_dept     ON Lecturer(department_id);
CREATE INDEX idx_course_dept       ON Course(department_id);
CREATE INDEX idx_enrollment_student ON Enrollment(student_id);
CREATE INDEX idx_enrollment_course  ON Enrollment(course_id);
CREATE INDEX idx_attendance_student ON Attendance(student_id);
CREATE INDEX idx_supervision_proj   ON Supervision(project_id);
CREATE INDEX idx_eventpart_event    ON EventParticipation(event_id);
