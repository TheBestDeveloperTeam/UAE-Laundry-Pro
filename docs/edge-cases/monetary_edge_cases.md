# Edge Cases: monetary - LaundryPro UAE
> **Version:** 1.0.0

## Scenarios
Zero amount orders, maximum DECIMAL(18,2) value (9999999999999999.99), negative discount validation, VAT rounding (round half-up to 2 decimal places), split payment that doesn't sum to total, currency conversion edge at AED boundaries.

## Testing Strategy
- Each scenario has a corresponding test case in the edge case test suite.
- Edge Case Hunter agent is responsible for discovering new edge cases.
- All edge cases are validated during regression testing.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial edge case catalog |