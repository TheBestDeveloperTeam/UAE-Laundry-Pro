# Edge Cases: offline - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
30+ days offline operation, sync outbox with 10,000+ entries, conflict resolution when both local and cloud modified same record, internet drops mid-sync, sync resumes after partial push, dead-letter queue processing.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |