# Blueprint: inventory Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Inventory Management module. Supply tracking (detergent, hangers, bags, starch, packaging). Stock-in transactions with supplier and invoice reference. Stock-out transactions linked to production consumption. Minimum threshold alerts. Garment inventory by status and location. Inventory valuation reports.

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