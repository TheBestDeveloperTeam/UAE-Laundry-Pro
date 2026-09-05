# Peripherals (Windows hardware)

LaundryPro UAE integrates ESC/POS printing, barcode scanner wedge, scale parser, cash drawer, and diagnostic tools via `lib/peripherals/`.

## Setup

1. Open **Settings → Peripherals**
2. **Printer** tab — select Windows installed thermal printer
3. **POS** — after payment, use **Print** for hardware or **Save PDF** for fallback

## Requirements

- Windows 10/11 desktop
- PowerShell (printer discovery via Win32 spooler)
- Selected printer in Peripherals console before POS hardware print

## Cash drawer

Drawer kick uses ESC/POS pulse through the selected printer. Configure printer in Peripherals → **Cash Drawer** tab or pulse automatically on cash payment in POS.

## Scanner

USB keyboard-wedge scanners work without drivers. POS and Peripherals screens listen for fast key bursts; matches service `code` or product `barcode` via catalog API.

## MSIX / VC++ runtime

For MSIX builds, stage VC++ runtime DLLs before packaging:

```powershell
powershell scripts/peripherals/stage_missing_dlls.ps1
```

Required DLLs: `msvcp140.dll`, `msvcp140_1.dll`, `vcruntime140.dll`, `vcruntime140_1.dll` (from Visual C++ Redistributable).

## Remote SQL tab

Admin diagnostic only — connects directly to MySQL bypassing API auth. Use on trusted LAN only.

## Local database

Peripheral templates, print queue, and logs use SQLite at:

`%APPDATA%/laundrypro_peripherals.db` (via `getApplicationSupportDirectory`)
