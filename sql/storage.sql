-- ============================================================
-- ULK Academic Activity and Resource Management System
-- Phase 9: Storage Investigation
-- Course: Advanced Database Management
-- Lecturer: KAMATE KATENDE TIMOTHEE
-- ============================================================

-- ============================================================
-- 9.1 Overall Database Size
-- ============================================================
SELECT
    current_database()                              AS database_name,
    pg_size_pretty(pg_database_size(current_database())) AS database_size;

/*
Expected Output:
database_name | database_size
-------------------------------
ulk_db        | 8.5 MB
*/

-- ============================================================
-- 9.2 Size of Each Table (Data + Indexes + TOAST)
-- ============================================================
SELECT
    relname                                              AS table_name,
    pg_size_pretty(pg_total_relation_size(relid))        AS total_size,
    pg_size_pretty(pg_relation_size(relid))              AS data_size,
    pg_size_pretty(pg_indexes_size(relid))               AS index_size,
    n_live_tup                                           AS live_rows
FROM pg_catalog.pg_statio_user_tables
JOIN pg_stat_user_tables USING (relid)
ORDER BY pg_total_relation_size(relid) DESC;

/*
Expected Output:
table_name         | total_size | data_size | index_size | live_rows
---------------------------------------------------------------------
student            | 120 kB     | 80 kB     | 40 kB      | 100
enrollment         | 72 kB      | 48 kB     | 24 kB      | 400
attendance         | 48 kB      | 32 kB     | 16 kB      | 300
lecturercourse     | 40 kB      | 24 kB     | 16 kB      | 105
...
*/

-- ============================================================
-- 9.3 Page and Tuple Statistics (Physical Storage)
-- ============================================================
SELECT
    relname      AS table_name,
    relpages     AS data_pages,
    reltuples    AS estimated_rows,
    CASE
        WHEN relpages > 0
        THEN ROUND(reltuples / relpages, 2)
        ELSE 0
    END          AS rows_per_page
FROM pg_class
WHERE relkind = 'r'
  AND relname IN (
      'student','lecturer','course','enrollment',
      'attendance','researchproject','supervision',
      'academicevent','eventparticipation','resource',
      'lecturercourse','schedule','department','faculty'
  )
ORDER BY relpages DESC;

/*
Explanation:
- relpages: number of 8 KB disk pages the table occupies
- reltuples: estimated number of rows
- rows_per_page: how many rows fit per page
  (Student rows are large due to composite types and arrays,
   so fewer rows per page than simple tables)
*/

-- ============================================================
-- 9.4 TOAST Usage (for JSONB and large TEXT columns)
-- ============================================================
SELECT
    c.relname                                       AS main_table,
    t.relname                                       AS toast_table,
    pg_size_pretty(pg_total_relation_size(t.oid))  AS toast_size
FROM pg_class c
JOIN pg_class t ON c.reltoastrelid = t.oid
WHERE c.relname IN ('researchproject','laboratory','student','lecturer')
ORDER BY pg_total_relation_size(t.oid) DESC;

/*
Explanation:
TOAST (The Oversized-Attribute Storage Technique) is used automatically
by PostgreSQL when column values exceed ~2 KB. In this system:
- ResearchProject.metadata (JSONB) may trigger TOAST for large metadata
- Laboratory.equipment (JSONB) stores equipment lists
- Student.phone_numbers (TEXT[]) and composite type columns
The TOAST table stores compressed/external values; the main table
stores only a pointer to the TOAST entry.
*/

-- ============================================================
-- 9.5 Index Usage Statistics
-- ============================================================
SELECT
    indexrelname   AS index_name,
    relname        AS table_name,
    idx_scan       AS times_used,
    idx_tup_read   AS tuples_read,
    idx_tup_fetch  AS tuples_fetched
FROM pg_stat_user_indexes
JOIN pg_statio_user_indexes USING (indexrelid)
ORDER BY idx_scan DESC;

/*
Explanation:
- idx_scan: how many times this index has been used by the planner
- idx_tup_read: tuples read from index pages
- idx_tup_fetch: tuples fetched from heap using index
High idx_scan values indicate heavily used indexes.
Low values may indicate unused indexes that waste write overhead.
*/

-- ============================================================
-- 9.6 Storage Structure Summary
-- ============================================================
/*
PostgreSQL Physical Storage Summary for ULK System:

PAGES (BLOCKS):
  - Default page size: 8 KB
  - Each table stored as heap file: base/<db_oid>/<relfilenode>
  - Student table (~100 rows, large composite columns): ~2-3 pages
  - Enrollment table (~400 rows, small columns): ~2 pages

TUPLES:
  - Each row = HeapTuple with 23-byte header (xmin, xmax, ctid for MVCC)
  - Student tuple ~300-400 bytes (address_type + contact_info + TEXT[])
  - Enrollment tuple ~40 bytes (4 integers + date)

HEAP STORAGE:
  - Unordered (rows stored in insertion order)
  - Dead tuples accumulate after UPDATE/DELETE (MVCC keeps old versions)
  - VACUUM reclaims dead tuple space

TOAST STORAGE:
  - Triggered automatically for values > ~2 KB
  - Used by: ResearchProject.metadata, Laboratory.equipment
  - Compression: pglz algorithm applied before external storage

FILE ORGANIZATION:
  - Each table = one or more files in data/base/<oid>/
  - Files split at 1 GB: relfilenode, relfilenode.1, relfilenode.2 ...
  - Indexes stored in separate files with same naming convention
  - Free Space Map (.fsm) tracks available space per page
  - Visibility Map (.vm) tracks all-visible pages for vacuum
*/