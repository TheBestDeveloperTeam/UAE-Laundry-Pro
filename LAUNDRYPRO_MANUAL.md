# LaundryPro UAE: Comprehensive Application Manual & Walkthrough

Welcome to the **LaundryPro UAE Complete Handbook**. This manual is designed for owners, managers, cashiers, and technical staff to understand the complete functionality, architecture, workflows, and rules of the system. 

LaundryPro UAE is an offline-first POS (Point of Sale) and ERP (Enterprise Resource Planning) system explicitly tailored for modern laundry businesses.

## 1. System Overview and Assumptions

### What is LaundryPro UAE?
LaundryPro UAE is designed for environments where the internet might be unstable. It operates on a Windows Desktop machine locally. 
- The **backend** is powered by a high-performance PHP 8.2 micro-framework with a local MariaDB database.
- The **frontend** is a responsive Flutter application designed for touch screens and keyboard/mouse setups.
- A **cloud synchronization engine** works in the background to push data to the main server when the internet is restored.

### Core Assumptions & Non-Negotiable Rules
- **No Monetary Data Loss:** The system calculates money using high-precision decimal math. No floats are used anywhere.
- **Audit Trails:** Everything from deleting an invoice to changing the temperature on a washing cycle is logged.
- **Additive Migrations:** The database is designed so data is never truly "lost" when updates happen.
- **Offline First:** The cashier must be able to ring up customers, print invoices, and open the cash drawer even if the internet is completely disconnected.

## 2. User Roles and Permissions

LaundryPro uses a robust Role-Based Access Control (RBAC) system. Every user logs in with an explicit token. 

### Roles
1. **Admin / Owner** 
   - *Permissions:* Can access all settings, create new users, modify inventory, run backups, and override prices.
   - *Use Case:* Setting up the business initially, closing the register at the end of the day, reviewing the Profit & Loss (P&L) statements.

2. **Manager**
   - *Permissions:* Can approve expenses, manage employees, view payroll, and refund customers. Cannot alter the core settings or run database migrations.
   - *Use Case:* Overseeing daily operations, managing customer complaints, handling cash drop-offs.

3. **Cashier**
   - *Permissions:* Can create sales drafts, confirm orders, accept payments, and add new customers. 
   - *Restrictions:* Cannot view business analytics, cannot delete invoices, cannot perform backups.
   - *Use Case:* The person standing at the front desk greeting customers and taking clothes.

4. **Operator / Driver**
   - *Permissions:* Specifically tailored for managing production cycles or delivery routes. 
   - *Use Case:* The delivery driver checking off "Challans" (delivery batches) on their tablet or the washing machine operator recording the pH levels of a wash.

## 3. Core Workflows with Examples

### A. The Front-Desk Workflow: Creating a Sale
*Scenario:* A customer walks in with 3 shirts for dry cleaning.

1. **Customer Selection:** The cashier clicks "New Order." They search for the customer by phone number. If the customer is new, they quickly add them (Name and Phone required).
2. **Item Entry:** The cashier taps "Dry Cleaning" -> "Shirt". They change the quantity to 3.
3. **Drafting:** The system creates a "Sales Draft." The items are not yet confirmed, allowing the cashier to modify quantities or apply a discount if the manager approves.
4. **Confirmation:** The cashier hits "Confirm Order." The system locks the prices. The order is now an official invoice.
5. **Payment:** The customer hands over cash. The cashier enters the amount received. The system calculates change, records a "Payment Transaction," and triggers the receipt printer.

### B. The Production Workflow: Advanced Garment Care
*Scenario:* The 3 shirts need to go through a specialized "Delicate Wash" cycle.

1. **Starting the Cycle:** The Operator goes to the "Advanced Cycles" screen. They scan the barcode on the garment tag (Sale ID). They select "Delicate Wash Preset" and the specific washing machine (Equipment ID).
2. **Recording Metrics:** Halfway through the wash, the system prompts for a quality check. The operator checks the water and logs a "pH Level" of 7.2 in the "Process Logs" tab.
3. **Completion:** The wash is done. The operator marks the cycle as "Completed." The system automatically logs who did the wash, on what machine, and the exact timestamp.

### C. The Inventory Workflow: Receiving Detergent
*Scenario:* A vendor drops off 10 bottles of specialized detergent.

1. **Purchase Order (PO):** The Manager goes to "Purchasing" and creates a PO for the vendor.
2. **Receiving Items:** When the delivery arrives, the Manager clicks "Receive Items" against the PO. 
3. **Stock Update:** The system adds 10 bottles to the local inventory. This transaction is permanently recorded in the "Inventory Movements" ledger.
4. **Usage:** As cycles are run, detergent is automatically deducted from stock based on the preset configurations. 

## 4. Feature Deep Dives

### Multi-Branch and Cloud Sync
- **How it works:** The `sync_outbox` table securely queues every transaction. When the background sync worker runs (every few minutes), it securely pushes these to the central cloud.
- **Example:** If branch A creates a new customer, Branch B will see that customer once both branches sync with the cloud.

### Deliveries & Challans
- **Challans:** A Challan is a manifest of items being moved. If you are sending 50 garments to a central factory for washing, you create a Challan. The driver signs it, and the factory acknowledges receipt. This ensures zero lost garments.
- **Route Delivery:** Drivers use the "Delivery Tasks" feature to see a prioritized list of customer locations for drop-offs, optimized by the system.

### Payroll & HR
- **Attendance:** Staff clock in and out using a PIN or RFID card.
- **Salary Advances:** If an employee requests an advance, the manager can approve it. 
- **Payroll Run:** At the end of the month, the system automatically calculates salaries, deducts the approved advances, adds overtime, and generates a payroll report.

### Offline Resilience & Backups
- **Local Database:** You never see a "Connecting to server..." loading spinner when ringing up a customer. 
- **Automatic Backups:** The system creates encrypted `.zip` backups locally. If the computer crashes, a new computer can be restored instantly using this file.
- **Verification:** The "Backup Verify" feature ensures the backup file isn't corrupted before relying on it.

## 5. Security & Licensing

- **Tamper Protection:** If a user tries to modify the local SQLite/MariaDB database directly using a third-party tool, the sync engine will detect the signature mismatch and flag the branch for an audit.
- **Rate Limiting:** To prevent brute-force attacks on the manager's password, the system locks login attempts after 5 failures in 1 minute.
- **Licensing:** The software requires a valid license key (checked against the cloud). If the license expires, the system drops into a "Read-Only" mode where sales are blocked but historical data is still accessible.

## 6. End-to-End Walkthrough (The "Perfect Day")

1. **8:00 AM:** The manager opens the store, turns on the computer. The system boots in 2 seconds. The manager checks the **Health Screen** to ensure the receipt printer and cloud sync are green.
2. **8:15 AM - 12:00 PM:** Cashiers take 50 orders. The system works flawlessly offline even when the local ISP goes down at 10 AM.
3. **1:00 PM:** The driver arrives. The manager generates a **Challan** for 100 dirty garments. The driver takes them to the factory.
4. **3:00 PM:** The factory receives the garments, runs **Advanced Cycles**, and logs the metrics.
5. **5:00 PM:** The clean garments return. They are scanned in via the **Barcode Scanner**. The system automatically sends a WhatsApp/SMS notification to the 50 customers: "Your clothes are ready!"
6. **6:00 PM - 8:00 PM:** Customers pick up their clothes and pay the remaining balances.
7. **9:00 PM:** The manager runs the **End of Day Report**. It matches the cash drawer perfectly. The manager triggers a **Manual Backup** to a USB drive and closes the store.

---
*Generated by Antigravity AI - System Documentation Module*
