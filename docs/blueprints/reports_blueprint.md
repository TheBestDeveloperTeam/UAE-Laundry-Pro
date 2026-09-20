# Blueprint: reports Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Reports and Analytics module. Dashboard KPIs (daily revenue, orders, production throughput). Sales reports (by period, branch, service, employee). Production reports (by operator, service type, turnaround). Financial reports (P&L, cash flow, accounts receivable aging). HR reports (attendance, payroll, leave balances). Export to PDF and CSV.

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