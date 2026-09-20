# Blueprint: auth Module - LaundryPro UAE
> **Version:** 1.0.0

## Overview
Authentication & Authorization module. JWT-based login with access/refresh tokens. RBAC with 6 roles and scope-based permissions. UMAC machine-bound licensing. Session management with forced logout. Password hashing with bcrypt. Account locking after 5 failed attempts.

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