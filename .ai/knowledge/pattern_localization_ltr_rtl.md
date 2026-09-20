# Knowledge: pattern_localization_ltr_rtl

> **Version:** 1.0.0 | **Last Updated:** 2026-09-21 | **Category:** Design Pattern

## Reference

Localization: en.json (English LTR) and ar.json (Arabic RTL). All UI strings via locale keys, never hardcoded. Flutter Localizations delegate with ARB files. RTL support: use Directionality widget, start/end instead of left/right, TextDirection-aware padding. Font pairs: Inter/Roboto for Latin, Noto Sans Arabic/Cairo for Arabic. i18n_auditor bot validates parity.

## Usage
This knowledge file is injected into agent context when the agent's Knowledge Domains list includes this file. Agents should treat this as authoritative reference for their domain decisions.

## Change Log
| Version | Date | Change |
|---------|------|--------|
| 1.0.0 | 2026-09-21 | Initial knowledge entry |