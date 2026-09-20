# UMAC Licensing Specification - LaundryPro UAE
> **Version:** 1.0.0

## Overview
UMAC (Unique Machine Authentication Code) binds each license to a specific machine.

## Machine Hash Components
- CPU ID (CPUID instruction)
- Disk serial number (primary drive)
- MAC address (primary network adapter)
- Combined via SHA-256: `UMAC = SHA256(CPUID + DISK_SERIAL + MAC_ADDRESS)`

## License Tiers
| Tier | Duration | Features |
|------|----------|----------|
| Trial | 30 days | Full features, watermark |
| Standard | 1 year | Core modules |
| Premium | 1 year | All modules + priority support |
| Enterprise | 1 year | Multi-branch + API access |

## Validation Flow
1. On launch: compute UMAC from hardware.
2. Compare against stored license hash.
3. If match: activate.
4. If mismatch: enter read-only mode.
5. Grace period: 30 days offline before read-only enforcement.