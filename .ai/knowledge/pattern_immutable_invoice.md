# Knowledge: pattern_immutable_invoice

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Posted invoices are immutable. Once status=posted, no field can be modified. Corrections via correction memo (credit note + new invoice). Sequential numbering: INV-YYYY-NNNNNN, no gaps allowed. Void requires reason and authorization. FTA audit trail requirement.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |