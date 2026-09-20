| Aspect | PostgreSQL | MySQL | SQLite |
|---|---|---|---|
| **Architecture** | Client-server; separate process handling connections | Client-server; separate process handling connections | Embedded/serverless; runs in-process, no separate server |
| **Best for** | Complex queries, data integrity, analytical workloads | Web apps, read-heavy workloads, simple CRUD apps | Mobile/desktop apps, local storage, testing, low-traffic sites |
| **Concurrency** | Strong multi-version concurrency control (MVCC), handles many concurrent writers well | Good concurrency, especially with InnoDB, though historically weaker than Postgres for writes | Limited — locks the whole database file on writes, not ideal for high write concurrency |
| **Data types \& extensibility** | Very rich (JSON/JSONB, arrays, custom types, extensions like PostGIS) | Solid standard support, fewer advanced types out of the box | Dynamic typing (flexible but can be a gotcha), fewer built-in types |
| **Standards compliance** | Very strong SQL standard compliance | Historically looser compliance (some quirks), improved over versions | Mostly compliant but has quirks (e.g., loose typing, limited ALTER TABLE support) |
| **Setup \& maintenance** | Requires installation, configuration, and a running server | Requires installation and a running server | Zero setup — it's just a file, no server to manage |
| **Scalability** | Scales well vertically and with extensions/replication for larger workloads | Scales well, especially with read replicas, very common at web scale | Not designed for high concurrency or large multi-user scale |
| **License** | Open source (PostgreSQL License, permissive) | Open source (GPL, with Oracle-owned commercial options) | Public domain |

**Quick take:** SQLite is the right call when you want something simple, embedded, and file-based (mobile apps, prototypes, small tools). MySQL is a solid default for typical web applications with moderate scale. PostgreSQL shines when you need advanced features, strict data integrity, or complex queries — it's often the go-to for larger or more sophisticated systems these days.
