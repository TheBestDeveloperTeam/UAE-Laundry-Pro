# Migration Strategy - LaundryPro UAE
> **Version:** 1.0.0

## Principles
1. All migrations are sequential (001, 002, 003...).
2. All migrations are idempotent (IF NOT EXISTS / IF EXISTS).
3. All migrations have a corresponding rollback script.
4. Pre-migration backup is mandatory.
5. Migrations are tested on a copy of production data first.

## Migration File Naming
`{NNN}_{description}.sql`
Example: `001_baseline.sql`, `002_add_rfid_columns.sql`

## Migration Procedure
1. Create migration file in `api/database/migrations/`.
2. Create rollback file in `api/database/migrations/rollback/`.
3. Test migration on development database.
4. Take pre-migration backup (backup.protocol).
5. Execute migration on production.
6. Verify migration success (row counts, schema check).
7. Log migration in `migrations` tracking table.

## Current Migrations
| Number | Description | Date |
|--------|------------|------|
| 001 | Baseline schema (50+ tables) | 2026-09-20 |