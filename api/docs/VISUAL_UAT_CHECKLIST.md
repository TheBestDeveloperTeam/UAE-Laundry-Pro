# Visual UAT Checklist — LaundryPro UAE

Manual UX validation for operator flows. Target: fewer clicks, real data, no overflow in RTL.

| # | Flow | Max clicks | Pass criteria | Evidence |
|---|------|------------|---------------|----------|
| 1 | Login → POS sale → receipt | ≤4 | Receipt prints/PDF; order in pending | Screenshot / order no |
| 2 | Login → Dashboard → pending invoice | ≤2 | KPI shows real value or honest empty state | Dashboard screenshot |
| 3 | Login → Reports → filtered P&L | ≤3 | Date filter applied; formatted AED totals | Reports tab screenshot |
| 4 | Admin → HR → payroll run | ≤4 | Period visible; run created | Payroll screen |
| 5 | Arabic RTL smoke | 1 toggle | No overflow on dashboard/reports | AR screenshots |
| 6 | Dashboard drill-through | ≤2 | KPI card navigates to correct route | Route URL |
| 7 | Production status chain | ≤3 | All 8 statuses visible; transition works | Production tab |
| 8 | Branches list/create | ≤3 | Branch appears in list | Branches screen |
| 9 | Terminals register | ≤4 | Session token returned | API response |
| 10 | Analytics summary | ≤2 | Today sales + trend list | Analytics screen |
| 11 | Storefront order convert | ≤4 | Pending order → sales draft | Storefront screen |
| 12 | Customer portal lookup | ≤3 | Order status by token | Portal screen |
| 13 | Notification channel test | ≤3 | Test message logged | Channels screen |
| 14 | Accounting export | ≤3 | Batch with lines created | Accounting screen |
| 15 | KSA profile switch | ≤3 | Country AE↔SA without error | Localization screen |

## Sign-off

| Role | Name | Date | Result |
|------|------|------|--------|
| Developer | Magnificent Solution | 2026-09-05 | ☐ Pass |
| UAT | | | ☐ Pass |
