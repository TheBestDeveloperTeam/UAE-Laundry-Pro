# Protocol: Code Review

## Steps
1. Author submits code change with description and affected files.
2. ORCHESTRATOR routes to appropriate department lead.
3. Department lead assigns reviewer (peer specialist or lead).
4. Reviewer checks against:
   - Architecture compliance (Clean Architecture, MVVM)
   - Security (RBAC, SQL injection, XSS)
   - Data integrity (DECIMAL precision, tenant isolation)
   - Localization (locale keys, RTL support)
   - Testing (unit tests, integration tests)
5. Bot sweep runs (all 10 bots validate the change).
6. If any CRITICAL bot alert: review blocked until resolved.
7. Reviewer approves or requests changes.
8. On approval: change is merged and logged.

## Quality Gates
- [ ] Architecture compliance verified
- [ ] Security review passed
- [ ] Bot sweep clean (zero CRITICAL)
- [ ] Tests pass
- [ ] Localization verified (en + ar keys)

## SLA
- Review turnaround: within 1 prompt-turn of submission.