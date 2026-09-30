# LaundryPro UAE — User Acceptance Testing (UAT) Scripts

> **Version:** 2.0.0 | **Authoritative Operational Validation Checklist**

---

## Script 1: Initial Workstation Provisioning & Admin Onboarding

| Step # | Action | Input Data | Expected Result | Pass / Fail |
|:---:|---|---|---|:---:|
| 1.1 | Launch Windows desktop application | N/A | App launches without errors; redirects to `/install` if unlicensed | [ ] |
| 1.2 | Submit valid Enterprise License Key | `LP-ENT-2026-ABCD-EFGH` | System extracts UMAC, contacts Cloud API, activates license | [ ] |
| 1.3 | Create Super-Admin store account | `admin@store.ae` / `P@ssword2026!` | Admin profile created; redirects to POS login screen | [ ] |
| 1.4 | Log in with newly created credentials | Same credentials | Issues JWT Bearer token; opens main POS AppShell in bilingual EN/AR | [ ] |

---

## Script 2: Customer Intake, Heat-Seal Tagging & Thermal Print

| Step # | Action | Input Data | Expected Result | Pass / Fail |
|:---:|---|---|---|:---:|
| 2.1 | Search customer by phone number | `+971501234567` | Displays customer record or prompts to create new customer | [ ] |
| 2.2 | Add 2x Men's Kandora (Dry Clean) | Modifier: `Medium Starch` | Items added to cart; gross total and 5% VAT updated instantly | [ ] |
| 2.3 | Add 1x Silk Abaya (Hand Wash) | Modifier: `Perfume Rinse` | Items added to cart; turnaround time computed | [ ] |
| 2.4 | Click "Confirm & Print Tags" | Tender: `Advance 50 AED Cash` | Cash drawer kicks open; thermal printer outputs 3 garment tags + 1 customer receipt | [ ] |
| 2.5 | Inspect physical printed tags | Visual Inspection | Tags contain high-contrast legible barcode, item count `1/3`, `2/3`, `3/3` | [ ] |

---

## Script 3: Factory Challan Dispatch & Return Gate-Pass

| Step # | Action | Input Data | Expected Result | Pass / Fail |
|:---:|---|---|---|:---:|
| 3.1 | Navigate to Logistics -> Factory Challan | Filter: `Ready for Factory` | Lists all confirmed garment batches currently in branch staging | [ ] |
| 3.2 | Scan barcodes of 20 garments | Barcode Scanner | Items automatically grouped into Challan manifest #CH-1001 | [ ] |
| 3.3 | Assign Van Driver & Click "Dispatch" | Driver: `Ahmed Al Zaabi` | Manifest finalized; garments status updated to `InProcess (Factory)` | [ ] |
| 3.4 | Later: Factory van returns; scan return | Challan #CH-1001 | Garments verified against manifest; missing items highlighted | [ ] |
| 3.5 | Confirm receipt into branch | Click "Accept Clean" | Garments updated to `Ready`; customer SMS/WhatsApp triggers | [ ] |

---

## Script 4: Offline POS Resilience & Background Cloud Synchronization

| Step # | Action | Input Data | Expected Result | Pass / Fail |
|:---:|---|---|---|:---:|
| 4.1 | Disconnect network cable (Simulate Outage)| Physically disconnect | Cloud sync status badge turns yellow `Offline Mode` | [ ] |
| 4.2 | Create 3 new customer sales orders | Standard POS Checkout | Orders processed without latency; saved to local SQLite DB | [ ] |
| 4.3 | Print tax invoices and customer receipts | Thermal Printer | Invoices print normally with local sequence numbers | [ ] |
| 4.4 | Reconnect network cable | Physically connect | Cloud sync status badge turns green `Syncing...` | [ ] |
| 4.5 | Verify Cloud Portal inspector | Cloud Admin URL | All 3 orders appear on Cloud Portal with status `Synced` within 60s | [ ] |
