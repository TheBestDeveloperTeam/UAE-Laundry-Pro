# LaundryPro UAE — cPanel Production Deployment (canonical)

> **Stack:** PHP 8.2 + Apache/LiteSpeed + MariaDB — **no Docker, Node, or Composer required**  
> **Also published as:** [docs/operations/DEPLOYMENT_CPANEL.md](docs/operations/DEPLOYMENT_CPANEL.md)

---

## Security notice

- **Never commit** `.env`, `.env.production`, or real passwords to git.
- If credentials ever appeared in documentation or chat logs, **rotate** database passwords, `JWT_SECRET`, `LICENSE_MASTER_SECRET`, and super-admin passwords on the server immediately.
- Use explicit `CORS_ALLOWED_ORIGINS` in production (not `*`).
- Do **not** set `0777` on web-facing folders; only `cloud-api/logs` and `cloud-api/storage` need write access (typically `755`).
- Prefer **SSH key auth** for deploy automation; rotate any password that was stored in plaintext outside a secret manager.

---

## Table of contents

1. [Cloud vs local database](#1-cloud-vs-local-database)
2. [Prerequisites](#2-prerequisites)
3. [Upload layout (cPanel)](#3-upload-layout-cpanel)
4. [Database (cPanel)](#4-database-cpanel)
5. [Environment files](#5-environment-files)
6. [URL rewriting (.htaccess)](#6-url-rewriting-htaccess)
7. [Migrations and deploy engine](#7-migrations-and-deploy-engine)
8. [Rebuild cloud database (drop all tables)](#8-rebuild-cloud-database-drop-all-tables)
9. [cPanel cron jobs](#9-cpanel-cron-jobs)
10. [Verification](#10-verification)
11. [Connect Windows POS terminals](#11-connect-windows-pos-terminals)
12. [Automated SSH deploy](#12-automated-ssh-deploy)
13. [Troubleshooting](#13-troubleshooting)

---

## 1. Cloud vs local database

| | **Cloud (this guide)** | **Local (each Windows store)** |
|--|------------------------|--------------------------------|
| **Where** | MariaDB on cPanel | MySQL/SQLite on the POS PC |
| **Tables** | `businesses`, `sync_*`, `tenant_*` | `settings`, `sales`, `customers`, … |
| **Tenancy** | Many organizations (`tenant_id`) | Single store (no `tenant_id` on every row) |
| **How to create** | `php cloud-api/scripts/deploy.php` | Local `api` install / migrations |

Domains are aligned (POS sync, licensing, reports), but **table names are not identical**.  
**Never** import workstation SQL (`database/schema.sql`, `database/local/schema.sql`, `api/database/migrations/*`) into the **cloud** database.

---

## 2. Prerequisites

| Item | Requirement |
|------|-------------|
| Hosting | cPanel shared or reseller with PHP 8.2+ |
| Web server | Apache or LiteSpeed with `mod_rewrite` |
| Database | MariaDB / MySQL 10.4+ |
| TLS | Valid certificate on cloud subdomain |

**Document root (choose one):**

- **Option A (recommended):** cPanel subdomain document root → `.../cloud-api/public`
- **Option B:** Subdomain root = deploy folder + root [`.htaccess`](.htaccess) routing to `cloud-api/public/index.php`

Replace placeholders:

| Placeholder | Example (Magnificent Solution layout) |
|-------------|----------------------------------------|
| `CLOUD_DOMAIN` | `laundrypro-cloudapi.magnificentsolution.co.in` |
| `CPANEL_USER` | your cPanel username |
| `DEPLOY_ROOT` | `/home/CPANEL_USER/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in` |
| `HTTP_DOCROOT` (Option A) | `{DEPLOY_ROOT}/cloud-api/public` |
| `DB_NAME` | `cpuser_laundrypro_cloud` |
| `DB_USER` | `cpuser_laundrypro` |

**Automation path map:** `scripts/cloud_deploy/DeployPaths.php` reads `remote_home`, `ftp_remote_path`, `deploy_layout`, and `http_docroot` from [`credentials.ini`](scripts/cloud_deploy/credentials.example.ini). For Magnificent Solution production:

| Key | Value |
|-----|--------|
| `deploy_layout` | `option_a` |
| `ftp_remote_path` / `remote_home` | `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in` |
| `http_docroot` | `{DEPLOY_ROOT}/cloud-api/public` |

Verify before/after FTP deploy:

```powershell
powershell -File scripts/cloud_deploy/verify_path_alignment.ps1
```

---

## 3. Upload layout (cPanel)

### Recommended: minimal zip

From your dev machine:

```powershell
.\scripts\build_cloud_cpanel.ps1
```

Upload `dist/cloud-cpanel-upload.zip` to `DEPLOY_ROOT`, extract. It contains:

- `cloud-api/` (including **`cloud-api/database/migrations/`** — required)
- `.htaccess`
- `deployment.md`

### If you upload the full git repo (Option B)

Allowed, but **not required**: `lib/`, `test/`, `windows/`, `pubspec.yaml` must **not** be relied on in production. Root `.htaccess` blocks direct web access to `api`, `lib`, `database`, etc.

**Do not upload** [`.archive/`](.archive/) to cPanel (legacy/local-only files).

**Required on server:**

| Path | Purpose |
|------|---------|
| `cloud-api/public/` | Front controller |
| `cloud-api/database/migrations/*.sql` | Schema (001, 002) |
| `cloud-api/scripts/deploy.php` | Deploy + migrate |
| `cloud-api/.env` | Secrets (see below) |

**Reference only (do not import into cloud DB via phpMyAdmin):**

- [`database/cloud/schema.sql`](database/cloud/schema.sql) — snapshot; must match migrations; use `deploy.php` instead.

---

## 4. Database (cPanel)

1. cPanel → **MySQL® Databases** → create `DB_NAME` and user `DB_USER` with **ALL PRIVILEGES**.
2. Host is almost always `localhost` (not `cloud-db`).

### Forbidden imports (cloud database)

Do **not** import in phpMyAdmin:

- `database/schema.sql`
- `database/local/schema.sql`
- `docs/audit/DB_SCHEMA_FINAL.sql`
- `api/database/migrations/*` (local POS migrations)
- Partial “seed” fragments from workstation docs

These create a local `settings` table and cause errors such as:

`#1062 - Duplicate entry 'inventory.allow_negative_stock-' for key 'uq_settings_key_scope'`

(that happens when `scope = 'inventory'` is used on an ENUM that does not include `inventory`).

---

## 5. Environment files

On the server:

```bash
cd DEPLOY_ROOT/cloud-api
cp .env.production.example .env
chmod 600 .env   # if your host allows
```

Minimum production keys (see [`cloud-api/.env.production.example`](cloud-api/.env.production.example)):

```ini
APP_DEBUG=false
APP_ENV=production
APP_URL=https://CLOUD_DOMAIN
DB_HOST=localhost
DB_PORT=3306
DB_NAME=DB_NAME
DB_USER=DB_USER
DB_PASS=<strong-random-password>
JWT_SECRET=<64+-char-random-hex>
LICENSE_MASTER_SECRET=<64+-char-random-secret>
CORS_ALLOWED_ORIGINS=https://CLOUD_DOMAIN
SESSION_DRIVER=file
SESSION_LIFETIME=120
```

Prefer **`cloud-api/.env`** over a repo-root `.env`. `deploy.php` can read a parent `.env`, but keeping secrets under `cloud-api/` avoids confusion.

---

## 6. URL rewriting (.htaccess)

Ensure these files exist after upload:

- [`DEPLOY_ROOT/.htaccess`](.htaccess) (Option B)
- [`cloud-api/.htaccess`](cloud-api/.htaccess)
- [`cloud-api/public/.htaccess`](cloud-api/public/.htaccess)

LiteSpeed generally honors Apache rewrite rules. Forward `Authorization` for JWT (included in repo rules).

---

## 7. Migrations and deploy engine

SSH or cPanel **Terminal**:

```bash
cd DEPLOY_ROOT/cloud-api
php scripts/deploy.php
```

This applies pending SQL from `cloud-api/database/migrations/`, verifies `logs/` and `storage/`, and ensures super-admin provisioning when missing.

**Manual fallback** (only if `deploy.php` cannot run): import **in order**, same database:

1. `cloud-api/database/migrations/001_cloud_initial_schema.sql`
2. `cloud-api/database/migrations/002_tenant_full_domain_schema.sql`

Then confirm `schema_migrations` lists both migrations.

---

## 8. Rebuild cloud database (drop all tables)

Use when the cloud DB was polluted with local POS tables or failed phpMyAdmin imports. **All cloud data will be lost.**

```bash
cd DEPLOY_ROOT/cloud-api
export REBUILD_CONFIRM=1
php scripts/deploy.php --fresh
```

Or:

```bash
export REBUILD_CONFIRM=1
bash scripts/rebuild_cloud_database.sh
```

Re-check [§10 Verification](#10-verification).

---

## 9. cPanel cron jobs

cPanel → **Cron Jobs** (use full path to PHP CLI from `which php`):

```cron
0 * * * * php DEPLOY_ROOT/cloud-api/scripts/clean_sessions.php >> DEPLOY_ROOT/cloud-api/logs/cron.log 2>&1
*/15 * * * * php DEPLOY_ROOT/cloud-api/scripts/sync_health_collector.php >> DEPLOY_ROOT/cloud-api/logs/cron.log 2>&1
```

Ensure `cloud-api/logs` and `cloud-api/storage` are writable by the PHP user (`755` typical).

---

## 10. Verification

| Check | URL |
|-------|-----|
| Health | `https://CLOUD_DOMAIN/api/v1/health` → `HEALTH_OK`, `database: ok` |
| API docs | `https://CLOUD_DOMAIN/api/v1/docs` |
| Super-admin | `https://CLOUD_DOMAIN/admin/login` |

Default super-admin may be seeded in migration `001` (`superadmin`) or created by `deploy.php` if missing — change password immediately after first login.

---

## 11. Connect Windows POS terminals

On each store workstation, in `api/.env` (see [`api/.env.production.template`](api/.env.production.template)):

```ini
CLOUD_API_URL=https://CLOUD_DOMAIN/api/v1
SYNC_INTERVAL_SECONDS=300
```

Register Windows tasks: `scripts/setup-task-scheduler.ps1` (sync every 5 minutes, backup daily).

Desktop app: build with cloud URL — see [`scripts/build_prod.ps1`](scripts/build_prod.ps1).

---

## 12. Automated cloud deploy (SSH or FTP+HTTP)

From a Windows dev machine with PHP CLI:

| Account | Purpose |
|---------|---------|
| `cloud-laudry-pro-ssh` | **Shell SSH** — `cloud_ssh_deploy.php` (when port 22 open) |
| `cloud-laudry-pro-admin@magnificentsolution.co.in` | **FTP port 21** — upload zip + download logs; **HTTPS** runs `apply_release` + `deploy.php --fresh` |

**FTP+HTTP (no SSH):** set matching secrets:

- Server `cloud-api/.env`: `DEPLOY_AUTOMATION_TOKEN=...`, `DEPLOY_HTTP_ENABLED=true`
- Local `scripts/cloud_deploy/credentials.ini`: `deploy_automation_token=...` (same value), `ftp_port=21`

Automation uploads `DEPLOY_AUTOMATION_TOKEN` / `DEPLOY_HTTP_ENABLED` via FTP before apply:

```powershell
php scripts/cloud_deploy/ftp_patch_server_env.php
.\scripts\cloud_deploy.ps1 -Transport Ftp
# or Auto (uses FTP when SSH test fails)
php scripts/cloud_ftp_deploy.php --dry-run
```

Endpoints (token header `X-LaundryPro-Deploy-Token`): `POST /api/v1/internal/deploy/apply`, `GET /api/v1/internal/deploy/logs`.

**One-time server (cPanel File Manager → `cloud-api/.env`):**

```ini
DEPLOY_AUTOMATION_TOKEN=<same value as deploy_automation_token in credentials.ini>
DEPLOY_HTTP_ENABLED=true
```

| HTTP result | Meaning | Fix |
|-------------|---------|-----|
| **401** JSON `UNAUTHORIZED` | Token missing/wrong on server | Add lines above to `cloud-api/.env` |
| **404** HTML or API `NOT_FOUND` | Routes not deployed yet | Automation FTP-uploads bootstrap; or **Extract** `deploy_staging/cloud-cpanel-upload.zip` at subdomain root, then re-run deploy |
| **200** JSON `HTTP_APPLY_OK` / `DEPLOY_APPLY_OK` | Fresh migrations ran | Check `/api/v1/health` → `database: ok` |

Bootstrap URL (docroot `cloud-api/public`): `https://<host>/lp_deploy_apply.php`. Option B (subdomain root + root `.htaccess`): `https://<host>/cloud-api/public/lp_deploy_apply.php`.

SSH path still uses **OpenSSH** or **Posh-SSH** (`Install-Module Posh-SSH -Scope CurrentUser`):

Generate local deploy keys (empty passphrase, gitignored at repo root):

```powershell
.\scripts\cloud_deploy.ps1 -GenerateKeys
```

Authorize the printed `.pub` in cPanel **SSH Access** for `cloud-laudry-pro-ssh`. Test SSH + FTP TCP/auth:

```powershell
.\scripts\cloud_deploy.ps1 -TestConnections
```

1. Copy [`scripts/cloud_deploy/credentials.example.ini`](scripts/cloud_deploy/credentials.example.ini) to gitignored `scripts/cloud_deploy/credentials.ini`, or rely on [`.ssh-credentials-details`](.ssh-credentials-details) (SSH block + optional `FTP` section).
2. Set `remote_home` to the **absolute** cPanel docroot, e.g. `/home/CPANEL_USER/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in` (not the account home alone).
3. Prefer `identity_file` pointing at your **private** OpenSSH key (not `.ppk`). Use an **unencrypted** key for OpenSSH `BatchMode`, or rely on password + Posh-SSH (encrypted keys auto-fallback when password is in `.ssh-credentials-details`).
4. Dry-run:

```powershell
.\scripts\cloud_deploy.ps1 -DryRun
```

5. Deploy (builds zip, uploads, applies on server):

```powershell
.\scripts\cloud_deploy.ps1
```

Equivalent: `php scripts/cloud_ssh_deploy.php` (`--dry-run`, `--skip-build`).

**Destructive:** server [`apply_release.php`](cloud-api/scripts/automation/apply_release.php) always runs `REBUILD_CONFIRM=1` + [`deploy.php --fresh`](cloud-api/scripts/deploy.php) — **all cloud DB tables are dropped** on every automated deploy. Prunes stray top-level files (`lib/`, `pubspec.yaml`, etc.) per [`manifest.cloud.json`](cloud-api/scripts/automation/manifest.cloud.json). Preserves `cloud-api/.env` and `cloud-api/logs` / `storage` data when present.

---

## 13. Troubleshooting

| Symptom | Fix |
|---------|-----|
| DB connection failed | `DB_HOST=localhost`; verify cPanel user privileges |
| 404 on `/api/v1/health` | Enable rewrite; confirm document root or root `.htaccess` |
| 401 on sync | Clock skew, JWT secret mismatch, or expired license |
| Cron silent | Check `cloud-api/logs/cron.log`; PHP path in cron command |
| SSH `connection refused` on deploy | `.\scripts\cloud_deploy.ps1 -Transport Ftp`; `ftp_port=21` |
| HTTP deploy `401` | `DEPLOY_AUTOMATION_TOKEN` in server `cloud-api/.env` must match `deploy_automation_token` in `credentials.ini` |
| HTTP deploy `404` | Extract zip in cPanel or let bootstrap upload `.htaccess` + `lp_deploy_apply.php` |
| Bootstrap `404` but `/api/v1/health` works | **Docroot mismatch:** cPanel → Domains → document root must be `{DEPLOY_ROOT}/cloud-api/public`, and `ftp_remote_path` / `remote_home` must be `{DEPLOY_ROOT}` (not the `public` folder). FTP files in the wrong tree never run over HTTP. |
| FTP `553` on `.htaccess` / `index.php` | Upload as `rewrite_rules.txt` then rename (automation does this); some hosts block overwriting `index.php` via FTP — use File Manager extract once. |
| `#1062` / `inventory.allow_negative_stock` on import | Wrong SQL file (local schema on cloud DB); rebuild per [§8](#8-rebuild-cloud-database-drop-all-tables) |
| `Missing SQL migrations` from deploy | Upload `cloud-api/database/migrations/` (001 + 002) |
| `deploy.php --fresh` refused | Set `REBUILD_CONFIRM=1` |

Docker-based guides in [`docs/operations/DEPLOYMENT_GUIDE.md`](docs/operations/DEPLOYMENT_GUIDE.md) §2.2 are **legacy optional** — not used for this cPanel production pack.
