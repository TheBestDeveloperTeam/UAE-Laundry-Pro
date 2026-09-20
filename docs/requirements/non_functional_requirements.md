# Non-Functional Requirements - LaundryPro UAE
> **Version:** 1.0.0

## Performance
- NFR-PERF-001: API response time < 500ms at P95.
- NFR-PERF-002: Page load time < 2 seconds for all screens.
- NFR-PERF-003: Database query execution < 100ms at P95.
- NFR-PERF-004: Order processing (POS) < 30 seconds end-to-end.
- NFR-PERF-005: Print job queuing < 2 seconds.
- NFR-PERF-006: Sync outbox flush < 30 seconds after connectivity restoration.

## Reliability
- NFR-REL-001: System shall operate continuously for 30+ days without internet.
- NFR-REL-002: Zero data loss during offline/online transitions.
- NFR-REL-003: Automatic recovery from hardware disconnection.
- NFR-REL-004: Database backup with SHA-256 integrity verification.

## Security
- NFR-SEC-001: All API endpoints authenticated via JWT.
- NFR-SEC-002: RBAC enforced server-side on all routes.
- NFR-SEC-003: All user input sanitized (SQL injection, XSS prevention).
- NFR-SEC-004: PII encrypted at rest.
- NFR-SEC-005: Machine-bound licensing (UMAC) prevents unauthorized use.
- NFR-SEC-006: Audit trail tamper-evident with hash chaining.

## Usability
- NFR-USE-001: Full LTR (English) and RTL (Arabic) support.
- NFR-USE-002: WCAG 2.1 AA accessibility compliance.
- NFR-USE-003: Keyboard navigation for all screens.
- NFR-USE-004: Font scaling support (100%-200%).

## Scalability
- NFR-SCA-001: Support up to 10 concurrent users per branch.
- NFR-SCA-002: Support up to 50 branches per business owner.
- NFR-SCA-003: Support up to 100,000 orders per branch per year.
- NFR-SCA-004: Support up to 500 inventory items per branch.