# ULK Academic Activity & Resource Management System (PostgreSQL)

> Centralized PostgreSQL object-relational database for Kigali Independent University (ULK), integrating academic operations into a single structured platform.

---

## Project Overview
This database models core academic activities, including:
- Students and lecturers (inheritance from `Person`)
- Faculties, departments, and courses
- Enrollments and course assignments
- Timetabling (schedules in classroom/laboratory)
- Attendance tracking
- Research projects and supervision
- Academic events and event participation (union via `participant_type`)
- Department resources (inventory)

---

## PostgreSQL Features Used
- **User-defined composite types**
  - `address_type` (street, city, district)
  - `contact_info` (email, emergency phone)
- **Array attribute**
  - `phone_numbers TEXT[]` on `Person`
- **JSONB**
  - `equipment` on `Laboratory`
  - `metadata` on `ResearchProject`
- **Table inheritance**
  - `Person → Student, Lecturer`
  - `AcademicSpace → Classroom, Laboratory`
- **CHECK constraints**
  - `Student.year_of_study` range
  - `Attendance.status ∈ {Present, Absent, Late}`
  - `EventParticipation.participant_type ∈ {Student, Lecturer}`
- **Indexes**
  - B-Tree indexes on frequently queried foreign keys and lookup columns

---

## 📁 Repository Structure
```
ulk_db/
  README.md
  ERD/
    ulk_db - public.png
  report/
    ULK_Database_Report.pdf
  sql/
    ulk_schema.sql            # Phase 4: schema (types, tables, indexes)
    ulk_data.sql              # (If present) Phase 5: data population
    queries.sql              # Phase 6: 15 SQL queries
    queries_analysis.sql     # Phase 7: EXPLAIN ANALYZE for selected queries
    indexing.sql             # Phase 8: index performance experiment
    storage.sql              # Phase 9: storage investigation
    buffer_management.sql   # Phase 10: buffer management experiment
    dump-ulk_db-202606161105.sql # pg_dump backup of the database
```

> Note: In your current checkout, `ulk_data.sql` may not be present; use `dump-ulk_db-202606161105.sql` if you need a ready-to-load dataset.

---

## ▶️ How to Run

### 1) Create the database
```bash
createdb -U postgres ulk_db
```

### 2) Create schema
```bash
psql -U postgres -d ulk_db -f sql/ulk_schema.sql
```

### 3) Load data (two options)

**Option A — use a dump (recommended if available):**
```bash
psql -U postgres -d ulk_db -f sql/dump-ulk_db-202606161105.sql
```

**Option B — use population script (if present):**
```bash
psql -U postgres -d ulk_db -f sql/ulk_data.sql
```

### 4) Run the 15 queries
```bash
psql -U postgres -d ulk_db -f sql/queries.sql
```

### 5) Run experiments / analysis
```bash
psql -U postgres -d ulk_db -f sql/queries_analysis.sql
psql -U postgres -d ulk_db -f sql/indexing.sql
psql -U postgres -d ulk_db -f sql/storage.sql
psql -U postgres -d ulk_db -f sql/buffer_management.sql
```

---

## 🔎 Notes on Schema/Queries
- The project demonstrates object-relational modeling using **inheritance**, **composite types**, and **JSONB**.
- Event participation uses a **type-safe category pattern** via:
  - `participant_id`
  - `participant_type` (Student/Lecturer)

---

## 📚 Documentation
- **ER diagram:** `ERD/ulk_db - public.png`
- **Full report (PDF):** `report/ULK_Database_Report.pdf`

---

## 👤 Student / Course Info
- **Course:** Advanced Database Management
- **Lecturer:** KAMATE KATENDE TIMOTHEE
- **Institution:** Kigali Independent University (ULK)

---

## ✅ Data Integrity & Performance
Integrity is enforced through:
- Primary keys
- Foreign keys
- CHECK constraints
- Uniqueness constraints

Performance is addressed using:
- B-Tree indexes on join/filter columns
- Experiment scripts (`indexing.sql`, `storage.sql`, `buffer_management.sql`) to support the write-up.

