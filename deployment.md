# LaundryPro UAE — cPanel Production Deployment (canonical)

> **Stack:** PHP 8.2 + Apache/LiteSpeed + MariaDB — **no Docker, Node, or Composer required**  
> **Also published as:** [docs/operations/DEPLOYMENT_CPANEL.md](docs/operations/DEPLOYMENT_CPANEL.md)

---

## Security notice

- **Never commit** `.env`, `.env.production`, or real passwords to git.
- If credentials ever appeared in documentation or chat logs, **rotate** database passwords, `JWT_SECRET`, `LICENSE_MASTER_SECRET`, and super-admin passwords on the server immediately.
- Use explicit `CORS_ALLOWED_ORIGINS` in production (not `*`).

---

## Table of contents

1. [Prerequisites](#1-prerequisites)
2. [Database (cPanel)](#2-database-cpanel)
3. [Environment files](#3-environment-files)
4. [URL rewriting (.htaccess)](#4-url-rewriting-htaccess)
5. [Migrations & deploy engine](#5-migrations--deploy-engine)
6. [cPanel cron jobs](#6-cpanel-cron-jobs)
7. [Verification](#7-verification)
8. [Connect Windows POS terminals](#8-connect-windows-pos-terminals)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

| Item | Requirement |
|------|-------------|
| Hosting | cPanel shared or reseller with PHP 8.2+ |
| Web server | Apache or LiteSpeed with `mod_rewrite` |
| Database | MariaDB / MySQL 10.4+ |
| TLS | Valid certificate on cloud subdomain |

**Document root (choose one):**

- **Option A (recommended):** cPanel subdomain document root → `.../cloud-api/public`
- **Option B:** Parent folder + root `.htaccess` routing to `cloud-api/public/index.php` (see repo [`.htaccess`](.htaccess))

Replace placeholders below:

| Placeholder | Example |
|-------------|---------|
| `CLOUD_DOMAIN` | `laundrypro-cloudapi.example.com` |
| `CPANEL_USER` | `your_cpanel_user` |
| `DEPLOY_ROOT` | `/home/CPANEL_USER/public_html/CLOUD_DOMAIN` |
| `DB_NAME` | `cpuser_laundrypro` |
| `DB_USER` | `cpuser_laundrypro` |

---

## 2. Database (cPanel)

1. cPanel → **MySQL® Databases** → create `DB_NAME` and user `DB_USER` with **ALL PRIVILEGES**.
2. Note host is almost always `localhost` (not `cloud-db` — that name is for legacy container docs only).

---

## 3. Environment files

On the server:

```bash
cd DEPLOY_ROOT/cloud-api
cp .env.production.example .env
# Edit .env with production values (chmod 600 if your host allows)
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

`deploy.php` also accepts `DB_DATABASE` / `DB_USERNAME` / `DB_PASSWORD` aliases.

---

## 4. URL rewriting (.htaccess)

Ensure repo files are present:

- [`DEPLOY_ROOT/.htaccess`](.htaccess) (Option B)
- [`cloud-api/.htaccess`](cloud-api/.htaccess)
- [`cloud-api/public/.htaccess`](cloud-api/public/.htaccess)

LiteSpeed generally honors Apache rewrite rules. Forward `Authorization` for JWT (included in repo rules).

---

## 5. Migrations & deploy engine

SSH or cPanel Terminal:

```bash
cd DEPLOY_ROOT/cloud-api
php scripts/deploy.php
```

This runs pending SQL migrations, verifies `logs/` and `storage/`, and ensures super-admin provisioning logic runs.

**Manual fallback:** import in order:

- `cloud-api/database/migrations/001_cloud_initial_schema.sql`
- `cloud-api/database/migrations/002_tenant_full_domain_schema.sql`

Super-admin is created by `deploy.php` when configured; otherwise set password via admin UI after first login with a one-time bootstrap procedure your ops team controls.

---

## 6. cPanel cron jobs

cPanel → **Cron Jobs** (use full path to PHP CLI from `which php`):

```cron
0 * * * * php DEPLOY_ROOT/cloud-api/scripts/clean_sessions.php >> DEPLOY_ROOT/cloud-api/logs/cron.log 2>&1
*/15 * * * * php DEPLOY_ROOT/cloud-api/scripts/sync_health_collector.php >> DEPLOY_ROOT/cloud-api/logs/cron.log 2>&1
```

Ensure `cloud-api/logs` and `cloud-api/storage` are writable by the web/PHP user (`chmod 755` or host default).

---

## 7. Verification

| Check | URL |
|-------|-----|
| Health | `https://CLOUD_DOMAIN/api/v1/health` → `HEALTH_OK`, `database: connected` |
| API docs | `https://CLOUD_DOMAIN/api/v1/docs` |
| Super-admin | `https://CLOUD_DOMAIN/admin/login` |

**Headers (optional smoke):** confirm HTTPS redirect, `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options` if enabled in server config.

---

## 8. Connect Windows POS terminals

On each store workstation, in `api/.env` (see [`api/.env.production.template`](api/.env.production.template)):

```ini
CLOUD_API_URL=https://CLOUD_DOMAIN/api/v1
SYNC_INTERVAL_SECONDS=300
```

Register Windows tasks: `scripts/setup-task-scheduler.ps1` (sync every 5 minutes, backup daily).

Desktop app: build with cloud URL — see [`scripts/build_prod.ps1`](scripts/build_prod.ps1).

---

## 9. Troubleshooting

| Symptom | Fix |
|---------|-----|
| DB connection failed | `DB_HOST=localhost`; verify cPanel user privileges |
| 404 on `/api/v1/health` | Enable rewrite; confirm document root or root `.htaccess` |
| 401 on sync | Clock skew, JWT secret mismatch, or expired license |
| Cron silent | Check `cloud-api/logs/cron.log`; PHP path in cron command |

Docker-based guides in [`docs/operations/DEPLOYMENT_GUIDE.md`](docs/operations/DEPLOYMENT_GUIDE.md) §2.2 are **legacy optional** — not used for this cPanel production pack.
