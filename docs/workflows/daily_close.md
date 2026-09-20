# Workflow: daily close - LaundryPro UAE
> **Version:** 1.0.0

## Flow
Daily close: Print daily summary report -> Count cash register -> Enter counted amount -> System calculates variance -> Manager reviews and approves -> Generate daily financial report -> Backup database.

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