# Form: payment form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Payment form: invoice_id (required, FK), amount (required, DECIMAL > 0), method (required, enum: cash/card/bank_transfer), reference_number (required if card/bank, varchar 50), notes (optional, text).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |