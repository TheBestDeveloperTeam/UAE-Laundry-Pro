# Printer Integration - LaundryPro UAE
> **Version:** 1.0.0

## Supported Printer Types
| Type | Protocol | Paper Sizes | Brands |
|------|----------|-------------|--------|
| Thermal | ESC/POS | 57mm, 80mm | Epson, Star, Bixolon, Citizen, Xprinter |
| Dot-Matrix | ESC/P | 112mm | Epson |
| Inkjet/Laser | Windows Spooler | A6, A5, A4 | Any Windows-compatible |

## Auto-Discovery Methods
1. WMI query for USB printers
2. Bluetooth device scan
3. TCP port scan for network printers
4. mDNS/Bonjour discovery
5. COM port enumeration for serial

## Adapter Interface
All printers implement `IPrinterAdapter`:
- `connect()`, `disconnect()`
- `print(template, data)`
- `getStatus()`
- `openCashDrawer()`