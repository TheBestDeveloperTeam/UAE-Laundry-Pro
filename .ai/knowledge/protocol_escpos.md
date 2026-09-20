# Knowledge: protocol_escpos

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Protocol

## Reference

ESC/POS thermal printer protocol. Initialize: ESC @ (1B 40). Text alignment: ESC a n. Bold: ESC E 1 / ESC E 0. Font size: GS ! n. Cut paper: GS V 66 n. Cash drawer: ESC p 0 50 50. Barcode: GS k. QR code: GS ( k. Image: GS v 0. Supported widths: 57mm (32 chars), 80mm (48 chars). Arabic printing: codepage 864 or UTF-8 mode.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |