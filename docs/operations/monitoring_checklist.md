# System Monitoring Checklist â€” LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Real-Time Monitors
| What | How | Alert Threshold |
|------|-----|-----------------|
| Apache status | `sc query Apache2.4` | Service not running |
| MariaDB status | `sc query mysql` | Service not running |
| Disk space | `Get-PSDrive C` | < 1 GB free |
| Database connections | `SHOW STATUS LIKE 'Threads_connected'` | > 80 |
| Sync outbox pending | `SELECT COUNT(*) FROM sync_outbox WHERE status='pending'` | > 1000 |
| Dead-letter entries | `SELECT COUNT(*) FROM sync_outbox WHERE status='dead'` | > 0 |
| API error rate | PHP error log analysis | > 10 errors/hour |
| Backup age | Last backup timestamp | > 26 hours |

## Health Check Script
```powershell
# LaundryPro Health Check
Write-Host "=== LaundryPro UAE Health Check ==="
Write-Host "Date: 09/21/2026 01:47:25"

# Services
Write-Host "
Services:"
@("Apache2.4","mysql") | ForEach-Object {
    $svc = Get-Service $_ -ErrorAction SilentlyContinue
    Write-Host "  $_: $(if ($svc.Status -eq 'Running') {'OK'} else {'DOWN!'})"
}

# Disk
Write-Host "
Disk:"
$drive = Get-PSDrive C
Write-Host "  Free: $([math]::Round($drive.Free/1GB, 2)) GB"

# Database
Write-Host "
Database:"
$result = & "C:\xampp\mysql\bin\mysql.exe" -u root -e "SELECT 'OK' AS status" 2>$null
Write-Host "  Connection: $(if ($result -match 'OK') {'OK'} else {'FAILED!'})"

Write-Host "
=== Health Check Complete ==="
```