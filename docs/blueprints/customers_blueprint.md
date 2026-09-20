# Blueprint: customers Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Customer Management module. Customer profile (name, phone, email, address, TRN for corporate). Order history and spending analysis. Corporate account management with monthly billing. Customer preferences (starch level, fold style, packaging). Loyalty/credit balance. Customer notes and communication log.

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