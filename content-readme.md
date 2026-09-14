# LaundryPro UAE — Complete Non-Technical Walkthrough / Manual / Handbook

## 1. Document Control

| Attribute | Details |
|---|---|
| **Document Name** | Complete Non-Technical Project Walkthrough & Operational Handbook |
| **Project Name** | LaundryPro UAE |
| **Version** | 1.2.1+4 (Production Release) |
| **Date** | September 2026 |
| **Status** | Final / Approved |
| **Target Audience** | Business Owners, Store Managers, Cashiers, Auditors, Support Teams |

---

## 2. Executive Summary

LaundryPro UAE is a specialized, offline-resilient Point of Sale (POS) and Enterprise Resource Planning (ERP) application built for the UAE laundry and dry-cleaning market. It ensures uninterrupted store operations even when internet connectivity fails. Designed with strict financial accuracy, role-based access control, and hardware integrations (thermal printers, cash drawers), the system manages the entire garment lifecycle from drop-off to delivery, while transparently synchronizing data to a central cloud head office.

---

## 3. Purpose and Audience

**Purpose:** This handbook serves as the single source of truth for the business functionality of LaundryPro UAE. It explains what the system does, how it is used, and the rules governing its behavior, entirely in plain business language. 
**Audience:** 
- **Cashiers & Front-desk Staff:** For daily operational guidance.
- **Store Managers:** For shift closures, audits, and overrides.
- **Business Owners & Auditors:** For understanding financial constraints, security, and compliance.

---

## 4. Scope and Out of Scope

**In Scope:**
- Point of Sale (POS) checkout, order creation, and multi-tender payments.
- Offline-first resilience and background data synchronization.
- Customer management (CRM) and WhatsApp receipt integration.
- Inventory tracking and low-stock alerts.
- End-of-day shift closures (Z-Reports) and cash reconciliation.
- Refunds (Correction Memos).
- Role-based permissions and onboarding.

**Out of Scope:**
- Detailed technical server configuration (handled by IT).
- Central cloud portal operations (covered in a separate Franchise Handbook).
- Physical hardware repair of printers or cash drawers.

---

## 5. System Overview — Non-Technical

LaundryPro UAE operates on a "Local-First" principle. Every physical store runs a complete, independent version of the software on its local Windows computer. 

When a cashier processes an order, it is saved instantly to the local machine. This guarantees the store never stops operating, even if the city's internet goes down. In the background, an automated "Sync Engine" constantly checks for an internet connection. When available, it securely beams all new orders, customers, and payments up to the central franchise cloud. 

The system uses strict financial mathematics. It never rounds pennies incorrectly, ensuring that End-of-Day tax reports exactly match the money in the drawer.

---

## 6. Glossary of Business Terms

- **POS (Point of Sale):** The main screen where cashiers ring up orders.
- **Walk-in Customer:** A customer who does not want to provide a phone number or name; treated generically.
- **Split Payment:** Paying a single bill with multiple methods (e.g., half cash, half credit card).
- **Correction Memo:** A system-generated negative receipt used to process refunds without illegally deleting the original invoice.
- **Z-Report:** The final daily financial printout generated when a manager closes a shift.
- **Float:** The starting cash placed in the register at the beginning of the day.
- **Sync Engine:** The invisible background helper that sends local store data to the cloud.
- **UMAC:** The unique hardware fingerprint of the store's computer, used to prevent software piracy.

---

## 7. Roles, Personas, and Responsibilities

| Role | Persona | Responsibilities |
|---|---|---|
| **Cashier** | Front-desk staff | Creates orders, takes payments, hands over clean garments, opens shifts. |
| **Store Manager** | Branch Supervisor | Overrides blocked actions, issues refunds, performs shift closures, handles inventory reordering. |
| **Super-Admin** | Franchise IT / Owner | Installs the software, sets up the catalog, monitors sync health, manages role permissions. |

---

## 8. Permissions and Access Control

Permissions dictate exactly what a user can or cannot click on the screen.

| Permission ID | Role | Resource | Action | Scope / Conditions | Example |
|---|---|---|---|---|---|
| `PRM-01` | Cashier | Sales Orders | Create | Can only create new orders | Cashier creates a Walk-in order. |
| `PRM-02` | Cashier | Shift | Open | Cannot close shift without Manager | Cashier inputs morning float of 500 AED. |
| `PRM-03` | Manager | Refunds | Execute | Cannot exceed original order total | Manager refunds 50 AED for a damaged shirt. |
| `PRM-04` | Manager | Shift | Close | Must provide reason if cash is short | Manager closes shift, notes 10 AED missing. |
| `PRM-05` | Admin | Settings | Edit | Full system access | Admin changes VAT rate from 5% to 0%. |

**Inheritance:** The Manager role inherits all Cashier permissions. The Admin role inherits all Manager permissions.

---

## 9. Feature Catalog

### F-01: Offline-First Point of Sale
| Field | Details |
|---|---|
| **Feature Name** | Offline-First POS Checkout |
| **Feature ID** | F-01 |
| **Purpose** | Allow uninterrupted sales regardless of internet stability. |
| **Primary Users** | Cashiers |
| **Trigger** | Customer brings garments to the counter. |
| **Steps** | 1. Cashier selects customer. 2. Adds items (e.g., 2 Shirts). 3. Selects payment method. 4. Clicks "Confirm". |
| **Permissions** | `sales.create` |
| **Example** | Internet drops during a rainstorm. Cashier rings up 150 AED cash order. Drawer opens, receipt prints instantly. |
| **Edge Cases** | System loses power mid-transaction (order auto-saves as Draft). |
| **Assumptions** | Store has local power and a functioning local computer. |

### F-02: Split Payments (Multi-Tender)
| Field | Details |
|---|---|
| **Feature Name** | Split Payment Engine |
| **Feature ID** | F-02 |
| **Purpose** | Allow customers to pay using multiple methods for one bill. |
| **Primary Users** | Cashiers |
| **Trigger** | Customer wants to pay a 200 AED bill with 50 AED cash and 150 AED on card. |
| **Steps** | 1. Cashier clicks "Split Payment". 2. Types "50" in Cash field. 3. System shows "150 Balance". 4. Types "150" in Card field. 5. Confirms. |
| **Permissions** | `sales.create` |
| **Example** | A customer is short on cash, pays 20 AED in coins and puts the remaining 100 AED on their Visa. |
| **Edge Cases** | Cashier enters 300 AED in Cash for a 200 AED bill (System automatically calculates 100 AED Change Due). |

### F-03: Refunds & Correction Memos
| Field | Details |
|---|---|
| **Feature Name** | Immutable Correction Memos |
| **Feature ID** | F-03 |
| **Purpose** | Process refunds legally without altering historical tax records. |
| **Primary Users** | Managers |
| **Trigger** | Customer returns an improperly cleaned garment and demands a refund. |
| **Steps** | 1. Manager opens original order. 2. Clicks "Issue Correction Memo". 3. Selects the specific item to refund. 4. Enters reason. 5. Prints Refund Receipt. |
| **Permissions** | `sales.refund` (Manager only) |
| **Example** | Manager refunds 20 AED for a torn shirt. The system creates a new negative invoice (-20 AED) linked to the original order. The original order remains unchanged. |
| **Edge Cases** | Manager tries to refund 50 AED on a 20 AED item (System blocks action). |

### F-04: Inventory Low-Stock Alerts
| Field | Details |
|---|---|
| **Feature Name** | Automated Stock Monitoring |
| **Feature ID** | F-04 |
| **Purpose** | Prevent the store from running out of essential supplies (detergent, hangers). |
| **Primary Users** | Managers, Admins |
| **Trigger** | Inventory falls below a predefined threshold. |
| **Steps** | 1. System detects stock < minimum. 2. Generates dashboard notification. 3. Manager clicks notification to draft a Purchase Order. |
| **Permissions** | `inventory.read` |
| **Example** | Hanger count drops to 45 (minimum is 50). A red alert appears on the Manager's dashboard. |
| **Assumptions** | Cashiers accurately log spoiled/broken inventory. |

### F-05: Z-Report & Shift Management
| Field | Details |
|---|---|
| **Feature Name** | Shift Close & Cash Reconciliation |
| **Feature ID** | F-05 |
| **Purpose** | Ensure physical money in the drawer matches software records. |
| **Primary Users** | Managers |
| **Trigger** | End of the business day or shift change. |
| **Steps** | 1. Manager clicks "Close Shift". 2. System asks "How much physical cash is in the drawer?". 3. Manager counts and enters cash. 4. System calculates variance. 5. Z-Report prints. |
| **Permissions** | `reports.shift_close` |
| **Example** | Software expects 1000 AED. Manager counts 990 AED. Manager enters 990. System flags a -10 AED variance and demands a typed reason ("Dropped coin"). |
| **Edge Cases** | Unpaid draft orders are open (System forces cashier to void or finalize them before closing shift). |

---

## 10. Use Cases

### UC-01: Process Walk-In Sale
| Field | Details |
|---|---|
| **Use Case ID** | UC-01 |
| **Name** | Process Walk-In Sale |
| **Actor** | Cashier |
| **Goal** | Successfully ring up a customer who declines to provide a phone number. |
| **Preconditions** | System is on, Shift is open. |
| **Trigger** | Customer drops off 1 suit for dry cleaning. |
| **Main Flow** | 1. Cashier selects "Walk-in" button. 2. Adds "Suit - Dry Clean". 3. Selects "Cash". 4. Completes order. |
| **Alternate Flow** | Customer decides to provide a phone number halfway through; Cashier edits customer details on the fly. |
| **Postconditions** | Order saved, receipt printed, drawer opened. |
| **Example** | A tourist drops off a jacket, pays 40 AED cash, takes the printed ticket, and leaves. |

### UC-02: Issue Partial Refund
| Field | Details |
|---|---|
| **Use Case ID** | UC-02 |
| **Name** | Issue Partial Refund |
| **Actor** | Manager |
| **Goal** | Refund a single item from a multi-item order. |
| **Preconditions** | Original order exists and is fully paid. |
| **Trigger** | Customer complains about 1 out of 5 washed shirts. |
| **Main Flow** | 1. Manager finds order. 2. Clicks Refund. 3. Deselects 4 shirts, keeps 1 shirt selected. 4. Notes "Customer unhappy with collar". 5. Confirms. |
| **Postconditions** | Credit memo created for 1 shirt. Financials updated. |
| **Example** | Order was 100 AED. Refund is 20 AED. Daily total revenue drops by 20 AED, but original 100 AED invoice remains untouched for audit purposes. |

---

## 11. End-to-End Workflows

### WF-01: End-to-End Order Lifecycle
| Field | Details |
|---|---|
| **Workflow ID** | WF-01 |
| **Name** | Order Lifecycle |
| **Trigger** | Customer drops off garments. |
| **Actors** | Cashier, Laundry Staff |
| **Steps** | 1. **Received:** Order created, unpaid. <br> 2. **Processing:** Laundry staff marks it "In Wash". <br> 3. **Ready:** Garments pressed and bagged. <br> 4. **Delivered:** Customer pays and collects. |
| **Decisions** | If customer pays upfront, skip payment at delivery step. |
| **Success Criteria** | Order reaches 'Delivered' state with zero balance due. |
| **Example** | Customer drops off a dress on Monday (Received). Cleaned on Tuesday (Ready). Customer picks up and pays on Wednesday (Delivered). |

### WF-02: Background Data Synchronization
| Field | Details |
|---|---|
| **Workflow ID** | WF-02 |
| **Name** | Offline-to-Cloud Sync |
| **Trigger** | Internet connection restored after an outage. |
| **Actors** | System Daemon (Invisible) |
| **Steps** | 1. Detects internet. 2. Gathers all locally queued receipts. 3. Sends in batches of 100 to Cloud. 4. Marks local receipts as 'Synced'. |
| **Failure Paths** | Cloud is down -> System waits 1 minute, then 2 minutes, then 4 minutes (Exponential Backoff) and tries again. |
| **Success Criteria** | Local "Sync Dot" on screen turns from Red to Green. |

---

## 12. User Flows by Role

### UF-01: Cashier Daily Flow
| Field | Details |
|---|---|
| **User Flow ID** | UF-01 |
| **Name** | Cashier Morning to Evening |
| **Role** | Cashier |
| **Entry Point** | App Login Screen at 8:00 AM |
| **Goal** | Manage the front desk for the day. |
| **Steps** | 1. Login. 2. Declare morning float (e.g., 500 AED). 3. Process 50+ sales via POS. 4. Hand over clean garments to customers. 5. Inform Manager at 5:00 PM to close shift. |
| **Exit Points** | Logout / Switch User screen. |

---

## 13. Data and Information Overview — Non-Technical

The system handles several types of critical business data:
- **Financial Data:** Stored using exact monetary definitions. The system uses strict math rules so that `10.00 - 5.00` is always exactly `5.00`, avoiding computer rounding errors.
- **Customer Data:** Names, phone numbers, and addresses.
- **Audit Logs:** An invisible ledger tracks *who* did *what* and *when*. If a cashier voids a line item, the system remembers it permanently.
- **Sync Outbox:** A waiting room for data. If the internet breaks, data waits here safely until the connection returns.

