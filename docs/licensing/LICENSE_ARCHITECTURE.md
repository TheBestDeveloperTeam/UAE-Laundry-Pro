# LaundryPro UAE — License Architecture

> **Version:** 2.0.0 | **Last Updated:** 2026-09-30

---

## 1. Overview

LaundryPro uses a **3-way license handshake** involving:
1. **Local API** — License validation and UMAC generation
2. **Cloud API** — License issuance, validation, and device tracking
3. **Windows Registry** — Write-once hardware fingerprint storage

## 2. License Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                        LICENSE LIFECYCLE                         │
│                                                                 │
│  TRIAL ──► ACTIVATE ──► ACTIVE ──► EXPIRED                     │
│              │            │           │                          │
│              │            │           └──► REACTIVATE ──► ACTIVE │
│              │            │                                      │
│              │            └──► SUSPENDED ──► REVOKED             │
│              │                                                   │
│              └──► INVALID (bad key or UMAC mismatch)             │
└─────────────────────────────────────────────────────────────────┘
```

## 3. Trial Mode

When no license is activated:
- **Invoice limit:** 9 invoices total
- **Customer limit:** 9 customers total
- **Duration:** 7 days from first install
- **Features:** Basic POS only, no sync, no multi-branch
- **Anti-tamper:** Install pulse stored in Windows Registry (write-once)

### Trial Enforcement

```php
// LicenseService.php — Trial validation
if ($row === null) {
    $trialValid = ($invCount <= 9 && $custCount <= 9);
    return [
        'active' => false,
        'is_trial' => true,
        'trial_valid' => $trialValid,
        'trial_days_remaining' => 7 - daysSinceInstall(),
        'invoice_count' => $invCount,
        'max_invoices' => 9,
    ];
}
```

## 4. 3-Way Handshake

### Step-by-Step Flow

| Step | Actor | Action |
|---|---|---|
| 1 | Flutter | User enters license key in Settings → License screen |
| 2 | Flutter | Calls `POST /api/v1/license/activate` with `{license_key}` |
| 3 | Local API | Generates UMAC from hardware (CPU ID + baseboard serial) |
| 4 | Local API | Writes UMAC + install_pulse to Windows Registry (write-once) |
| 5 | Local API | Calls Cloud API: `POST /api/v1/license/validate` with `{license_key, umac, machine_name}` |
| 6 | Cloud API | Validates license_key exists in `cloud_licenses` |
| 7 | Cloud API | Checks `cloud_licenses.status = 'active'` |
| 8 | Cloud API | Checks `cloud_licenses.expires_at > NOW()` |
| 9 | Cloud API | Records/verifies UMAC in `cloud_telemetry` |
| 10 | Cloud API | Checks device count ≤ plan limit |
| 11 | Cloud API | Returns `{valid: true, plan_type, expires_at, max_invoices, max_customers}` |
| 12 | Local API | Stores validated license in local `license` table |
| 13 | Local API | Returns success to Flutter |

### Failure Cases

| Failure | Code | Response |
|---|---|---|
| Invalid license key | `LICENSE_INVALID` | Key not found in cloud DB |
| Expired license | `LICENSE_EXPIRED` | `expires_at` has passed |
| Revoked license | `LICENSE_REVOKED` | Status is 'revoked' |
| Device limit exceeded | `LICENSE_LIMIT_EXCEEDED` | Too many UMACs for plan |
| UMAC mismatch | `LICENSE_UMAC_MISMATCH` | Registry tampering detected |
| Cloud unreachable | *Offline grace period* | Use cached license for 72 hours |

## 5. Plan Types

| Plan | Devices | Branches | Invoices | Customers | Sync | Support |
|---|---|---|---|---|---|---|
| **Trial** | 1 | 1 | 9 | 9 | ❌ | None |
| **Standard** | 1 | 1 | ∞ | ∞ | ❌ | Email |
| **Premium** | 5 | 3 | ∞ | ∞ | ✅ | Priority |
| **Enterprise** | 999 | ∞ | ∞ | ∞ | ✅ | 24/7 |

## 6. UMAC (Unique Machine Authentication Code)

### 6.1 Generation

```dart
// system_guard_service.dart
String rawCombo = '$machineName|$cpuId|$baseboard';
String machineHash = sha256(utf8.encode(rawCombo)).toUpperCase();
String umac = 'UMAC-${hash[0:4]}-${hash[4:8]}-${hash[8:12]}';
```

### 6.2 Registry Storage

```
HKCU\Software\LaundryProUAE\Evaluation
├── MachineCode: UMAC-A1B2-C3D4-E5F6 (REG_SZ)
├── InstallPulse: 1727625600        (REG_DWORD, Unix timestamp)
└── AppVersion: 1.2.1               (REG_SZ)
```

### 6.3 Anti-Tamper Rules

1. If `InstallPulse` is missing → First install, write current timestamp
2. If `InstallPulse` exists but changed → License invalidated (tamper detected)
3. If `MachineCode` changed → New hardware, requires re-activation
4. Registry values are checked on every app startup

## 7. Offline Grace Period

When cloud API is unreachable during license check:
- **Cached license valid for 72 hours** after last successful cloud validation
- After 72 hours offline → License status degrades to trial mode
- On reconnect → Full re-validation with cloud
- Grace period tracked via `license.last_cloud_validated_at` column

## 8. License Issuance (Cloud Admin)

The Cloud Super-Admin Portal provides license management:

1. **Issue License:** Generate license key, assign to tenant, set plan/expiry
2. **View Licenses:** List all licenses with status, usage, device count
3. **Revoke License:** Immediately revoke a license with reason
4. **Extend License:** Update expiry date for renewals
5. **Audit Trail:** All license operations logged to `cloud_audit_logs`

---

*This document is the authoritative license architecture reference.*
