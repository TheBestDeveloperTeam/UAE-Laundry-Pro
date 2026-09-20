# Blueprint: orders Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Order Management module. Walk-in, pickup, and corporate order intake. Sequential numbering (ORD-YYYY-NNNNNN). Barcode/RFID garment tagging. Status tracking (received, sorting, processing, quality-check, ready, out-for-delivery, delivered). Express/same-day/next-day/standard turnaround. Per-item, per-kg, per-piece pricing. Line-item and order-level discounts. Special instructions and notes.

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