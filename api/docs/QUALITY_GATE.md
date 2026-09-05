# Quality Gate

Definition of Done for API platform features.

## Automated checks

Run from repo root:

```powershell
powershell scripts\quality-gate.ps1
```

Order (fail-fast):

1. `php-lint.ps1` — PHP syntax on all `api/` sources
2. `api/tests/autoload_test.php`
3. `api/tests/routing_test.php`
4. `api/tests/jwt_test.php`
5. `api/tests/run_api_tests.php` — declarative HTTP cases in `api/tests/cases/`
6. `api-smoke.ps1` — Apache integration smoke
7. `flutter analyze` + `flutter test`
8. `api/tests/openapi_drift_test.php` — route metadata count matches router

## Feature checklist

- Every new route in `api/routes/api.php` includes metadata (`tag`, `summary`, `responses`)
- Route appears in live Swagger: `GET /api/v1/docs/openapi.json`
- Bundled Swagger UI: `/docs/` (static assets under `api/public/docs/`)
- Test case added under `api/tests/cases/` for happy path + key error codes
- No hardcoded secrets in code, logs, or OpenAPI spec
- `INSTALL_SECRET` set in production `.env` and rotated after first install
- Install mutate endpoints locked after `POST /install/complete` (`storage/installed.lock`)
- Settings writes and install actions audited
- New Flutter strings in both `assets/i18n/en.json` and `assets/i18n/ar.json`

## Install workflow (cPanel)

1. Upload `api/`, create MySQL DB, edit `api/.env` (DB + `INSTALL_SECRET`)
2. `GET /install/status` — confirm `db_connected: true`
3. `POST /install/migrate` with `X-Install-Token`
4. `POST /install/seed` with `{ "admin_password": "..." }`
5. `POST /install/complete` — locks installer
6. `GET /health` — verify

## Test environment

- `API_TEST_BASE_URL` — defaults to `http://localhost/laundrypro-api/public/api/v1`
- Use a separate test database for CI; never point tests at production DB
