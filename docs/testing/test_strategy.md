# Test Strategy - LaundryPro UAE
> **Version:** 1.0.0

## Test Pyramid
1. **Unit Tests** (base): Individual functions, methods, widgets. Target: 80% coverage.
2. **Integration Tests** (middle): API endpoints, database queries, cross-module flows.
3. **E2E Tests** (top): Full user workflows through the UI.

## Test Frameworks
| Layer | Flutter | PHP |
|-------|---------|-----|
| Unit | flutter_test | PHPUnit |
| Widget | testWidgets, golden | N/A |
| Integration | integration_test | PHPUnit + HTTP client |
| E2E | integration_test (driver) | N/A |

## Quality Gates (must pass before release)
- Unit test pass rate: 100%
- Integration test pass rate: 100%
- Code coverage: >= 80%
- Zero CRITICAL bot alerts
- Regression suite: 100% pass
- Security test: 100% pass
- Accessibility: WCAG 2.1 AA compliant