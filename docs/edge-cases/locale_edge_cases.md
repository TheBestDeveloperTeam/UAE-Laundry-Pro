# Edge Cases: locale - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
Switch locale mid-transaction (EN to AR), Arabic text in English fields, mixed LTR/RTL in same string (e.g., Arabic name with English product code), right-to-left numbers in invoice, very long Arabic text overflow.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |