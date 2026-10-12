# LaundryPro UAE — Release Notes

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
