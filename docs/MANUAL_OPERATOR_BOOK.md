# LaundryPro UAE — Operator & Cashier User Manual

**Document Version:** 2.0 (Production Release)  
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

---

## 1. Starting the Application

Launch LaundryPro UAE from your Windows Desktop shortcut or executable:
uild\windows\x64\runner\Release\laundrypro_uae.exe

Ensure that XAMPP (Apache and MySQL) is running on the computer.

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
2. Select your preferred language:
   - **English (LTR)** or **العربية (Arabic RTL)**.
   - You can toggle language at any time from the top navigation bar.

---

## 4. Instant Sale / Counter Point of Sale (POS)

The POS interface is optimized for keyboard, mouse, and touchscreen operation:

1. **Select or Scan Customer:**
   - Use the Customer Search bar (by phone number, name, or code) or click **Walk-in Customer**.
2. **Add Laundry Items:**
   - Tap category buttons (Dry Clean, Wash & Fold, Steam Press, Curtain Care).
   - Click services or scan item barcodes.
   - Adjust quantities using the on-screen keypad (+ / -).
3. **Apply Modifiers & Urgency:**
   - Express Service (+50%), Fragrance, Stiff Starch, Stain Treatment.
4. **Collect Payment:**
   - Choose Payment Method: **Cash**, **Card / Terminal**, **Credit (Account)**.
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

- **Printer Models Supported:** Standard 80mm and 58mm ESC/POS thermal receipt printers (Epson, Citizen, Bixolon, Xprinter).
- **Cash Drawer:** Automatically pops open via RJ11 pulse on cash transactions.
- **Reprint Receipt:** Open any past order and click **Reprint Receipt** (Ctrl+P).

---

## 7. Order Tracking & Processing Movement

Track order progress through 4 standard stages:
1. **Received (Counter):** Items tagged and bagged.
2. **In Processing (Washing/Dry Cleaning):** Items in wash or dry clean cycle.
3. **Ready for Pickup / Delivery:** Ironed, packaged, and inspected by QC.
4. **Delivered / Completed:** Customer collected or driver delivered.

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

---

## 11. Offline Resilience & Recovery

- **Zero Cloud Dependence:** You can continue booking orders, printing receipts, and collecting payments even if the internet is completely disconnected.
- When internet returns, the background sync engine seamlessly uploads records to the central cloud.