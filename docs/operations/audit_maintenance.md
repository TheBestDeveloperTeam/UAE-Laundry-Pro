# Audit & Maintenance Guide â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Daily Maintenance Checklist
- [ ] Verify XAMPP services running (Apache + MariaDB)
- [ ] Check disk space (minimum 1 GB free)
- [ ] Verify daily backup completed successfully
- [ ] Check sync outbox for dead-letter entries
- [ ] Review error.log for new errors

## Weekly Maintenance Checklist
- [ ] Run database ANALYZE TABLE on all tables
- [ ] Review slow query log
- [ ] Check backup SHA-256 integrity
- [ ] Review audit_logs for anomalies
- [ ] Verify license validity (days remaining)

## Monthly Maintenance Checklist
- [ ] Test backup restore on isolated environment
- [ ] Review and rotate PHP error logs
- [ ] Update dependency lock files (pubspec.lock, composer.lock)
- [ ] Run full security scan (RBAC audit, SQL injection test)
- [ ] Review memory usage trends

## Audit Trail Integrity Verification
```sql
-- Verify hash chain integrity
SELECT a1.id, a1.hash, a2.hash as prev_hash
FROM audit_logs a1
LEFT JOIN audit_logs a2 ON a2.id = a1.id - 1
WHERE a1.id > 1
AND a1.prev_hash != a2.hash
LIMIT 10;
-- If any rows returned, hash chain is broken (investigate tampering)
```

## Database Health Queries
```sql
-- Table sizes
SELECT table_name, ROUND(data_length/1024/1024, 2) AS size_mb, table_rows
FROM information_schema.tables WHERE table_schema = 'laundrypro'
ORDER BY data_length DESC;

-- Index usage
SELECT table_name, index_name, seq_in_index, column_name
FROM information_schema.statistics WHERE table_schema = 'laundrypro'
ORDER BY table_name, index_name, seq_in_index;

-- Fragmentation check
SELECT table_name, ROUND(data_free/1024/1024, 2) AS fragmented_mb
FROM information_schema.tables WHERE table_schema = 'laundrypro' AND data_free > 0;
```

## Log Rotation Policy
| Log | Location | Rotation | Retention |
|-----|----------|----------|-----------|
| PHP error log | C:\xampp\php\logs\ | Weekly | 30 days |
| Apache access log | C:\xampp\apache\logs\ | Daily | 90 days |
| Apache error log | C:\xampp\apache\logs\ | Daily | 90 days |
| Agent decision log | .ai/logs/decisions.log.md | Monthly archive | Permanent |
| Audit trail | audit_logs table | None (append-only) | Permanent |