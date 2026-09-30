# LaundryPro UAE — Peripheral & Hardware Integration Guide

> **Version:** 2.0.0 | **Authoritative Hardware Engineering Manual**

---

## 1. Supported Hardware Matrix

| Hardware Class | Supported Models | Interface | Primary Role |
|---|---|---|---|
| **80mm Thermal Receipt** | Epson TM-T88VI/VII, Bixolon SRP-350, Rongta RP326 | USB, TCP/IP (Port 9100) | Customer Receipts & FTA Tax Invoices |
| **Heat-Seal Garment Tag** | Zebra ZD421, TSC TE200, Citizen CL-E300 | USB, Virtual COM | Water-resistant polyester care label tags |
| **POS Cash Drawer** | APG Vasario, M-S Cash Drawer, E-POS RJ11 | RJ11/RJ12 (via Receipt Printer) | Physical currency storage & drawer kicks |
| **Barcode / 2D Scanners** | Honeywell Xenon 1900, Zebra DS2208, Datalogic | USB HID Keyboard Emulation | Order search & garment sorting scan |
| **NFC / RFID Readers** | ACR122U, Impinj Speedway UHF Reader | USB / Serial | High-volume industrial garment tracking |

---

## 2. Thermal Printing & Bilingual Arabic Rendering

Standard ESC/POS thermal printers do not natively shape connected Arabic text (RTL and contextual letter forms). LaundryPro UAE utilizes a dual-path rendering engine:

### 2.1 Raster Canvas Graphic Rendering (Default & Recommended)
1. The Flutter desktop app or PHP renderer draws the receipt onto an off-screen monochrome canvas (576 dots width for 80mm paper).
2. Connected Arabic text (Noto Sans Arabic) and Latin typography are rendered with pixel-perfect alignment.
3. The image is converted into raw ESC/POS bit-image command bytes (`GS v 0`) and transmitted directly to the printer socket or spooler.
4. **Advantage**: 100% consistent typography across all printer brands; zero dependency on printer firmware code pages.

### 2.2 Hardware Code Page Mode (Fast Text Mode)
For legacy low-bandwidth networks:
- Command: `ESC t 28` (Select Character Code Table: CP864 Arabic) or `ESC t 37` (Windows-1256).
- Text is processed through a bidirectional reshaping algorithm before output.

---

## 3. Cash Drawer Kick-Out Pulse

The cash drawer is connected via an RJ11/RJ12 cable to the back of the thermal receipt printer. The printer delivers a 24V solenoid electrical pulse:

```dart
// Dart ESC/POS Cash Drawer Trigger Code
final List<int> kickDrawer = [
  0x1B, 0x70, // ESC p
  0x00,       // Pin 2 (Drawer 1)
  0x19,       // Pulse ON time: 25 * 2ms = 50ms
  0xFA        // Pulse OFF time: 250 * 2ms = 500ms
];
await printerSocket.add(kickDrawer);
```

---

## 4. Garment Tag Printing Specification

Heat-seal care tags must withstand continuous wash cycles up to 90°C and hydrocarbon dry cleaning solvents:
- **Material**: Thermoplastic coated woven taffeta / satin polyester ribbon.
- **Barcode Symbology**: Code 128 (Auto subset) or compact DataMatrix.
- **Tag Layout (Width: 35mm, Height: 25mm)**:
  ```text
  ┌─────────────────────────┐
  │ LP: DXB-2026-0042 [1/3] │
  │ KANDORA - DRY CLEAN     │
  │ *|||||||||||||||||||||* │
  │ DUE: 02-OCT RACK: A-14  │
  └─────────────────────────┘
  ```
