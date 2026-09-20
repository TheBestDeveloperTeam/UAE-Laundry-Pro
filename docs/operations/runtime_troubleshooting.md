# Runtime Troubleshooting Guide â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21
> **Owner:** LP-AGENT-OPS-LEAD

---

## Quick Diagnosis Flowchart

```
Issue Reported
    |
    +-- Application won't start?      --> Section 1
    +-- XAMPP service won't start?     --> Section 2
    +-- Database connection failed?    --> Section 3
    +-- API returning errors?          --> Section 4
    +-- Print job fails?               --> Section 5
    +-- Scanner not working?           --> Section 6
    +-- Sync not working?              --> Section 7
    +-- License error?                 --> Section 8
    +-- Performance degradation?       --> Section 9
    +-- Data inconsistency?            --> Section 10
    +-- UI rendering issues?           --> Section 11
    +-- Backup/Restore issues?         --> Section 12
```

---

## Section 1: Application Won't Start

### Symptoms
- MSIX app crashes on launch
- White screen on startup
- Error dialog on launch

### Diagnosis
1. Check Windows Event Viewer (Application log) for crash details.
2. Verify MSIX package integrity: `Get-AppxPackage *LaundryPro*`
3. Check if XAMPP services are running.
4. Check license validity (UMAC hash match).

### Resolution
| Cause | Fix |
|-------|-----|
| Corrupt MSIX | Reinstall MSIX package |
| XAMPP not running | Start Apache and MariaDB services |
| License expired | Renew license or enter grace period |
| Missing .env file | Restore from backup or recreate |
| Database unreachable | Check MariaDB port 3306 |

### Recovery
```powershell
# Verify XAMPP services
net start Apache2.4
net start mysql
# Verify database connection
mysql -u root -p -e "SELECT 1"
```

---

## Section 2: XAMPP Service Won't Start

### Apache Won't Start
| Cause | Fix |
|-------|-----|
| Port 80 occupied | `netstat -ano | findstr :80` then kill conflicting process or change Apache port |
| Port 443 occupied | Same as above for HTTPS port |
| Corrupt httpd.conf | Restore from `xampp/apache/conf/httpd.conf.bak` |
| Missing PHP module | Verify php.ini extension loading |

### MariaDB Won't Start
| Cause | Fix |
|-------|-----|
| Port 3306 occupied | `netstat -ano | findstr :3306` then kill conflicting process |
| Corrupt InnoDB files | Run `mysqlcheck --all-databases --repair` |
| Insufficient disk space | Free disk space (min 1 GB required) |
| my.ini syntax error | Restore from `xampp/mysql/bin/my.ini.bak` |

### Recovery
```powershell
# Check port conflicts
netstat -ano | findstr ":80 :443 :3306"
# Force kill conflicting PID
taskkill /PID <PID> /F
# Restart XAMPP services
& "C:\xampp\xampp_start.exe"
```

---

## Section 3: Database Connection Failed

### Symptoms
- API returns LP-ERR-SYS-5002
- "Connection refused" errors
- Timeout on database queries

### Diagnosis
```powershell
# Test MariaDB connectivity
mysql -u root -p -h 127.0.0.1 -P 3306 -e "SHOW DATABASES;"
# Check connection count
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"
# Check max connections
mysql -u root -p -e "SHOW VARIABLES LIKE 'max_connections';"
```

### Resolution
| Cause | Fix |
|-------|-----|
| MariaDB not running | Start MariaDB service |
| Max connections reached | Increase max_connections in my.ini (default: 100) |
| Wrong credentials in .env | Verify DB_HOST, DB_PORT, DB_USER, DB_PASS in .env |
| Firewall blocking | Allow port 3306 in Windows Firewall |
| InnoDB corruption | Run recovery: `innodb_force_recovery = 1` in my.ini, restart, then repair |

---

## Section 4: API Returning Errors

### Error Code Quick Reference
| Error Code | Meaning | Fix |
|------------|---------|-----|
| LP-ERR-AUTH-1001 | Invalid credentials | Verify username/password |
| LP-ERR-AUTH-1002 | Token expired | Refresh token via /auth/refresh |
| LP-ERR-AUTH-1004 | Insufficient permissions | Check user role and RBAC scopes |
| LP-ERR-AUTH-1006 | License expired | Renew UMAC license |
| LP-ERR-AUTH-1007 | Machine not authorized | Verify UMAC hash; re-bind license |
| LP-ERR-VAL-2001 | Required field missing | Check request payload |
| LP-ERR-VAL-2004 | Duplicate entry | Check for existing record |
| LP-ERR-BIZ-3002 | Invoice immutable | Use correction memo workflow |
| LP-ERR-SYNC-4001 | Sync conflict | Check dead-letter queue |
| LP-ERR-SYS-5001 | Internal server error | Check PHP error log |
| LP-ERR-SYS-5002 | Database connection failed | See Section 3 |

### PHP Error Log Location
`C:\xampp\php\logs\php_error_log` or `C:\xampp\apache\logs\error.log`

---

## Section 5: Print Job Fails

### Diagnosis
1. Check printer power and USB/network connection.
2. Run auto-discovery to verify detection.
3. Check Windows print spooler: `Get-Service Spooler`
4. Test with direct ESC/POS command.

### Resolution
| Cause | Fix |
|-------|-----|
| Printer offline | Power cycle printer; check USB cable |
| Wrong port assigned | Re-run auto-discovery |
| Print spooler stopped | `Start-Service Spooler` |
| Paper out | Reload paper |
| ESC/POS command error | Verify printer supports ESC/POS; check codepage for Arabic |
| Driver conflict | Remove and reinstall printer driver |

### Test Print
```powershell
# Test Windows spooler
Get-Printer | Format-Table Name, PortName, PrinterStatus
# Restart print spooler
Restart-Service Spooler
```

---

## Section 6: Scanner Not Working

### Diagnosis
1. Check USB connection.
2. Verify scanner appears in Device Manager (HID devices).
3. Test scanner output in Notepad (should inject text + Enter).

### Resolution
| Cause | Fix |
|-------|-----|
| USB not connected | Reconnect USB cable |
| Wrong HID mode | Configure scanner for USB HID keyboard wedge mode |
| Scanner sending wrong suffix | Configure scanner to send CR (Enter) suffix |
| Bluetooth not paired | Re-pair Bluetooth scanner |
| Application not capturing input | Ensure focus is on the scan input field |

---

## Section 7: Sync Not Working

### Diagnosis
```sql
-- Check outbox status
SELECT status, COUNT(*) FROM sync_outbox GROUP BY status;
-- Check dead-letter entries
SELECT * FROM sync_outbox WHERE status = 'dead' ORDER BY created_at DESC LIMIT 10;
-- Check last sync time
SELECT MAX(synced_at) FROM sync_outbox WHERE status = 'synced';
```

### Resolution
| Cause | Fix |
|-------|-----|
| No internet | Expected in offline mode; entries queue in outbox |
| Cloud endpoint down | Entries queue; retry on next connectivity |
| Max retries exceeded | Check dead-letter queue; investigate and replay |
| Conflict unresolved | Manual resolution via admin interface |
| Tenant isolation violation | CRITICAL: investigate immediately |
| Outbox table locked | Check for long-running transactions; restart MariaDB |

---

## Section 8: License Error

### UMAC Troubleshooting
| Symptom | Cause | Fix |
|---------|-------|-----|
| Machine not authorized | Hardware changed (CPU, disk, NIC) | Re-bind license to new hardware hash |
| License expired | Subscription lapsed | Renew license key |
| Read-only mode | Grace period exceeded (30 days offline) | Connect to internet for license verification |
| Invalid license format | Corrupt license key | Request new license from vendor |

### Hardware Hash Verification
```powershell
# Get CPU ID
wmic cpu get ProcessorId
# Get disk serial
wmic diskdrive get SerialNumber
# Get MAC address
getmac /v
```

---

## Section 9: Performance Degradation

### Diagnosis
| Area | Check | Tool |
|------|-------|------|
| Database | Slow queries | `SHOW PROCESSLIST;` and slow query log |
| API | Response time | Check API response time headers |
| UI | Frame rate | Flutter DevTools performance tab |
| Memory | Leak detection | Task Manager memory trend |
| Disk | Space | `Get-PSDrive C` |

### Quick Fixes
```sql
-- Find slow queries
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
-- Analyze table statistics
ANALYZE TABLE orders, order_items, invoices, customers;
-- Check missing indexes
EXPLAIN SELECT * FROM orders WHERE business_owner_id = 1 AND status = 'pending';
```

---

## Section 10: Data Inconsistency

### Diagnosis
```sql
-- Check orphaned order items
SELECT oi.id FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.id WHERE o.id IS NULL;
-- Check invoice-payment mismatch
SELECT i.id, i.total_amount, COALESCE(SUM(p.amount),0) as paid FROM invoices i LEFT JOIN payments p ON p.invoice_id = i.id GROUP BY i.id HAVING i.total_amount != paid;
-- Check tenant isolation
SELECT table_name FROM information_schema.columns WHERE column_name = 'business_owner_id' AND table_schema = 'laundrypro';
```

### Resolution
1. Identify root cause (missing FK, failed sync, bug).
2. Take backup before any data fix.
3. Apply data correction with audit log entry.
4. Verify with integrity checks.
5. Add regression test to prevent recurrence.

---

## Section 11: UI Rendering Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| RTL layout broken | Missing Directionality | Wrap with Directionality widget |
| Text overflow | Long Arabic text | Use TextOverflow.ellipsis or Flexible |
| Widget rebuild jank | Unnecessary rebuilds | Use const constructors and select() |
| Theme not applied | Wrong context | Ensure Theme.of(context) is used |
| Images not loading | Wrong path | Check asset declarations in pubspec.yaml |

---

## Section 12: Backup/Restore Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Backup fails | Disk full | Free space; minimum 2x database size |
| SHA-256 mismatch | Corrupt backup file | Re-run backup; check disk health |
| Restore fails | Version mismatch | Ensure backup matches current schema version |
| Partial restore | Interrupted process | Restore from the previous clean backup |

### Emergency Backup
```powershell
# Emergency manual backup
cd C:\xampp\mysql\bin
mysqldump -u root -p --single-transaction --routines --triggers laundrypro > "backup_emergency_20260921_014725.sql"
```

---

## Escalation Matrix for Runtime Issues
| Severity | Response Time | Who to Contact |
|----------|--------------|----------------|
| P1 Critical (system down) | 15 min | OPS-L3 + CTO |
| P2 High (major feature broken) | 1 hour | OPS-L2 + ENG-LEAD |
| P3 Medium (workaround available) | 4 hours | OPS-L1 |
| P4 Low (cosmetic/enhancement) | Next sprint | Backlog |

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial runtime troubleshooting guide |