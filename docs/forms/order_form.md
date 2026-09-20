# Form: order form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Order form: customer_id (required, FK), branch_id (required, FK), service_type (required, enum), turnaround (required, enum: express/same-day/next-day/standard), notes (optional, text, max 500 chars). Items: service_id (required, FK), quantity (required, int > 0), unit_price (auto-filled, DECIMAL), discount (optional, DECIMAL 0-100%).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |