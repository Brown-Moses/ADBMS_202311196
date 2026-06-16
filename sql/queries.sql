-- ============================================================
-- ULK Academic Activity and Resource Management System
-- Phase 6: SQL Queries (15 Queries)
-- Course: Advanced Database Management
-- Lecturer: KAMATE KATENDE TIMOTHEE
-- ============================================================

-- ============================================================
-- Query 1: Students in Computer Science Department
-- Operation: Selection + Projection + Join
-- ============================================================
SELECT
    s.registration_number,
    s.first_name,
    s.last_name,
    s.year_of_study
FROM Student s
JOIN Department d ON s.department_id = d.department_id
WHERE d.department_name = 'Computer Science'
ORDER BY s.last_name, s.first_name;

/*
Sample Output:
registration_number | first_name | last_name    | year_of_study
--------------------------------------------------------------------
STU202300010        | Alice      | Uwimana      | 2
STU202300020        | Alice      | Uwimana      | 2
STU202300030        | Alice      | Uwimana      | 3
...
(10 rows)
*/

-- ============================================================
-- Query 2: Courses Offered Per Department with Faculty
-- Operation: Multi-table Join + Projection
-- ============================================================
SELECT
    f.faculty_name,
    d.department_name,
    c.course_code,
    c.course_name,
    c.credits
FROM Course c
JOIN Department d ON c.department_id = d.department_id
JOIN Faculty    f ON d.faculty_id    = f.faculty_id
ORDER BY f.faculty_name, d.department_name;

/*
Sample Output:
faculty_name                    | department_name      | course_code | course_name                    | credits
--------------------------------------------------------------------------------------------------------------
Faculty of Business Admin...    | Accounting and Fin.. | AC101       | Financial Accounting           | 3
Faculty of Business Admin...    | Accounting and Fin.. | AC201       | Management Accounting          | 3
Faculty of Business Admin...    | Business Management  | BM101       | Principles of Management       | 3
...
(30 rows)
*/

-- ============================================================
-- Query 3: Number of Students Enrolled Per Course
-- Operation: Aggregation + Left Join + Group By
-- ============================================================
SELECT
    c.course_code,
    c.course_name,
    COUNT(e.student_id) AS enrollment_count
FROM Course c
LEFT JOIN Enrollment e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_code, c.course_name
ORDER BY enrollment_count DESC;

/*
Sample Output:
course_code | course_name                        | enrollment_count
--------------------------------------------------------------------
CS101       | Introduction to Programming        | 25
BM101       | Principles of Management           | 22
AC101       | Financial Accounting               | 20
...
(30 rows)
*/

-- ============================================================
-- Query 4: Most Enrolled Course
-- Operation: Aggregation + Ordering + Limit
-- ============================================================
SELECT
    c.course_code,
    c.course_name,
    COUNT(e.student_id) AS total_enrolled
FROM Enrollment e
JOIN Course c ON e.course_id = c.course_id
GROUP BY c.course_id, c.course_code, c.course_name
ORDER BY total_enrolled DESC
LIMIT 1;

/*
Sample Output:
course_code | course_name                   | total_enrolled
-------------------------------------------------------------
CS101       | Introduction to Programming   | 25
(1 row)
*/

-- ============================================================
-- Query 5: Average Enrollment Per Course
-- Operation: Nested Subquery + Aggregation
-- ============================================================
SELECT ROUND(AVG(cnt), 2) AS avg_enrollments_per_course
FROM (
    SELECT course_id, COUNT(*) AS cnt
    FROM Enrollment
    GROUP BY course_id
) sub;

/*
Sample Output:
avg_enrollments_per_course
---------------------------
13.33
(1 row)
*/

-- ============================================================
-- Query 6: Students Not Enrolled in Any Course
-- Operation: Subquery + NOT IN
-- ============================================================
SELECT
    s.registration_number,
    s.first_name,
    s.last_name,
    d.department_name
FROM Student s
JOIN Department d ON s.department_id = d.department_id
WHERE s.person_id NOT IN (
    SELECT DISTINCT student_id FROM Enrollment
);

/*
Sample Output:
registration_number | first_name | last_name | department_name
---------------------------------------------------------------
(0 rows - all students are enrolled)
*/

-- ============================================================
-- Query 7: Lecturers and All Courses They Teach
-- Operation: Multi-table Join
-- ============================================================
SELECT
    l.staff_number,
    l.first_name || ' ' || l.last_name AS lecturer_name,
    l.rank,
    c.course_code,
    c.course_name
FROM Lecturer l
JOIN LecturerCourse lc ON l.person_id  = lc.lecturer_id
JOIN Course c           ON lc.course_id = c.course_id
ORDER BY lecturer_name, c.course_code;

/*
Sample Output:
staff_number | lecturer_name          | rank            | course_code | course_name
-------------------------------------------------------------------------------------
LEC009       | Celestin Rurangwa      | Senior Lecturer | EE101       | Circuit Theory
LEC009       | Celestin Rurangwa      | Senior Lecturer | EE201       | Digital Electronics
LEC006       | Chantal Ingabire       | Asst Lecturer   | CS301       | Database Mgmt Systems
...
(40 rows)
*/

