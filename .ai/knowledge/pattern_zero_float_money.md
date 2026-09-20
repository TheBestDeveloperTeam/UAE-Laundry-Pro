# Knowledge: pattern_zero_float_money

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Zero-float money rule: NEVER use FLOAT or DOUBLE for monetary values. MariaDB: DECIMAL(18,2). PHP: bcmath functions (bcadd, bcsub, bcmul, bcdiv) with scale=2. Dart: int cents or Decimal package. Display: always 2 decimal places with proper locale formatting. Rounding: ROUND_HALF_UP. money_precision_guard bot enforces this rule.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |