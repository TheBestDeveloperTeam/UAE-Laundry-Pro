# Blueprint: hr_payroll Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
HR and Payroll module. Employee master records (personal info, employment details, salary). Attendance tracking (check-in/check-out, late, absent, overtime). Leave management (annual 30 days, sick, unpaid). Payroll calculation with UAE overtime rules (1.25x, 1.5x, 2x). SIF file export for WPS compliance. End-of-service gratuity calculation.

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