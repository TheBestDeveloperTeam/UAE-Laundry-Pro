# Blueprint: finance Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Finance and Invoicing module. Invoice generation with TRN and VAT (5%). Immutable posted invoices (correction memo only). Sequential invoice numbering (INV-YYYY-NNNNNN). Payment tracking (cash, card, bank transfer). Daily cash register reconciliation. Expense tracking. Financial reports (P&L, cash flow, aging, VAT return).

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