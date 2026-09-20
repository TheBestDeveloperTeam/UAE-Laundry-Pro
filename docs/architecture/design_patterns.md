# Design Patterns - LaundryPro UAE
> **Version:** 1.0.0

## Architectural Patterns
| Pattern | Where Used | Description |
|---------|-----------|-------------|
| MVVM | Flutter frontend | Model-View-ViewModel with Riverpod |
| Clean Architecture | PHP backend | Controller -> Service -> Repository layers |
| Repository Pattern | PHP + Flutter | Abstract data access behind interfaces |
| Adapter Pattern | Hardware layer | Generic interfaces for all hardware |
| Offline-First | System-wide | Local-first with sync outbox |
| Sync Outbox | Sync engine | Append-only queue for offline writes |

## Design Patterns
| Pattern | Where Used | Description |
|---------|-----------|-------------|
| Factory Pattern | DTOs, Models | fromJson/toJson data transformation |
| Observer Pattern | Riverpod | Reactive state management |
| Middleware Pattern | PHP API | Request pipeline (auth, RBAC, idempotency) |
| Strategy Pattern | Pricing | Different pricing strategies (per-item, per-kg) |
| Template Method | Reports | Common report structure with variable content |
| Singleton Pattern | Database | Single DB connection per request |

## Anti-Patterns Explicitly Forbidden
| Anti-Pattern | Why Forbidden | Guard |
|-------------|---------------|-------|
| Floating-point money | Precision loss | money_precision_guard bot |
| God Object | Maintainability | Clean Architecture enforcement |
| N+1 Queries | Performance | Performance agent review |
| Raw SQL in controllers | Testability | Repository Pattern enforcement |
| Client-only auth | Security | rbac_enforcer bot |