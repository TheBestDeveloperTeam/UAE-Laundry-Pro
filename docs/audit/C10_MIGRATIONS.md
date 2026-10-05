# C10 — Database Migration & Schema Unification Strategy

> **Chunk:** C10 | **Date:** 2026-10-05 | **Resume Token:** `RT-C10-20261005-MIGRATION-STRATEGY`
> **Depends On:** C1 (Census), C2 (Schema Audit), C9 (Technical Debt)

---

## 1. Executive Summary

The database architecture for LaundryPro UAE spans two runtime environments:
1. **On-Premise / Edge:** Edge stores running on MariaDB 10.11 or embedded SQLite 3.x (`database/schema.sql`, `api/database/migrations/001_local_initial_schema.sql`).
2. **Cloud Multi-Tenant Hub:** Clustered MariaDB / AWS Aurora (`cloud-api/database/migrations/001_cloud_initial_schema.sql`, `002_tenant_full_domain_schema.sql`).

This strategy establishes a deterministic, automated migration pipeline that guarantees **zero data loss**, **idempotent version tracking**, and **smooth unification** of redundant table definitions identified in C2.

---

## 2. Migration Execution Architecture

### 2.1 The Migration Engine (`MigrationService.php` / `cloud-api/database/migrate.php`)
Both APIs incorporate an internal, zero-dependency migration runner that operates via a dedicated tracker table:

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    migration VARCHAR(255) NOT NULL UNIQUE,
    batch INT NOT NULL,
    executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 2.2 Execution Principles
1. **Idempotency:** Every DDL statement uses `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, or conditional index creation blocks.
2. **Transactional Wrapping:** For MariaDB supporting DDL or transactional DML, each migration file is executed inside atomic blocks or wrapped in try-catch with rollback handling.
3. **Pre-Flight Snapshot:** The `BackupService` triggers an automatic physical/logical dump of the active database before executing pending migrations.

---

## 3. Migration Roadmap & Consolidation Plan

```
Current State (Fragmented)             Target State (Unified Architecture)
┌───────────────────────────┐         ┌─────────────────────────────────┐
│ database/schema.sql       │         │ Canonical Consolidated DDL      │
│ (176 KB, 219 CREATE stmts)│────────▶│ • 95 Normalized Unique Tables   │
│ Duplicate table blocks    │         │ • Strict Foreign Key Integrity  │
└───────────────────────────┘         │ • Standardized Compound Indexes │
                                      └─────────────────────────────────┘
                                                       │
                                      ┌────────────────┴────────────────┐
                                      ▼                                 ▼
                         ┌──────────────────────────┐     ┌──────────────────────────┐
                         │ Local Store Engine       │     │ Cloud Multi-Tenant Hub   │
                         │ (Edge SQLite / MariaDB)  │     │ (Clustered MariaDB)      │
                         │ + Local sync_outbox      │     │ + tenant_id multi-tenant │
                         └──────────────────────────┘     └──────────────────────────┘
```

### Phased Migration Sequence

| Phase | Migration Script | Target Scope |
|:------|:-----------------|:-------------|
| **Phase 1** | `001_core_baseline.sql` | Business profile, users, roles, permissions, audit_logs. |
| **Phase 2** | `002_catalog_inventory.sql` | Service categories, items, prices, modifiers, warehouses, purchase orders. |
| **Phase 3** | `003_pos_sales.sql` | Customers, orders, order_items, payments, invoices, refunds, tax rates. |
| **Phase 4** | `004_workforce_hr.sql` | Employees, contracts, attendance, shifts, leave_requests, payroll, SIF records. |
| **Phase 5** | `005_industrial_operations.sql` | Machines, cycles, medical sterilization batches, chemical dosing logs, RFID tags. |
| **Phase 6** | `006_sync_telemetry.sql` | sync_outbox, sync_inbox, sync_conflicts, terminals, channels. |

---

## 4. Rollback & Disaster Recovery Protocol

In the event of an unexpected migration failure:
1. **Immediate Abort:** The migration runner halts execution at the failing file, recording the error in `logs/migration_errors.log`.
2. **Batch Rollback:** Executes corresponding down migrations or invokes `BackupService::restoreFromLatestPreMigrationDump()`.
3. **Integrity Verification:** Runs schema validation queries checking table count and foreign key constraints before re-opening traffic to the application.

---

## 5. Audit Sign-Off

- **Migration Readiness:** High. Clean separation between local and cloud migrations with automated runner support.
- **Data Safety:** Fully preserved with pre-flight backup hooks.
