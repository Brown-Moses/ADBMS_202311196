-- ============================================================
-- ULK Academic Activity and Resource Management System
-- Phase 8: Indexing Experiment
-- Course: Advanced Database Management
-- Lecturer: KAMATE KATENDE TIMOTHEE
-- ============================================================
-- Run each step in order and record the execution times.
-- ============================================================

-- ============================================================
-- EXPERIMENT 1: Enrollment table — student_id lookup
-- ============================================================

-- Step 1: Check existing indexes on Enrollment
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'enrollment';

-- Step 2: Drop experiment index if it exists from a previous run
DROP INDEX IF EXISTS idx_exp_enrollment_student;

-- Step 3: Run query WITHOUT index (baseline)
-- Record the "Execution Time" from the output
EXPLAIN ANALYZE
SELECT *
FROM Enrollment
WHERE student_id = 50;

/*
Expected output WITHOUT index:
Seq Scan on enrollment
  Filter: (student_id = 50)
  Rows Removed by Filter: ~396
Planning Time:  ~0.1 ms
Execution Time: ~0.1 ms
*/

-- Step 4: Create the index
CREATE INDEX idx_exp_enrollment_student ON Enrollment(student_id);

-- Step 5: Run query AFTER index creation
-- Record the "Execution Time" and compare
EXPLAIN ANALYZE
SELECT *
FROM Enrollment
WHERE student_id = 50;

/*
Expected output WITH index:
Index Scan using idx_exp_enrollment_student on enrollment
  Index Cond: (student_id = 50)
Planning Time:  ~0.2 ms
Execution Time: ~0.05 ms

Result: Index scan is faster — O(log n) vs O(n) sequential scan.
At 400 rows the gain is modest. At 100,000+ rows the difference
grows dramatically (80+ ms vs 0.2 ms).
*/

-- ============================================================
-- EXPERIMENT 2: Attendance table — student_id lookup
-- ============================================================

-- Step 1: Run WITHOUT index
DROP INDEX IF EXISTS idx_exp_attendance_student;

EXPLAIN ANALYZE
SELECT *
FROM Attendance
WHERE student_id = 25;

/*
Expected output WITHOUT index:
Seq Scan on attendance
  Filter: (student_id = 25)
Execution Time: ~0.08 ms
*/

-- Step 2: Create index
CREATE INDEX idx_exp_attendance_student ON Attendance(student_id);

-- Step 3: Run AFTER index
EXPLAIN ANALYZE
SELECT *
FROM Attendance
WHERE student_id = 25;

/*
Expected output WITH index:
Index Scan using idx_exp_attendance_student on attendance
  Index Cond: (student_id = 25)
Execution Time: ~0.04 ms
*/

-- ============================================================
-- EXPERIMENT 3: Student table — department_id lookup
-- ============================================================

DROP INDEX IF EXISTS idx_exp_student_dept;

-- Without index
EXPLAIN ANALYZE
SELECT *
FROM Student
WHERE department_id = 3;

-- Create index
CREATE INDEX idx_exp_student_dept ON Student(department_id);

-- With index
EXPLAIN ANALYZE
SELECT *
FROM Student
WHERE department_id = 3;

-- ============================================================
-- Summary: View all indexes on key tables
-- ============================================================
SELECT
    t.relname  AS table_name,
    i.relname  AS index_name,
    ix.indisunique AS is_unique,
    array_to_string(array_agg(a.attname ORDER BY k.n), ', ') AS columns
FROM pg_class t
JOIN pg_index ix  ON t.oid       = ix.indrelid
JOIN pg_class i   ON i.oid       = ix.indexrelid
JOIN pg_attribute a ON a.attrelid = t.oid
JOIN unnest(ix.indkey) WITH ORDINALITY AS k(attnum, n)
     ON a.attnum = k.attnum
WHERE t.relname IN ('student','lecturer','course','enrollment',
                    'attendance','supervision','eventparticipation')
GROUP BY t.relname, i.relname, ix.indisunique
ORDER BY t.relname, i.relname;