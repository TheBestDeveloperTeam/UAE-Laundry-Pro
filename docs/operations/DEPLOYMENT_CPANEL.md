# cPanel cloud deployment

**Canonical guide:** [deployment.md](../../deployment.md) at the repository root.

Quick reminders:

- Cloud DB: `php cloud-api/scripts/deploy.php` only — **not** `database/schema.sql`.
- Upload must include `cloud-api/database/migrations/` (001 + 002).
- Rebuild: `REBUILD_CONFIRM=1 php cloud-api/scripts/deploy.php --fresh`
- Minimal pack: `.\scripts\build_cloud_cpanel.ps1` → `dist/cloud-cpanel-upload.zip`
- **Automated SSH:** `.\scripts\cloud_deploy.ps1` (always fresh DB — see deployment.md §12)
- Do not upload `.archive/` to the server.

Example `DEPLOY_ROOT` (FTP + SSH upload target):

`/home/CPANEL_USER/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in`

Option A HTTP document root (cPanel → Domains):

`/home/CPANEL_USER/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api/public`

Set `deploy_layout=option_a` and matching `http_docroot` in `scripts/cloud_deploy/credentials.ini`. Check alignment:

```powershell
powershell -File scripts/cloud_deploy/verify_path_alignment.ps1
```
