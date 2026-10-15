# Post-UAT re-audit snapshot — 2026-10-15

Measured on developer workstation (`E:\Projects\Flutter\UAE-Laundry-Pro`). Supersedes stale “100%” claims where this report disagrees.

## Automated gates

| Gate | Command | Result |
|------|---------|--------|
| PHP syntax | `php -l scripts/export_swagger.php` | Pass |
| Cloud route parity | `php scripts/verify_route_parity.php` | 187 routes; LAN/install hardware false positives fixed; **32/35** domains with route matches |
| OpenAPI registry | `php api/tests/openapi_drift_test.php` | Pass (179 local routes) |
| API integration | `php api/tests/run_api_tests.php` | **190 passed**, 0 failed, 7 skipped |
| Deploy smoke | `php api/tests/deploy_automation_smoke_test.php` | Pass |
| Flutter tests | `flutter test` | **119 passed** |
| Swagger export | `php scripts/export_swagger.php` | Local 144 paths; cloud 159 paths; unified 303 paths |

## Logs (static review)

| Area | Finding |
|------|---------|
| Local `Logger.php` | Daily rotation documented in C14; unchanged this pass |
| Cloud deploy | `ReleaseAutomation` captures apply output; FTP downloads `cloud-api/logs/*.log` |
| FTP deploy stderr | 401 = token; 404 HTML = routing/docroot; automation now runs `ftp_patch_server_env.php` before POST |

## Cloud UAT (live)

| Step | Result |
|------|--------|
| Path map (`DeployPaths` + `credentials.ini`) | Pass — `option_a`, `DEPLOY_ROOT` and `http_docroot` aligned in automation |
| `verify_path_alignment.ps1` | Pass config; `GET /api/v1/health` **200**; bootstrap URL **404** |
| FTP zip upload | Pass → `deploy_staging/cloud-cpanel-upload.zip` |
| FTP `cloud-api/.env` token (`ftp_patch_server_env.php`) | **Fail** — no `.env` to download; `env_patch.txt` upload **553** (host blocks or `cloud-api/` missing) |
| `POST /api/v1/internal/deploy/apply` | **404** JSON `NOT_FOUND` (internal deploy routes not on live build) |
| Bootstrap `lp_deploy_apply.php` (Option A URL) | **404** HTML after FTP upload to `cloud-api/public/` |
| `GET /api/v1/internal/deploy/logs` | **404** JSON `NOT_FOUND` |
| `GET /api/v1/health` | Pass (`database: ok`) on **existing** deployment |
| Legacy `GET /cloud-api/public/api/v1/health` | **200** (suggests HTTP still routed via subdomain root / Option B, not docroot-only `public/`) |

**Blocker (unchanged until cPanel + extract):** Set subdomain document root to `{DEPLOY_ROOT}/cloud-api/public` (confirmed target path in `credentials.ini`), **extract** `deploy_staging/cloud-cpanel-upload.zip` at `DEPLOY_ROOT` if apply cannot run, ensure `cloud-api/.env` has `DEPLOY_AUTOMATION_TOKEN` + `DEPLOY_HTTP_ENABLED=true`. Until `lp_deploy_apply.php` is reachable at `/lp_deploy_apply.php`, automated fresh deploy cannot complete over FTP+HTTP.

## Schema parity

| Migration | Local | Cloud |
|-----------|-------|-------|
| 003 inventory settings | `api/database/migrations/003_settings_scope_inventory.sql` | `cloud-api/database/migrations/003_tenant_settings_inventory_defaults.sql` |

## Doc / audit reconciliation

| Topic | Resolution |
|-------|------------|
| AUDIT_TESTING G-031–033 | Still open for full E2E UI + PHPUnit + k6; CI covers drift + integration + Flutter |
| C15 “100%” | Use this file for Oct 2026 measured state |
| OpenAPI live URL | `export_swagger.php` server → `laundrypro-cloudapi.magnificentsolution.co.in` |

## Next actions (when back)

1. cPanel → Domains: document root = `/home/ihgzplwh/public_html/web/laundrypro-cloudapi.magnificentsolution.co.in/cloud-api/public`.
2. File Manager: extract `deploy_staging/cloud-cpanel-upload.zip` at `DEPLOY_ROOT`; create/patch `cloud-api/.env` if FTP patch keeps failing.
3. `powershell -File scripts/cloud_deploy/verify_path_alignment.ps1` — expect bootstrap **200** or apply route **2xx**, not **404**.
4. `.\scripts\cloud_deploy.ps1 -Transport Ftp` (destructive `--fresh`).
5. Confirm `POST .../internal/deploy/apply` returns JSON success; re-run health + migrations 001–003.

---

## R2 — Full-stack re-audit execution (2026-10-15 PM)

**Git:** `main` after `e0edbbd` (deploy automation + Lottie); closure fixes pending push.

### Code gates (workstation)

| Gate | Command | Result |
|------|---------|--------|
| Cloud domain parity | `verify_route_parity.php` | **Pass** — 32/35 covered; Install/RFID/LAN intentional |
| Cloud route registry | `cloud-api/tests/cloud_route_registry_test.php` | **Pass** — 187 routes, deploy paths in OpenAPI |
| Cloud core | `cloud_core_test.php` | **Pass** — 11/11 |
| Cloud domain integration | `cloud_domain_parity_test.php` | **Skip** without MySQL; **Pass** when DB up (`LAUNDRYPRO_REQUIRE_DB=1`) |
| OpenAPI local drift | `openapi_drift_test.php` | **Pass** — 179 routes |
| Deploy smoke | `deploy_automation_smoke_test.php` | **Pass** |
| Flutter | `flutter test` | **120 passed** |
| Local API HTTP suite | `run_api_tests.php` | **Skip** if `http://localhost/laundrypro-api/...` down (long timeout otherwise) |

**CI (`.github/workflows/ci.yml`):** backend job now runs export smoke, cloud core/registry, deploy smoke, domain parity (skips without DB on GA).

### Live cloud UAT (re-run)

| Check | Result |
|-------|--------|
| `verify_path_alignment.ps1` | Config OK; `health_canonical` **200** |
| `cloud_live_smoke.ps1` | `health` **200**, `openapi` **200**; `deploy/status` **404**; `lp_deploy_apply.php` **404** |
| `cloud_ftp_deploy.php` | Zip uploaded to `deploy_staging/`; `.env` patch **553**; apply **404**; bootstrap uploaded to FTP `cloud-api/public/` but HTTP still **404** |

**Verdict:** Application **code + automated gates certified**. **Live deploy automation not certified** until cPanel extracts `deploy_staging/cloud-cpanel-upload.zip` at `DEPLOY_ROOT` and `cloud-api/.env` exists with `DEPLOY_AUTOMATION_TOKEN` + `DEPLOY_HTTP_ENABLED=true`. Re-run `scripts/cloud_deploy/cloud_live_smoke.ps1` after extract.

**Waivers (unchanged):** G-031 E2E UI, G-032 PHPUnit, G-033 k6 — post-go-live enhancements.
