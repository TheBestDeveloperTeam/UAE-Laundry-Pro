# UAE Compliance: LaundryPro UAE

## UAE VAT (Value Added Tax)
- Rate: 5% (as of current UAE law)
- All sales invoices must show:
  - Business TRN (Tax Registration Number)
  - Subtotal (excl. VAT)
  - VAT amount as separate line: VAT (5%): AED X.XX
  - Grand Total (incl. VAT)
- Tax invoices: for B2B (businesses must show buyer TRN if provided)
- Simplified tax invoices: for retail/B2C under AED 10,000
- Invoice numbers: sequential, no gaps (server-side atomic)
- VAT report: must be exportable in FTA (Federal Tax Authority) format

## UAE Labour Law (HR/Payroll)
- Working hours: typically 8 hours/day, 48 hours/week
- Overtime: 1.25x for weekday OT, 1.5x for Friday, 2x for public holidays
- Leave entitlement: 30 calendar days per year after 1 year service
- WPS (Wage Protection System): mandatory salary payment via approved channels
  - WPS export: SIF format (Salary Information File)
  - Must include: employee Emirates ID, IBAN/account number, salary amount

## UAE PDPL (Personal Data Protection Law)
- Customer data: store only what is necessary
- Customer data deletion: support upon request
- No customer data stored in plaintext passwords or unencrypted
- Audit trail for all data access on PII fields

## Currency
- Primary: AED (UAE Dirham) / Fils (1 AED = 100 Fils)
- Decimal: 2 places (e.g., 73.50 AED)
- Never use floating-point for currency — always DECIMAL(18,2)
- Display: AED 73.50 or 73.50 درهم (Arabic)

## Date/Time
- Primary timezone: Asia/Dubai (UTC+4, no DST)
- Store timestamps in UTC in DB; display in Asia/Dubai
- Hijri calendar: optional feature (Phase 3)
- Business date: calendar date in Dubai timezone (not UTC)
