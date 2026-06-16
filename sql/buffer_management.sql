-- ============================================================
-- ULK Academic Activity and Resource Management System
-- Phase 10: Buffer Management Experiment
-- Course: Advanced Database Management
-- Lecturer: KAMATE KATENDE TIMOTHEE
-- ============================================================
-- Run Execution 1, then immediately run Execution 2.
-- Compare the "shared read" vs "shared hit" values.
-- ============================================================

-- ============================================================
-- 10.1 Check current shared_buffers setting
-- ============================================================
SHOW shared_buffers;

/*
Default: 128MB
Recommendation for production: 25% of total RAM
*/

-- ============================================================
-- 10.2 EXPERIMENT: Student + Department Join
-- ============================================================

-- EXECUTION 1 — Cold Buffer (first run, data read from disk)
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.first_name, s.last_name, s.registration_number,
       d.department_name
FROM Student s
JOIN Department d ON s.department_id = d.department_id
ORDER BY d.department_name, s.last_name;

/*
Expected Output (first run):
Hash Join
  Buffers: shared hit=0 read=4
  ->  Seq Scan on student    (Buffers: shared read=3)
  ->  Hash
        ->  Seq Scan on department (Buffers: shared read=1)
Planning Time:  ~0.5 ms
Execution Time: ~1.2 ms

"shared read=4" means 4 pages were read from DISK into shared_buffers.
*/

-- EXECUTION 2 — Warm Buffer (second run, data served from memory)
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.first_name, s.last_name, s.registration_number,
       d.department_name
FROM Student s
JOIN Department d ON s.department_id = d.department_id
ORDER BY d.department_name, s.last_name;

/*
Expected Output (second run):
Hash Join
  Buffers: shared hit=4 read=0
  ->  Seq Scan on student    (Buffers: shared hit=3)
  ->  Hash
        ->  Seq Scan on department (Buffers: shared hit=1)
Planning Time:  ~0.4 ms
Execution Time: ~0.3 ms

"shared hit=4 read=0" means ALL 4 pages were found in shared_buffers.
No disk access occurred. Execution time dropped by ~75%.
*/

-- ============================================================
-- 10.3 EXPERIMENT: Enrollment table (larger table)
-- ============================================================

-- EXECUTION 1 — Cold Buffer
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.student_id, e.course_id, e.enrollment_date,
       c.course_name
FROM Enrollment e
JOIN Course c ON e.course_id = c.course_id;

-- EXECUTION 2 — Warm Buffer
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.student_id, e.course_id, e.enrollment_date,
       c.course_name
FROM Enrollment e
JOIN Course c ON e.course_id = c.course_id;

-- ============================================================
-- 10.4 Buffer Hit Rate Across All Tables
-- ============================================================
SELECT
    relname                                              AS table_name,
    heap_blks_read                                       AS disk_reads,
    heap_blks_hit                                        AS buffer_hits,
    heap_blks_read + heap_blks_hit                       AS total_accesses,
    ROUND(
        heap_blks_hit::NUMERIC /
        NULLIF(heap_blks_hit + heap_blks_read, 0) * 100, 2
    )                                                    AS buffer_hit_pct
FROM pg_statio_user_tables
WHERE heap_blks_hit + heap_blks_read > 0
ORDER BY buffer_hit_pct DESC NULLS LAST;

/*
Expected Output (after running several queries):
table_name         | disk_reads | buffer_hits | total_accesses | buffer_hit_pct
---------------------------------------------------------------------------------
department         | 1          | 15          | 16             | 93.75
faculty            | 1          | 12          | 13             | 92.31
course             | 2          | 18          | 20             | 90.00
student            | 3          | 24          | 27             | 88.89
enrollment         | 4          | 28          | 32             | 87.50

Interpretation:
- Small tables (Department, Faculty) achieve very high hit ratios quickly
  because they fit in very few pages and remain in shared_buffers.
- Larger tables (Enrollment, Student) have slightly lower ratios initially
  but improve as repeated queries warm the buffer pool.
- A buffer hit ratio above 90% is considered good for OLTP workloads.
- Tuning shared_buffers to 25% of RAM improves hit ratios significantly
  for production systems with larger datasets.
*/

-- ============================================================
-- 10.5 Summary Comparison Table
-- ============================================================
/*
Experiment Results Summary:

| Metric              | Execution 1 (Cold) | Execution 2 (Warm) |
|---------------------|--------------------|--------------------|
| Disk Reads          | 4 pages            | 0 pages            |
| Buffer Hits         | 0                  | 4 pages            |
| Execution Time      | ~1.2 ms            | ~0.3 ms            |
| I/O Source          | Physical Disk      | Shared Buffer (RAM)|
| Performance Gain    | baseline           | ~75% faster        |

Conclusion:
PostgreSQL's shared buffer pool (shared_buffers) caches frequently
accessed pages in memory. After the first execution loads data from
disk, subsequent queries find pages already in RAM, eliminating
disk I/O entirely. For the ULK system, tables like Student, Course,
and Enrollment will be heavily accessed and will quickly become
"hot" in the buffer pool, making repeated queries very fast.
*/