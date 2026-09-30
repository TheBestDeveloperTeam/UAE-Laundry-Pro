# LaundryPro UAE — Security Model

> **Version:** 2.0.0 | **Last Updated:** 2026-09-30

---

## 1. Authentication

### 1.1 Local API — JWT Bearer Authentication

| Token | TTL | Purpose |
|---|---|---|
| Access Token | 8 hours (28800s) | Short-lived, sent with every request |
| Refresh Token | 30 days (2592000s) | Long-lived, used to obtain new access token |

**Token Flow:**
1. `POST /auth/login` → returns `{access_token, refresh_token, expires_in}`
2. Client stores tokens in `flutter_secure_storage`
3. Every request sends `Authorization: Bearer {access_token}`
4. On 401, client calls `POST /auth/refresh` with `{refresh_token}`
5. On logout, `POST /auth/logout` revokes refresh token (hash stored in `refresh_tokens` table)

### 1.2 Cloud API — Tenant Authentication

| Header | Purpose |
|---|---|
| `Authorization: Bearer {cloud_token}` | Tenant identity verification |
| `X-Business-Owner-Id: {tenant_id}` | Tenant scope identification |
| `X-License-Key: {key}` | License validation |
| `X-Device-UMAC: {umac}` | Device fingerprint tracking |

### 1.3 Portal Authentication

- Session-based PHP sessions
- Password verified via `password_verify()` against `password_hash` in database
- CSRF tokens on all POST forms
- Session timeout: 120 minutes
- Failed login tracking with account lockout (configurable)

## 2. Authorization (RBAC)

### 2.1 Role Structure

```json
// roles.permissions column (JSON array)
{
  "administrator": ["*"],
  "cashier": ["sales.create", "sales.read", "customers.read"],
  "supervisor": ["sales.*", "customers.*", "inventory.read", "reports.read"]
}
```

### 2.2 Permission Check Flow

```
Request → AuthMiddleware (decode JWT, extract user_id)
       → PermissionMiddleware:
           1. Fetch user's role from DB (cached)
           2. Get required permission from route meta
           3. Check if role.permissions contains required permission
           4. Wildcard "*" matches everything
           5. Prefix wildcards "sales.*" match "sales.create", "sales.read", etc.
       → Allow or reject (403 AUTH_FORBIDDEN)
```

### 2.3 Default Roles

| Role | Permissions | Description |
|---|---|---|
| `administrator` | `["*"]` | Full system access |
| `cashier` | `["sales.create", "sales.read", "customers.read"]` | POS-only access |

## 3. Input Validation & Sanitization

### 3.1 Rules

- All user input is validated before processing
- SQL queries use PDO prepared statements (parameterized, never string concatenation)
- JSON request bodies decoded with `json_decode()` and typed-checked
- File uploads validated for type, size, and name sanitization
- HTML output escaped to prevent XSS

### 3.2 Financial Precision

- All monetary values stored as `DECIMAL(18,2)` in database
- All calculations use `bcmath` functions (`bcmul`, `bcadd`, `bcsub`) — never `float`
- API responses send monetary values as strings to preserve precision
- VAT calculations: `tax = bcmul(subtotal, '0.05', 2)` (UAE 5% VAT)

## 4. Network Security

### 4.1 CORS

- Configured via `CORS_ALLOWED_ORIGINS` environment variable
- Only whitelisted origins receive `Access-Control-Allow-Origin`
- Credentials allowed for same-origin requests

### 4.2 Rate Limiting

| Endpoint Category | Limit | Window |
|---|---|---|
| Login/Refresh | 5 attempts | 15 minutes |
| Install endpoints | 10 attempts | 1 hour |
| General API | 1000 requests | 1 hour |

### 4.3 Security Headers

| Header | Value | Purpose |
|---|---|---|
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing |
| `X-Frame-Options` | `DENY` | Prevent clickjacking |
| `X-XSS-Protection` | `1; mode=block` | XSS protection |
| `Strict-Transport-Security` | `max-age=31536000` | Force HTTPS |
| `Content-Security-Policy` | `default-src 'self'` | CSP policy |

## 5. Hardware Identity (UMAC)

### 5.1 Generation Algorithm

```
Input:  hostname + CPU ProcessorID + baseboard SerialNumber
Hash:   SHA-256(hostname | CPU_ID | baseboard_serial)
Format: UMAC-{hash[0:4]}-{hash[4:8]}-{hash[8:12]}
```

### 5.2 Storage

- **Windows Registry:** `HKCU\Software\LaundryProUAE\Evaluation`
  - `MachineCode` (REG_SZ) — UMAC string
  - `InstallPulse` (REG_DWORD) — Unix timestamp of first install
  - Write-once: tamper detection if values change

### 5.3 Anti-Tamper

- Install pulse written once on first activation
- If registry values are modified → license invalidated
- UMAC compared against cloud license record on each sync

## 6. Data Protection

### 6.1 Sensitive Data Handling

| Data | Storage | Protection |
|---|---|---|
| User passwords | `users.password_hash` | `password_hash(PASSWORD_DEFAULT)` |
| JWT secret | `.env` file | Not committed to git |
| Cloud DB password | `.env.production` | Not committed to git |
| License master secret | `.env.production` | Not committed to git |
| Refresh tokens | `refresh_tokens.token_hash` | SHA-256 hash (not plaintext) |
| Cloud tokens | `businesses.cloud_token` | 64-char random hex |

### 6.2 Audit Trail

- All write operations logged to `audit_logs` table
- Log includes: `user_id`, `action`, `entity_type`, `entity_id`, `payload`, `timestamp`
- Cloud portal has separate `cloud_audit_logs` for super-admin actions
- Logs are append-only (no UPDATE/DELETE allowed)

---

*This document is the authoritative security model reference.*
