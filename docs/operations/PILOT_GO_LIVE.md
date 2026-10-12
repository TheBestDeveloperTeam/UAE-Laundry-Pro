# Pilot store go-live sign-off

Use after [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) engineering gate is green.

## 1. Cloud tenant prep

| Step | Owner | Done |
|------|-------|------|
| Create business/tenant in super-admin | Cloud ops | [ ] |
| Issue license key | Cloud ops | [ ] |
| Record TRN / branch profile | Cloud ops | [ ] |

## 2. Store install

| Step | Owner | Done |
|------|-------|------|
| Deploy local API + DB migrate | Field IT | [ ] |
| Install signed MSIX | Field IT | [ ] |
| Run setup wizard + activate license | Store manager | [ ] |
| Register sync + backup tasks | Field IT | [ ] |

## 3. Functional acceptance (same day)

| Test | Expected | Done |
|------|----------|------|
| Login cashier | JWT session | [ ] |
| Create + confirm sale | Receipt prints | [ ] |
| Disconnect LAN 10 min | Sale still works offline | [ ] |
| Reconnect | Outbox drains; cloud admin sees sync | [ ] |
| Backup file in `C:\LaundryPro\backups` | New zip after 02:00 or manual `backup_cli.php` | [ ] |

## 4. Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Store manager | | | |
| Field IT | | | |
| Cloud ops | | | |

**Notes / incidents:**
