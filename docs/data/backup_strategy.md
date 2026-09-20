# Backup Strategy - LaundryPro UAE
> **Version:** 1.0.0

## Backup Types
| Type | Frequency | Retention |
|------|-----------|-----------|
| Full | Daily 02:00 AM | 30 days |
| Incremental | Every 4 hours | 7 days |
| Pre-migration | Before schema changes | Permanent |
| Manual | On-demand | 90 days |

## Backup Verification
- SHA-256 hash generated for every backup file.
- Hash stored alongside backup file.
- Automated verification on backup completion.
- Monthly restore test on isolated environment.

## Storage
- Local: XAMPP backup directory.
- External: USB/network drive (recommended).
- Cloud: Sync to cloud when connectivity available (optional).

## Restore SLA
- Full restore: < 30 minutes for databases up to 10 GB.
- Point-in-time restore: Via incremental backups within 4-hour window.