# Workflow: pickup order - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Pickup order: Customer calls/schedules online -> Manager creates pickup order -> Assign driver -> Driver collects garments -> Tag at branch -> Process as standard order.

## Actors
- Relevant user roles as defined in user_roles.md

## Preconditions
- User authenticated with appropriate role
- System online or offline (offline-first capable)

## Postconditions
- All state changes logged to audit_logs
- Sync outbox updated for offline entries

## Error Handling
- Validation errors shown inline
- System errors logged and user notified
- Offline mode: operations queued in sync outbox

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial workflow documentation |