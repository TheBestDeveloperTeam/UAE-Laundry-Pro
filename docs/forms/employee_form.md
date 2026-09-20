# Form: employee form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Employee form: name (required, varchar 100), phone (required, varchar 20), email (optional), role_id (required, FK), branch_id (required, FK), hire_date (required, date), salary (required, DECIMAL(18,2) > 0), passport_number (required, varchar 20), emirates_id (required, varchar 18).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |