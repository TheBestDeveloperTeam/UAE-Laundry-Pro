# Form: invoice form - LaundryPro UAE
> **Version:** 1.0.0

## Specification
Invoice form: order_id (required, FK), customer_id (required, FK), subtotal (auto-calculated, DECIMAL), discount_amount (auto-calculated, DECIMAL), vat_amount (auto-calculated, 5% of subtotal-discount), total_amount (auto-calculated, DECIMAL), payment_method (required, enum: cash/card/split), trn_display (auto-filled from business profile).

## Validation Rules
- All required fields validated before submission.
- Inline error messages displayed below field.
- Server-side validation mirrors client-side rules.
- All monetary fields: DECIMAL(18,2), validated > 0.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial form specification |