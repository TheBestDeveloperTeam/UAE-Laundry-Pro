# Hardware Integration: LaundryPro UAE

## Architecture Rule
Application ONLY calls generic interfaces:
- scanService.read() — never call USB/BT SDK directly
- printerService.print(document) — routes to correct adapter
- cashDrawerService.open(reason) — audited, permission-checked

## Thermal Printers (ESC/POS)
| Brand | Models | USB | BT | WiFi | LAN |
|-------|--------|-----|----|------|-----|
| Epson | TM-T20/T82/T88 | ✅ | ✅ | ✅ | ✅ |
| Star | TSP100/TSP650/mPOP | ✅ | ✅ | ✅ | ✅ |
| Bixolon | SRP-350/330/275 | ✅ | ✅ | ✅ | ✅ |
| Citizen | CT-S310/4000 | ✅ | ✅ | ✅ | ✅ |
| Xprinter | XP-58/80 | ✅ | ✅ | ❌ | ✅ |
| Generic | Any ESC/POS | ✅ | ✅ | ✅ | ✅ |
Paper: 57mm, 80mm, 112mm

## Inkjet / Laser (Windows Spooler via PDF)
Paper: A6 (garment tag), A5 (challan/compact invoice), A4 (invoice/report), A3, A2, A1

## Dot Matrix (ESC/P via Serial)
| Brand | Models | Carbon Copy |
|-------|--------|-------------|
| Epson | LX-350, LQ-590, FX-890 | ✅ 2/3/4-ply |
| OKI | ML-5100 | ✅ |
| Generic | ESC/P compatible | ✅ |
Labels: ORIGINAL / CUSTOMER COPY / BRANCH COPY / DELIVERY COPY

## Scanners
| Type | Connection | Protocol |
|------|-----------|---------|
| USB Handheld (1D/2D) | USB HID | Keyboard wedge |
| Bluetooth | BT | Serial / keyboard |
| Serial | COM port | Configurable baud |
Barcode formats: Code39, Code128, EAN-8/13, UPC-A/E, QR Code, Data Matrix, PDF417

## Cash Drawers
| Brand | Connection | Command |
|-------|-----------|---------|
| APG, MMF, Posiflex | RJ11 via thermal | ESC p 0 50 50 |
| Generic | RJ11 via thermal | ESC p 0 50 50 |
| Any | Serial RS-232 | Configurable pulse |
Status pin polling where supported.

## Auto-Discovery Algorithm
1. WMI query USB printers
2. Bluetooth paired devices (printer class)
3. TCP subnet scan port 9100
4. mDNS (_pdl-datastream._tcp, _ipp._tcp)
5. COM port enumeration (ESC/POS status probe)
Auto-reconnect: every 30 seconds for failed connections.

## Print Templates Location
All templates in TEMPLATE_PATH (C:/LaundryPro/templates/)
Formats: receipt_thermal_80mm.json, receipt_thermal_57mm.json,
         invoice_a4.json, invoice_a5.json, garment_tag_a6.json,
         challan_a5.json, delivery_slip_a5.json, report_a4.json
