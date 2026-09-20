# Blueprint: pos Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Point of Sale module. Service catalog display with search. Barcode scanner integration for quick item add. Subtotal, discount, VAT (5%), total calculation. Cash, card, split payment methods. Thermal receipt printing (57mm/80mm). Cash drawer auto-open on cash payment. Quick customer lookup. Express checkout flow optimized for < 30 seconds.

## Key Business Rules
- All monetary values use DECIMAL(18,2).
- All operations scoped to business_owner_id.
- All state changes logged to audit_logs.
- All screens support LTR (English) and RTL (Arabic).
- All operations available in offline mode.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial blueprint |