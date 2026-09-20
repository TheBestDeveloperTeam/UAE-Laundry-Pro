# Error Code Registry - LaundryPro UAE
> **Version:** 1.0.0 | **Last Updated:** 2026-09-21

## Error Code Format
`LP-ERR-{MODULE}-{NUMBER}`

## Authentication Errors (1xxx)
| Code | HTTP | Message |
|------|------|---------|
| LP-ERR-AUTH-1001 | 401 | Invalid credentials |
| LP-ERR-AUTH-1002 | 401 | Token expired |
| LP-ERR-AUTH-1003 | 401 | Token revoked |
| LP-ERR-AUTH-1004 | 403 | Insufficient permissions |
| LP-ERR-AUTH-1005 | 403 | Account locked |
| LP-ERR-AUTH-1006 | 403 | License expired |
| LP-ERR-AUTH-1007 | 403 | Machine not authorized (UMAC) |

## Validation Errors (2xxx)
| Code | HTTP | Message |
|------|------|---------|
| LP-ERR-VAL-2001 | 422 | Required field missing |
| LP-ERR-VAL-2002 | 422 | Invalid field format |
| LP-ERR-VAL-2003 | 422 | Value out of range |
| LP-ERR-VAL-2004 | 422 | Duplicate entry |
| LP-ERR-VAL-2005 | 422 | Referential integrity violation |

## Business Logic Errors (3xxx)
| Code | HTTP | Message |
|------|------|---------|
| LP-ERR-BIZ-3001 | 409 | Order already processed |
| LP-ERR-BIZ-3002 | 409 | Invoice already posted (immutable) |
| LP-ERR-BIZ-3003 | 409 | Insufficient inventory |
| LP-ERR-BIZ-3004 | 409 | Payment amount mismatch |
| LP-ERR-BIZ-3005 | 409 | Employee already clocked in |

## Sync Errors (4xxx)
| Code | HTTP | Message |
|------|------|---------|
| LP-ERR-SYNC-4001 | 409 | Sync conflict detected |
| LP-ERR-SYNC-4002 | 409 | Idempotency key already processed |
| LP-ERR-SYNC-4003 | 422 | Invalid sync sequence |
| LP-ERR-SYNC-4004 | 503 | Cloud endpoint unavailable |

## System Errors (5xxx)
| Code | HTTP | Message |
|------|------|---------|
| LP-ERR-SYS-5001 | 500 | Internal server error |
| LP-ERR-SYS-5002 | 500 | Database connection failed |
| LP-ERR-SYS-5003 | 503 | Service unavailable |
| LP-ERR-SYS-5004 | 500 | Backup verification failed |