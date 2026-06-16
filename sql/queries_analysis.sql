-- ============================================================
-- ULK Academic Activity and Resource Management System
-- Phase 7: Query Processing Analysis
-- Course: Advanced Database Management
-- Lecturer: KAMATE KATENDE TIMOTHEE
-- ============================================================
-- Instructions: Run each EXPLAIN ANALYZE block separately.
-- Copy the actual output into your report.
-- ============================================================

-- ============================================================
-- Analysis Query A: Complex Join
-- Query: Research Supervision (4-table join)
-- ============================================================
EXPLAIN ANALYZE
SELECT
    rp.title,
    l.first_name || ' ' || l.last_name AS supervisor,
    s.first_name || ' ' || s.last_name AS student
FROM Supervision sup
JOIN ResearchProject rp ON sup.project_id  = rp.project_id
JOIN Lecturer        l  ON sup.lecturer_id = l.person_id
JOIN Student         s  ON sup.student_id  = s.person_id
WHERE rp.status = 'Active';

/*
Expected Plan Behavior:
- Seq Scan on ResearchProject (filter: status = 'Active') — small table, no index needed
- Hash Join: ResearchProject x Supervision — hash built on project_id
- Index Scan on Lecturer using person_id PK — O(log n) lookup
- Index Scan on Student using person_id PK  — O(log n) lookup
- Execution Time: < 1 ms on this dataset

Interpretation:
PostgreSQL chooses Hash Join for the ResearchProject-Supervision link because
it can build a small hash table on the 20 research projects and probe it
with the 40 supervision records efficiently. Primary key lookups on Lecturer
and Student are resolved via index scans since person_id is a PK index.
*/

-- ============================================================
-- Analysis Query B: Aggregation Query
-- Query: Enrollment count per course with ordering
-- ============================================================
EXPLAIN ANALYZE
SELECT
    c.course_code,
    c.course_name,
    COUNT(e.student_id) AS enrollment_count
FROM Course c
LEFT JOIN Enrollment e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_code, c.course_name
ORDER BY enrollment_count DESC;

/*
Expected Plan Behavior:
- Seq Scan on Course (30 rows — full scan is cheaper than index)
- Seq Scan on Enrollment (400 rows)
- Hash Left Join on course_id
- HashAggregate: groups results by course_id, maintains running COUNT
- Sort: quicksort on enrollment_count DESC
- Execution Time: < 2 ms on this dataset

Interpretation:
PostgreSQL uses HashAggregate rather than GroupAggregate because the data
is not pre-sorted by course_id. The hash table holds one entry per course
and updates the COUNT as enrollment rows are scanned. The final Sort node
orders the output by count descending. At larger scale (100,000+ enrollments),
an index on Enrollment(course_id) would allow GroupAggregate using sorted
index access, avoiding the in-memory hash.
*/

-- ============================================================
-- Analysis Query C: Subquery
-- Query: Students not enrolled in any course
-- ============================================================
EXPLAIN ANALYZE
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
Expected Plan Behavior:
- Seq Scan on Enrollment — materializes all student_id values
- Hash Anti Join: scans Student, checks each person_id against the hash
  Rows that find NO match in the hash pass through (NOT IN logic)
- Index Scan on Department using department_id FK
- Execution Time: < 1 ms on this dataset

Interpretation:
PostgreSQL rewrites NOT IN as a Hash Anti Join automatically. The subquery
(SELECT DISTINCT student_id FROM Enrollment) is evaluated once and stored
in a hash structure. The outer Student scan probes this hash — any student
whose person_id IS found in the hash is excluded. This is more efficient
than a correlated subquery which would re-execute for every student row.
With idx_enrollment_student in place, the inner scan can use the index.
*/