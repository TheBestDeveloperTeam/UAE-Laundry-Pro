# Protocol: Database Backup

## Schedule
- Full backup: Daily at 02:00 AM local time
- Incremental backup: Every 4 hours
- Pre-migration backup: Before any schema change

## Steps
1. Lock write operations (brief maintenance window for full backup).
2. Execute mysqldump with --single-transaction --routines --triggers.
3. Compress backup file (gzip).
4. Generate SHA-256 hash of compressed file.
5. Store backup with naming: backup_YYYYMMDD_HHMMSS.sql.gz.
6. Store hash file: backup_YYYYMMDD_HHMMSS.sql.gz.sha256.
7. Verify backup by comparing SHA-256 hash.
8. Retain policy: 30 daily backups, 12 monthly backups, 2 yearly backups.
9. Log backup completion to audit trail.

## Restore Procedure
1. Verify SHA-256 hash of backup file.
2. Decompress backup.
3. Restore to temporary database first.
4. Validate row counts and data integrity.
5. Swap databases (rename).
6. Verify application connectivity.