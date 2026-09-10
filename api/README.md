# LaundryPro UAE — Local PHP API

**Version:** 1.2.1 | **Runtime:** PHP 8.2 | **Database:** MariaDB/MySQL

A zero-dependency PHP 8.2 micro-framework powering the LaundryPro UAE offline-first POS/ERP backend. Designed for raw speed, minimal memory footprint, and reliable execution on Windows edge terminals running XAMPP.

---

## Requirements

| Requirement | Minimum Version |
|---|---|
| PHP | 8.2+ |
| MariaDB / MySQL | 10.6+ |
| PHP Extensions | `pdo_mysql`, `openssl`, `mbstring`, `json`, `zip`, `bcmath` |

> **Important:** `bcmath` is required for all monetary arithmetic. Ensure it is enabled in `php.ini` — uncomment `extension=bcmath` and restart Apache.

---

## Quick Start (XAMPP / Windows)

### 1. Configure Environment

```powershell
copy api\.env.example api\.env
```

Edit `api\.env` with your database credentials and file paths.

### 2. Create Apache Junction (run as Administrator)

```powershell
mklink /J E:\xampp\htdocs\laundrypro-api E:\Projects\Flutter\UAE-Laundry-Pro\api
```

### 3. Set Base Path in `.env`

```env
APP_BASE_PATH=/laundrypro-api/public
```

### 4. Run Migrations & Seeds

```powershell
powershell scripts\dev.ps1 migrate
powershell scripts\dev.ps1 seed
```

### 5. Verify Health

```
GET http://localhost/laundrypro-api/public/api/v1/health
```

Expected:
```json
{ "success": true, "code": "HEALTH_OK", "data": { "version": "1.2.1", "db": "connected" } }
```

### 6. Default Credentials

| Role | Username | Password |
|---|---|---|
| Admin | `admin` | `admin123` |
| Cashier | `cashier` | `cashier123` |

> **Change these immediately after first login in any production environment.**

---

## Environment Variables Reference

| Key | Default | Description |
|---|---|---|
| `APP_ENV` | `local` | Environment (`local`, `production`) |
| `APP_DEBUG` | `false` | Never `true` in production |
| `APP_BASE_PATH` | _(empty)_ | Apache URL prefix |
| `APP_VERSION` | `1.2.1` | Application version |
| `DB_HOST` | `127.0.0.1` | Database host |
| `DB_PORT` | `3306` | Database port |
| `DB_NAME` | `laundrypro` | Database name |
| `DB_USER` | `root` | Database user |
| `DB_PASS` | _(empty)_ | Database password |
| `JWT_SECRET` | _(required)_ | JWT signing secret (min 32 chars) |
| `JWT_ACCESS_TTL` | `900` | Access token TTL seconds (15 min) |
| `JWT_REFRESH_TTL` | `604800` | Refresh token TTL seconds (7 days) |
| `BACKUP_PATH` | `C:/LaundryPro/backups/` | Database backup ZIP directory |
| `INVOICE_PATH` | `C:/LaundryPro/invoices/` | Invoice PDF directory |
| `LOG_PATH` | `C:/LaundryPro/logs/` | Application log directory |
| `EXPORT_PATH` | `C:/LaundryPro/exports/` | Report export directory |
| `CORS_ALLOWED_ORIGINS` | `http://localhost` | Comma-separated CORS origins |
| `INSTALL_SECRET` | _(optional)_ | Token for headless HTTP installation |
| `CLOUD_API_URL` | _(optional)_ | Central cloud sync endpoint |
| `CLOUD_API_TOKEN` | _(optional)_ | Bearer token for cloud auth |

---

## Headless Installation (cPanel / No Terminal)

Set `INSTALL_SECRET` in `.env`, then call in order:

```
1. GET  /api/v1/install/status
2. POST /api/v1/install/migrate   (Header: X-Install-Token: <INSTALL_SECRET>)
3. POST /api/v1/install/seed      (Body: { "admin_password": "..." })
4. POST /api/v1/install/complete  (Locks installer via storage/installed.lock)
```

---

## API Documentation

- **Swagger UI:** `http://localhost/laundrypro-api/public/docs/`
- **OpenAPI JSON:** `http://localhost/laundrypro-api/public/api/v1/docs/openapi.json`

---

## Alternative: PHP Built-in Server

```powershell
E:\xampp\php\php.exe -S localhost:8090 -t api\public
```

Set Flutter `API_BASE_URL` to `http://localhost:8090/api/v1`.

---

## Testing

```powershell
powershell scripts\api-test.ps1
powershell scripts\dev.ps1 gate
```

| Suite | Pass | Skip |
|---|---|---|
| API test suite | 173 | 9 |
| Flutter tests | 116 | 0 |
| OpenAPI routes | 148 | — |

---

## Project Structure

```
api/
+-- public/index.php           # Front controller
+-- src/Controllers/           # HTTP handlers — no business logic
+-- src/Services/              # Business logic
+-- src/Repositories/          # PDO data access (only layer touching the DB)
+-- src/Middleware/            # AuthMiddleware, CorsMiddleware, RateLimitMiddleware
+-- src/Security/              # JwtService, PasswordHasher, PermissionChecker, UmacService
+-- src/Core/                  # Application, Router, Container, Request, Env
+-- src/Helpers/               # ApiResponse, Logger
+-- config/                    # app.php, database.php, security.php
+-- database/migrations/       # SQL migration files
+-- storage/                   # Logs, installed.lock
```

---

## URL Reference

| Deployment | Health URL | `APP_BASE_PATH` |
|---|---|---|
| Junction to `api/` | `http://localhost/laundrypro-api/public/api/v1/health` | `/laundrypro-api/public` |
| Junction to `api/public/` | `http://localhost/laundrypro-api/api/v1/health` | `/laundrypro-api` |
| PHP built-in server | `http://localhost:8090/api/v1/health` | _(empty)_ |

---

## Troubleshooting

**`NOT_FOUND` with `resolved_path` in response:**
- Confirm `APP_BASE_PATH` matches your Apache URL prefix.
- Enable `mod_rewrite` and allow `.htaccess`.

**`bcmath` function undefined:**
- Open `E:\xampp\php\php.ini`, uncomment `extension=bcmath`, restart Apache.

**JWT `invalid signature`:**
- Ensure `JWT_SECRET` is identical across all terminals sharing the same database.