-- ============================================================
-- Query 8: Attendance Summary Per Student
-- Operation: Aggregation + CASE Expression
-- ============================================================
SELECT
    s.registration_number,
    s.first_name || ' ' || s.last_name AS student_name,
    COUNT(*)                            AS total_sessions,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS present,
    SUM(CASE WHEN a.status = 'Absent'  THEN 1 ELSE 0 END) AS absent,
    ROUND(
        SUM(CASE WHEN a.status = 'Present' THEN 1.0 ELSE 0 END)
        / COUNT(*) * 100, 2
    ) AS attendance_percentage
FROM Attendance a
JOIN Student s ON a.student_id = s.person_id
GROUP BY s.person_id, s.registration_number, s.first_name, s.last_name
ORDER BY attendance_percentage DESC;

/*
Sample Output:
registration_number | student_name       | total_sessions | present | absent | attendance_pct
----------------------------------------------------------------------------------------------
STU202300001        | Alice Uwimana      | 6              | 6       | 0      | 100.00
STU202300003        | Claudine Habimana  | 6              | 6       | 0      | 100.00
STU202300005        | Emma Kamanzi       | 6              | 6       | 0      | 100.00
...
*/

-- ============================================================
-- Query 9: Research Projects and Their Supervisors
-- Operation: 3-way Join
-- ============================================================
SELECT
    rp.project_id,
    rp.title,
    l.staff_number,
    l.first_name || ' ' || l.last_name AS supervisor,
    sup.start_date                      AS supervision_date
FROM Supervision sup
JOIN ResearchProject rp ON sup.project_id  = rp.project_id
JOIN Lecturer        l  ON sup.lecturer_id = l.person_id
ORDER BY rp.title;

/*
Sample Output:
project_id | title                                    | staff_number | supervisor            | supervision_date
---------------------------------------------------------------------------------------------------------------
1          | AI-Powered Student Performance Pred...   | LEC001       | Jean Bosco Niyonzima  | 2024-01-15
1          | AI-Powered Student Performance Pred...   | LEC006       | Chantal Ingabire      | 2024-01-18
2          | Blockchain for Academic Record Mgmt      | LEC013       | Faustin Habimana      | 2024-02-05
...
*/

-- ============================================================
-- Query 10: Departments With More Than 5 Enrolled Students
-- Operation: Join + Group By + HAVING
-- ============================================================
SELECT
    d.department_name,
    COUNT(DISTINCT e.student_id) AS enrolled_students
FROM Department d
JOIN Student    s ON s.department_id = d.department_id
JOIN Enrollment e ON e.student_id   = s.person_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(DISTINCT e.student_id) > 5
ORDER BY enrolled_students DESC;

/*
Sample Output:
department_name         | enrolled_students
--------------------------------------------
Computer Science        | 40
Business Management     | 38
Information Systems     | 35
...
(10 rows - all departments qualify)
*/

-- ============================================================
-- Query 11: Classroom Schedule Report
-- Operation: Join (Schedule + Course + Classroom)
-- ============================================================
SELECT
    sch.day_of_week,
    sch.start_time,
    sch.end_time,
    c.course_code,
    c.course_name,
    cl.room_number,
    cl.building,
    sch.semester
FROM Schedule sch
JOIN Course    c  ON sch.course_id = c.course_id
JOIN Classroom cl ON sch.space_id  = cl.space_id
ORDER BY sch.day_of_week, sch.start_time;

/*
Sample Output:
day_of_week | start_time | end_time | course_code | course_name             | room_number | building | semester
------------------------------------------------------------------------------------------------------------------
Friday      | 08:00      | 10:00    | SE101       | Software Eng Principles | B202        | Block B  | Semester 1 2024
Friday      | 10:00      | 12:00    | CE101       | Engineering Mathematics  | D401        | Block D  | Semester 1 2024
Monday      | 08:00      | 10:00    | CS101       | Intro to Programming     | A101        | Block A  | Semester 1 2024
...
*/

-- ============================================================
-- Query 12: Event Participation Report
-- Operation: Category Union Type (CASE + Correlated Subqueries)
-- ============================================================
SELECT
    ae.event_name,
    ae.event_date,
    ep.participant_type,
    CASE
        WHEN ep.participant_type = 'Student'
        THEN (SELECT s.first_name || ' ' || s.last_name
              FROM Student s WHERE s.person_id = ep.participant_id)
        WHEN ep.participant_type = 'Lecturer'
        THEN (SELECT l.first_name || ' ' || l.last_name
              FROM Lecturer l WHERE l.person_id = ep.participant_id)
    END AS participant_name
FROM EventParticipation ep
JOIN AcademicEvent ae ON ep.event_id = ae.event_id
ORDER BY ae.event_name, ep.participant_type;

/*
Sample Output:
event_name                        | event_date | participant_type | participant_name
-------------------------------------------------------------------------------------
Career Fair and Industry Net...   | 2024-07-10 | Lecturer         | Aurore Mukarubibi
Career Fair and Industry Net...   | 2024-07-10 | Lecturer         | Claudine Uwimana
Career Fair and Industry Net...   | 2024-07-10 | Student          | Alice Uwimana
...
*/

