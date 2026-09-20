# LaundryPro UAE — Operator & Cashier User Manual

**Document Version:** 2.1 (Production Release)
**Product Version:** 1.2.1+4
**Target Audience:** Front-desk Cashiers, Store Operators, Laundry Floor Staff, Delivery Drivers

---

## Table of Contents
1. [Starting the Application](#1-starting-the-application)
2. [Splash Screen & Self-Healing Boot](#2-splash-screen--self-healing-boot)
3. [Logging In & Profile Switching](#3-logging-in--profile-switching)
4. [Instant Sale / Counter Point of Sale (POS)](#4-instant-sale--counter-point-of-sale-pos)
5. [Customer CRM & Walk-In Customers](#5-customer-crm--walk-in-customers)
6. [Thermal Receipt Printing & Cash Drawer](#6-thermal-receipt-printing--cash-drawer)
7. [Order Tracking & Processing Movement](#7-order-tracking--processing-movement)
8. [Factory Challans & Delivery Tasks](#8-factory-challans--delivery-tasks)
9. [Staff Attendance Clock-In / Clock-Out](#9-staff-attendance-clock-in--clock-out)
10. [End of Day Closing & Reports](#10-end-of-day-closing--reports)
11. [Offline Resilience & Recovery](#11-offline-resilience--recovery)
12. [Split Payments (Multi-Tender)](#12-split-payments-multi-tender)
13. [Hold & Resume Sales](#13-hold--resume-sales)
14. [Refunds & Correction Memos](#14-refunds--correction-memos)
15. [Keyboard Shortcuts](#15-keyboard-shortcuts)
16. [WhatsApp Receipt Sharing](#16-whatsapp-receipt-sharing)

---

## 1. Starting the Application

Launch LaundryPro UAE from your Windows Desktop shortcut or executable:

`
build\\windows\\x64\\runner\\Release\\laundrypro_uae.exe
`

Ensure that XAMPP (Apache and MySQL) is running on the computer before launching.

---

## 2. Splash Screen & Self-Healing Boot

When the program opens, a modern splash screen validates the system environment:

1. **Verifying Local Node Connectivity:** Checks if the local database and local web server are active.
   - *If offline:* The screen clearly displays: *Unable to connect to local database engine. Please verify XAMPP is running.* You can click **Retry** or **Exit Application**.
2. **Applying Database Upgrades:** Silently checks for pending database migrations and executes them automatically without operator intervention.
3. **Evaluating License & Machine ID:** Checks hardware UMAC and active license quotas.
4. **Cloud Background Handshake:** In the background, contacts the central cloud server to check for sync updates (never blocks offline usage).
5. **Dashboard Transition:** Opens the Login screen smoothly.

---

## 3. Logging In & Profile Switching

1. Enter your operator username and password:
   - **Default Admin:** dmin / dmin123
   - Passwords are case-sensitive. Contact your system administrator if locked out.
2. Select your preferred language:
   - **English (LTR)** or **العربية (Arabic RTL)**.
   - You can toggle language at any time from the top navigation bar.
3. To switch operator profiles mid-shift, click your name avatar in the top-right corner and select **Switch User** without closing the application.

---

## 4. Instant Sale / Counter Point of Sale (POS)

The POS interface is optimised for keyboard, mouse, and touchscreen operation:

1. **Select or Scan Customer:**
   - Use the Customer Search bar (by phone number, name, or code) or click **Walk-in Customer**.
2. **Add Laundry Items:**
   - Tap category buttons (Dry Clean, Wash & Fold, Steam Press, Curtain Care).
   - Click services or scan item barcodes.
   - Adjust quantities using the on-screen keypad (+ / -).
3. **Apply Modifiers & Urgency:**
   - Express Service (+50%), Fragrance, Stiff Starch, Stain Treatment.
4. **Collect Payment:**
   - Choose Payment Method: **Cash**, **Card / Terminal**, **Credit (Account)**, or **Split** (see Section 12).
   - If paying Cash, enter tender amount; the system calculates exact change in AED & Fils.
5. **Finalize Order:**
   - Click **Confirm & Print**. The thermal receipt prints immediately and the cash drawer kicks open.

---

## 5. Customer CRM & Walk-In Customers

1. Navigate to **Customers** on the left navigation rail.
2. Click **New Customer** (F2):
   - Enter Full Name, UAE Mobile Number (+971 50 ...), TRN (if corporate), Delivery Address, Villa/Flat No.
3. View order history, unpaid ledger balances, and loyalty points.

---

## 6. Thermal Receipt Printing & Cash Drawer

- **Printer Models Supported:** Standard 80 mm and 58 mm ESC/POS thermal receipt printers (Epson, Citizen, Bixolon, Xprinter).
- **Cash Drawer:** Automatically pops open via RJ11 pulse on cash transactions.
- **Reprint Receipt:** Open any past order and click **Reprint Receipt** (Ctrl+P).
- **Test Print:** Navigate to **Settings > Peripherals > Test Print** to verify printer alignment.

---

## 7. Order Tracking & Processing Movement

Track order progress through 4 standard stages:

1. **Received (Counter):** Items tagged and bagged.
2. **In Processing (Washing/Dry Cleaning):** Items in wash or dry clean cycle.
3. **Ready for Pickup / Delivery:** Ironed, packaged, and inspected by QC.
4. **Delivered / Completed:** Customer collected or driver delivered.

Status changes are logged with operator name and timestamp for full auditability.

---

## 8. Factory Challans & Delivery Tasks

- **Challans:** For laundries with an off-site central factory, generate a batch transfer Challan with line counts and barcodes for the transport driver.
- **Home Deliveries:** View scheduled deliveries, assign to drivers, and mark completed upon drop-off.

---

## 9. Staff Attendance Clock-In / Clock-Out

1. Navigate to **HR & Attendance**.
2. Staff member selects their profile or scans their employee barcode badge.
3. Tap **Clock In** at the start of shift and **Clock Out** at the end of shift.
4. Records are automatically compiled for monthly UAE Labour Law compliant payroll.

---

## 10. End of Day Closing & Reports

At the end of your shift:
1. Navigate to **Reports** > **Daily Sales Summary**.
2. Verify:
   - Total Cash in Drawer
   - Total Card Payments
   - Total Outstanding Invoices
3. Print the **Shift End / Z-Report** for the store manager.
4. For full shift reconciliation with variance logging, see Section 13: Hold & Resume Sales actually see Shift Close (UC-13 in Blueprint).

---

## 11. Offline Resilience & Recovery

- **Zero Cloud Dependence:** You can continue booking orders, printing receipts, and collecting payments even if the internet is completely disconnected.
- When internet returns, the background sync engine seamlessly uploads records to the central cloud.
- The status bar at the bottom of every screen shows a **Sync Status** indicator:
  - Green dot: All records synced.
  - Amber dot: Pending records in outbox (syncing shortly).
  - Red dot: Offline; records queued locally.

---

## 12. Split Payments (Multi-Tender)

Use Split Payment when a customer wants to settle an invoice with more than one payment method (e.g., part cash, part card).

**Steps:**

1. Build the cart and proceed to **Checkout** as normal.
2. Instead of selecting a single payment method, click **Split Payment**.
3. The Split Payment panel opens showing the full invoice total.
4. Enter the **Cash amount** the customer is paying (e.g., 100.00 AED).
   - The panel automatically shows the **Remaining Balance** (e.g., 110.00 AED).
5. Select the second method for the remaining balance: **Card / Terminal**, **Credit (Account)**, or a third split.
6. For Card: confirm the physical terminal has approved the charge, then click **Card Approved**.
7. Verify the running total matches the invoice total (the **Finalize** button only activates when fully balanced).
8. Click **Finalize Split Payment**.
9. A **single consolidated receipt** prints listing all payment legs.
10. The cash drawer opens only if a cash leg was included.

> **Note:** Change is only calculated and given on the **cash leg**. Card and account legs must be exact amounts.

---

## 13. Hold & Resume Sales

Hold an in-progress cart without losing its contents — useful when a customer needs to step aside or fetch more items.

**To Hold a Sale:**

1. While on the active cart screen, press **Ctrl+H** or click the **Hold Cart** icon (pause symbol) in the toolbar.
2. Enter an optional **Hold Note** (e.g., “customer fetching more garments”).
3. Click **Hold**. The cart is saved and the POS clears to accept a new customer.

**To Resume a Held Sale:**

1. Click the **Held Orders** tray icon in the top navigation bar (shows count badge).
2. Select the held cart from the list.
3. Click **Resume** — the cart reloads with all items, customer details, and modifiers intact.
4. Continue checkout as normal.

> **Important:** Held carts do not generate an invoice or reserve stock. They are session-level holds. If the application is closed, held carts are discarded.

---

## 14. Refunds & Correction Memos

LaundryPro UAE never modifies or deletes an original invoice. All refunds and corrections are handled through a **Correction Memo** (Credit Memo) that links back to the original order.

**Steps to Issue a Correction Memo:**

1. Navigate to **Orders** and search for the original order by number, customer name, or date.
2. Open the order detail view.
3. Click **Issue Correction Memo** (requires Manager role or above).
4. In the dialog:
   - Select the line items to refund (full or partial lines).
   - Enter the **refund reason** (mandatory field).
   - Choose the **refund method**: Cash Return, Account Credit, or Voucher.
5. Click **Confirm Memo**.
6. The system creates a **Credit Memo** (e.g., #CM-2026-00019) with a negative total referencing the original order.
7. A **Correction Memo receipt** prints automatically, clearly headed:

   `
   CORRECTION MEMO — NOT AN INVOICE
   Ref. Original Order: LP-2026-00109
   `

8. Return cash to the customer or apply the credit to their account.

> **Key Rules:**
> - The original invoice remains unchanged and visible in history.
> - Only managers and above can issue correction memos.
> - Partial refunds are allowed; you cannot refund more than the original line quantity.

---

## 15. Keyboard Shortcuts

Keyboard shortcuts accelerate high-volume counter operations. All shortcuts are active when the POS or Orders screen is in focus.

| Shortcut | Action |
|---|---|
| **F1** | Open Help / This Manual |
| **F2** | New Customer |
| **F3** | Customer Search |
| **F4** | New Order / Open Cart |
| **F5** | Refresh Current Screen |
| **F6** | Apply Express (+50%) modifier to selected line |
| **F8** | Void / Remove selected cart line |
| **F9** | Open Cash Drawer (manual pulse) |
| **F10** | Proceed to Checkout |
| **F11** | Toggle Full-Screen Mode |
| **F12** | Reprint Last Receipt |
| **Ctrl+H** | Hold Current Cart |
| **Ctrl+P** | Print / Reprint Receipt |
| **Ctrl+R** | Open Refund / Correction Memo |
| **Ctrl+Z** | Undo Last Item Add (cart only) |
| **Ctrl+S** | Save Draft (hold cart silently) |
| **Ctrl+Shift+S** | Shift Close Screen |
| **Ctrl+W** | Send WhatsApp Receipt (see Section 16) |
| **Escape** | Cancel current dialog / close panel |
| **Enter** | Confirm active dialog / proceed |
| **+** / **-** | Increase / Decrease selected item quantity |
| **Numpad 0–9** | Quick quantity entry on focused line |

---

## 16. WhatsApp Receipt Sharing

Send a digital receipt directly to the customer\'s WhatsApp number immediately after payment.

**After completing a sale:**

1. The post-payment confirmation screen shows a **Send WhatsApp Receipt** button (or press **Ctrl+W**).
2. Verify the customer\'s UAE mobile number displayed (pre-filled from the customer record).
3. Click **Send via WhatsApp**.
4. The system constructs a WhatsApp deep-link with the receipt summary pre-filled in the message body:
   `
   https://wa.me/971501234567?text=LaundryPro+UAE+Receipt+%23LP-2026-00109...
   `
5. Windows opens the WhatsApp Desktop app (or WhatsApp Web in browser).
6. Review the pre-filled message and click **Send** in WhatsApp.

**To share a receipt for a past order:**

1. Open the order in **Orders > Order Detail**.
2. Click the **WhatsApp** icon in the action bar.
3. Follow steps 2–6 above.

> **Note:** WhatsApp sharing uses the standard wa.me deep-link protocol and requires WhatsApp Desktop or WhatsApp Web to be installed and logged in on the workstation. An active internet connection is required for WhatsApp delivery; the local POS operates fully without it.
