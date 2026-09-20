# Security Architecture - LaundryPro UAE
> **Version:** 1.0.0

## Security Layers
1. **Authentication**: JWT with 15-min access tokens, 7-day refresh tokens.
2. **Authorization**: RBAC with scope-based permissions on all endpoints.
3. **Input Validation**: Server-side validation on all inputs; PDO prepared statements.
4. **Data Protection**: AES-256-GCM encryption for PII at rest; SHA-256 for backup verification.
5. **Audit Trail**: Hash-chained audit logs for tamper evidence.
6. **Licensing**: UMAC machine-bound licensing with hardware hash verification.
7. **Tenant Isolation**: business_owner_id on all data queries and mutations.