-- ============================================================
-- Query 13: Resource Summary Per Department
-- Operation: Join + Aggregation (COUNT, SUM, AVG)
-- ============================================================
SELECT
    d.department_name,
    COUNT(r.resource_id)     AS resource_types,
    SUM(r.quantity)          AS total_quantity,
    ROUND(AVG(r.quantity),2) AS average_quantity
FROM Resource r
JOIN Department d ON r.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_quantity DESC;

/*
Sample Output:
department_name         | resource_types | total_quantity | average_quantity
-----------------------------------------------------------------------------
Primary Education       | 12             | 960            | 80.00
Computer Science        | 14             | 840            | 60.00
Business Management     | 10             | 750            | 75.00
...
*/

-- ============================================================
-- Query 14: Students Enrolled Outside Their Department
-- Operation: Multi-join + Inequality Filter
-- ============================================================
SELECT DISTINCT
    s.registration_number,
    s.first_name || ' ' || s.last_name AS student_name,
    d_student.department_name          AS student_department,
    c.course_name,
    d_course.department_name           AS course_department
FROM Enrollment e
JOIN Student    s          ON e.student_id    = s.person_id
JOIN Course     c          ON e.course_id     = c.course_id
JOIN Department d_student  ON s.department_id = d_student.department_id
JOIN Department d_course   ON c.department_id = d_course.department_id
WHERE s.department_id <> c.department_id
ORDER BY student_name;

/*
Sample Output:
registration_number | student_name     | student_department  | course_name              | course_department
------------------------------------------------------------------------------------------------------------
STU202300001        | Alice Uwimana    | Computer Science    | Financial Accounting      | Accounting and Finance
STU202300001        | Alice Uwimana    | Computer Science    | Principles of Management  | Business Management
...
*/

-- ============================================================
-- Query 15: Lecturer Profile Summary with Course Load
-- Operation: Complex Join + GROUP BY + LEFT JOIN
-- ============================================================
SELECT
    l.staff_number,
    l.first_name || ' ' || l.last_name AS lecturer_name,
    l.qualification,
    l.rank,
    d.department_name,
    COUNT(lc.course_id)                AS courses_taught
FROM Lecturer l
JOIN Department d ON l.department_id = d.department_id
LEFT JOIN LecturerCourse lc ON l.person_id = lc.lecturer_id
GROUP BY l.person_id, l.staff_number, l.first_name, l.last_name,
         l.qualification, l.rank, d.department_name
ORDER BY courses_taught DESC, lecturer_name;

/*
Actual Output from Database:
staff_number | lecturer_name          | qualification              | rank               | department_name        | courses_taught
--------------------------------------------------------------------------------------------------------------------------------
LEC001       | Jean Bosco Niyonzima   | PhD Computer Science       | Senior Lecturer    | Computer Science       | 3
LEC002       | Marie Claire Mukamana  | MSc Information Systems    | Lecturer           | Information Systems    | 3
LEC003       | Patrick Habimana       | PhD Software Engineering   | Professor          | Software Engineering   | 3
LEC004       | Claudine Uwimana       | MBA                        | Lecturer           | Business Management    | 3
LEC005       | Samuel Nkurunziza      | PhD Education              | Senior Lecturer    | Primary Education      | 3
LEC007       | Bruno Nshimiyimana     | PhD Civil Engineering      | Professor          | Civil Engineering      | 3
LEC010       | Yvette Nyirabashyitsi  | MSc Accounting             | Lecturer           | Accounting and Finance | 3
LEC011       | Theogene Munyanziza    | PhD Business               | Associate Professor| Business Management    | 2
LEC015       | Alexis Niyigena        | PhD Mathematics            | Professor          | Civil Engineering      | 2
LEC018       | Sandrine Uwamahoro     | MEd Primary Education      | Lecturer           | Primary Education      | 2
LEC008       | Valentina Mukamurenzi  | MSc Public Health          | Lecturer           | Public Health          | 2
LEC014       | Josephine Uwase        | MSc Software Engineering   | Assistant Lecturer | Software Engineering   | 2
LEC009       | Celestin Rurangwa      | PhD Electrical Engineering | Senior Lecturer    | Electrical Engineering | 2
LEC013       | Faustin Habimana       | PhD Information Security   | Senior Lecturer    | Information Systems    | 2
LEC016       | Solange Mukandutiye    | MSc Epidemiology           | Lecturer           | Public Health          | 2
LEC006       | Chantal Ingabire       | MSc Computer Science       | Assistant Lecturer | Computer Science       | 2
LEC017       | Ignace Bizimana        | PhD Computer Networks      | Professor          | Computer Science       | 2
LEC020       | Aurore Mukarubibi      | PhD Marketing              | Associate Professor| Business Management    | 2
LEC019       | Herve Ndayishimiye     | MSc Agile Methods          | Assistant Lecturer | Software Engineering   | 1
LEC012       | Esperance Kamanzi      | MEd Secondary Education    | Lecturer           | Secondary Education    | 1
(20 rows)
*/