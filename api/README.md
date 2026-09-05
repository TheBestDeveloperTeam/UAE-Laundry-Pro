# LaundryPro API (Plain PHP)

## Requirements
- PHP 8.2+ with `pdo_mysql`, `openssl`, `mbstring`, `json`, `zip`
- MySQL/MariaDB

## Quick Start

1. Copy environment file:
   ```powershell
   copy api\.env.example api\.env
   ```

2. Create Apache junction (Admin PowerShell):
   ```powershell
   mklink /J E:\xampp\htdocs\laundrypro-api E:\Projects\Flutter\UAE-Laundry-Pro\api
   ```

3. Set routing base path in `api/.env`:
   ```env
   APP_BASE_PATH=/laundrypro-api/public
   ```
   If junction points to `api/public` instead, use:
   ```env
   APP_BASE_PATH=/laundrypro-api
   ```

4. Run migrations:
   ```powershell
   powershell scripts\migrate.ps1
   ```

5. Verify health (full path required):
   ```
   http://localhost/laundrypro-api/public/api/v1/health
   ```

6. Default dev credentials: `admin` / `admin123`

## API Documentation

- Bundled Swagger UI: `http://localhost/laundrypro-api/public/docs/`
- Live OpenAPI JSON: `http://localhost/laundrypro-api/public/api/v1/docs/openapi.json`

Spec is generated from route metadata in `routes/api.php` — no manual `openapi.yaml` sync required.

## Install (cPanel / no terminal)

Set `INSTALL_SECRET` in `.env`, then:

1. `GET /api/v1/install/status`
2. `POST /api/v1/install/migrate` — header `X-Install-Token: <INSTALL_SECRET>`
3. `POST /api/v1/install/seed` — body `{ "admin_password": "..." }`
4. `POST /api/v1/install/complete` — locks installer (`storage/installed.lock`)

## Testing

```powershell
powershell scripts\api-test.ps1
powershell scripts\quality-gate.ps1
```

Declarative cases: `api/tests/cases/*.json`. See `api/docs/QUALITY_GATE.md`.

## URL Patterns

| Deployment | Health URL | `APP_BASE_PATH` |
|------------|------------|-----------------|
| Junction to `api/` (default) | `http://localhost/laundrypro-api/public/api/v1/health` | `/laundrypro-api/public` |
| Junction to `api/public/` | `http://localhost/laundrypro-api/api/v1/health` | `/laundrypro-api` |
| PHP built-in server | `http://localhost:8090/api/v1/health` | empty |

Note: `/api/v1` alone is not a route. Use `/api/v1/health`, `/api/v1/auth/login`, etc.

## Built-in PHP Server (alternative to XAMPP)

```powershell
cd api
E:\xampp\php\php.exe -S localhost:8090 -t public
```

Then set Flutter `API_BASE_URL` to `http://localhost:8090/api/v1`.

## Structure

- `public/index.php` — front controller
- `src/Core` — router, request/response, container, path resolver
- `src/Security` — JWT + password hashing (no external libs)
- `database/migrations` — SQL migrations
- `docs/openapi.yaml` — API contract

## Troubleshooting

If health returns `NOT_FOUND` with `resolved_path` in debug meta:
1. Confirm `APP_BASE_PATH` matches your Apache URL prefix
2. Ensure `mod_rewrite` is enabled and `.htaccess` is allowed
3. Run `php api/tests/routing_test.php`
