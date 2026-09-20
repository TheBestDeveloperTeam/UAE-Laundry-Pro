# Scanner Integration - LaundryPro UAE
> **Version:** 1.0.0

## Supported Scanner Types
| Type | Interface | Mode |
|------|-----------|------|
| Handheld USB | USB HID | Keyboard wedge |
| Bluetooth | SPP | Serial stream |
| Fixed mount | RS-232 | Serial stream |

## Barcode Formats
- Code 128 (primary for garment tags)
- QR Code (customer-facing)
- EAN-13 (product lookup)

## Integration Approach
USB HID scanners inject keystrokes. The application listens for rapid keystroke sequences ending with Enter/CR to detect scan input vs. manual typing.