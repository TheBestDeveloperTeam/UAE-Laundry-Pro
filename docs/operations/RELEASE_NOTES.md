# LaundryPro UAE — Release Notes

## Re-audit closure R2 (2026-10-15)

| Check | Result |
|-------|--------|
| `verify_route_parity.php` | Pass (32/35 + intentional local-only domains) |
| `cloud_route_registry_test.php` | Pass |
| `cloud_core_test.php` | 11/11 |
| `flutter test` | 120 passed |
| CI backend job | Extended (OpenAPI smoke, cloud tests, deploy smoke) |
| Live `cloud_live_smoke.ps1` | Health/OpenAPI 200; deploy/bootstrap 404 until cPanel zip extract |

See [POST_UAT_REAUDIT_2026-10.md](../audit/POST_UAT_REAUDIT_2026-10.md) §R2 and [PRODUCTION_CLOSEOUT.md](../audit/PRODUCTION_CLOSEOUT.md) R2 addendum.

## Production Pack Baseline (2026-10-12)

Quality gate snapshot recorded during Production Pack v2.0 implementation.

| Check | Result | Notes |
|-------|--------|-------|
| PHP API tests (`api/tests/run_api_tests.php`) | **190 passed**, 0 failed, 7 skipped | PHP: `E:\xampp\php\php.exe` |
| `flutter analyze` | **No issues found** | Repo root |
| `flutter test` | **119 passed** | Repo root |
| Route parity (`scripts/verify_route_parity.php`) | **33/35 domains** (100% domain parity) | Cloud routes: 184 |

Skipped API cases: optional cloud tenant tests when cloud URL unreachable; install lock state.

---

## Version alignment

- Flutter/desktop: `pubspec.yaml` → `version: 1.2.1+4`
- Local API template: `api/.env.example` → `APP_VERSION=1.2.1`
