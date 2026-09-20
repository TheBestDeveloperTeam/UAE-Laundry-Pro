# Tenant Isolation Model - LaundryPro UAE
> **Version:** 1.0.0

## Approach: Shared Database, Shared Schema, Row-Level Isolation

## Isolation Column
`business_owner_id` (BIGINT UNSIGNED FK) on all data tables.

## Enforcement Points
1. **Database**: All SELECT queries include WHERE business_owner_id = ?.
2. **API Middleware**: Extracts business_owner_id from JWT; injects into all queries.
3. **Sync Engine**: Outbox entries scoped to business_owner_id.
4. **Reports**: All reports filtered by business_owner_id.
5. **Bot**: tenant_isolation_checker validates at code review.

## Exempt Tables (system-scoped)
- migrations, system_settings, roles, permissions, role_permissions, machine_licenses