---

## 14. Notifications, Alerts, and Communications

- **Dashboard Alerts:** Red badges appear for low stock, failed cloud syncs, or pending deliveries.
- **WhatsApp Receipts:** After a sale, a cashier can click "WhatsApp Receipt". The system generates a link that opens the WhatsApp Desktop app, pre-filling a polite message and the digital receipt link to send to the customer. No official WhatsApp API fees are incurred (uses standard deep-linking).

---

## 15. Reports, Analytics, and Exports

- **Daily Sales Summary:** Breaks down revenue by Cash, Card, and Account Credit.
- **Tax (VAT) Report:** Calculates exact 5% VAT collected over a specific date range.
- **Exporting:** All reports can be exported to CSV/Excel for accounting software (e.g., Tally, Xero).

---

## 16. Security, Privacy, and Compliance — Non-Technical

- **Anti-Piracy (UMAC):** The software locks itself to the physical computer's motherboard/network card. If an employee copies the software to a USB drive and takes it home, it will refuse to open.
- **Data Privacy:** Customer data is stored locally. Access requires a valid username and password.
- **Immutable Records:** UAE tax laws require that invoices are never deleted. The system enforces this physically; there is no "Delete" button for a completed invoice, only a "Correction Memo" button.
- **Brute Force Protection:** If someone types the wrong password 5 times in a minute, the system locks them out temporarily.

---

## 17. Assumptions, Constraints, and Dependencies

| ID | Assumption | Impact if Wrong | Example |
|---|---|---|---|
| `ASM-01` | **Local Power:** The store has stable electricity or a UPS backup. | If power dies mid-sale, the current cart might be lost (though DB is safe). | Storm cuts power while cashier is typing a name. |
| `ASM-02` | **Windows OS:** Terminals are running Windows 10/11. | Software will not run on iPads or Android tablets natively. | Owner buys iPads; cannot install the POS. |
| `ASM-03` | **XAMPP Installed:** The local database engine (MariaDB) is running. | App will show "Offline/Database Error" on boot. | Staff accidentally uninstalls XAMPP. |

---

## 18. Edge Cases and Error Handling

| Edge Case ID | Scenario | Expected System Behavior | User Sees |
|---|---|---|---|
| `ERR-01` | **Internet Disconnects** | Background sync pauses. Local POS continues at 100% speed. | "Sync indicator turns Red." No interruption to checkout. |
| `ERR-02` | **Insufficient Stock** | System blocks the sale of an inventory-tracked item. | "Error: Not enough detergent in stock." |
| `ERR-03` | **Card Machine Fails** | Cashier must select a different payment type. | Cashier manually voids the card leg of the split payment and switches to Cash. |

---

## 19. Troubleshooting and FAQ

**Q: The screen says "Unable to connect to local database engine."**
A: Ensure XAMPP is open and the "MySQL" and "Apache" modules have a green background (are running).

**Q: The receipt printer is printing blank paper.**
A: The thermal paper roll is likely inserted upside down. Flip the roll.

**Q: I made a mistake on an order, how do I delete it?**
A: You cannot delete a confirmed order. You must ask a Manager to issue a "Correction Memo" to refund it.

---

## 20. Traceability Matrix

| Feature ID | Use Case ID | Workflow ID | User Flow ID | Permission ID |
|---|---|---|---|---|
| **F-01** (Offline POS) | UC-01 | WF-01 | UF-01 | `PRM-01` |
| **F-03** (Refunds) | UC-02 | WF-01 | UF-02 | `PRM-03` |
| **F-05** (Z-Report) | UC-03 | WF-01 | UF-02 | `PRM-04` |

---

## 21. Appendices

### Appendix A: Technical References (For IT only)
- Application Runtime: PHP 8.2 (Backend), Flutter Desktop (Frontend).
- Database: MariaDB 10.6+ (`DECIMAL(18,2)` columns).
- Precision Math: `bcmath` extension is strictly required for PHP.

---

## 22. Index

- **C:** Cash Drawer (Sec 6), Correction Memo (Sec 9, F-03), Customers (Sec 13)
- **O:** Offline Resilience (Sec 5, Sec 18)
- **P:** Permissions (Sec 8)
- **S:** Split Payments (Sec 9, F-02), Sync Engine (Sec 6, WF-02)
- **Z:** Z-Report (Sec 9, F-05)

---
*End of Document*