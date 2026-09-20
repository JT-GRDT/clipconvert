| Feature | PostgreSQL | MySQL | SQLite |
| --- | --- | --- | --- |
| **Architecture** | Client-Server (Multi-process model) | Client-Server (Thread-per-connection model) | Serverless / Embedded (In-process, reads/writes directly to file) |
| **Concurrency \& Locking** | High concurrency; uses MVCC so readers don't block writers | High concurrency; uses row-level locking with the InnoDB engine | Low concurrency; locks the database file during writes (one writer at a time) |
| **Data Types \& Features** | Highly extensible; supports native JSONB, PostGIS, custom types, and arrays | Supports standard data types, JSON, CTEs, and window functions | Dynamic typing (manifest typing); stores values as NULL, INTEGER, REAL, TEXT, or BLOB |
| **Best Use Case** | Complex data structures, high write concurrency, heavy analytical queries, enterprise web apps | High-traffic web applications, content management systems (CMS), read-heavy workloads | Mobile applications, desktop apps, edge devices, testing, low-to-medium traffic sites |
| **Setup \& Administration** | Requires installation, background service management, and regular autovacuum maintenance | Requires setup, user/privilege management, and server administration | Zero configuration; single database file with no setup or background process required |
