# Release checklist (Production Pack v2.0)

## Engineering gate (before tagging)

- [ ] `.\scripts\quality-gate.ps1` exits 0
- [ ] `docs/operations/RELEASE_NOTES.md` updated with version + test counts
- [ ] No `.env` files staged in git

## Cloud (cPanel)

- [ ] Follow [deployment.md](../../deployment.md)
- [ ] `php cloud-api/scripts/deploy.php` success
- [ ] Cron: `clean_sessions.php`, `sync_health_collector.php`
- [ ] `GET /api/v1/health` → database connected
- [ ] Super-admin login; password not default
- [ ] `CORS_ALLOWED_ORIGINS` not `*`

## Local Windows (pilot store)

- [ ] [LOCAL_WINDOWS_SETUP.md](LOCAL_WINDOWS_SETUP.md) completed
- [ ] `api/.env` from `api/.env.production.template`
- [ ] Migrations applied
- [ ] Task Scheduler: `LaundryPro_SyncOutbox`, `LaundryPro_DailyBackup`
- [ ] Manual backup + restore drill once

## Desktop MSIX

- [ ] Built via `.\scripts\build_prod.ps1 -BuildMsix -CertificatePath ...`
- [ ] `--dart-define` URLs match store Apache vhost + cloud domain
- [ ] Clean VM install without developer mode
- [ ] Offline sale → online sync round-trip

## Rollback

- [ ] Previous MSIX + API zip retained with `MANIFEST.json` checksums
- [ ] Cloud DB export via cPanel before schema deploy
