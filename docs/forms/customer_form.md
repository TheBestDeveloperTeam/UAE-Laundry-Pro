# Form: customer form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Customer form: name (required, varchar 100), phone (required, varchar 20, UAE format +971XXXXXXXXX), email (optional, valid email format), address (optional, text), type (required, enum: individual/corporate), trn (required if corporate, 15-digit TRN format).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |