# LaundryPro UAE: Complete System Manual & Walkthrough

Welcome to the comprehensive handbook for **LaundryPro UAE**. This manual is designed for non-technical stakeholders, business owners, and operations managers. It details every feature, workflow, and user journey within the platform, explaining how the system operates in real-world scenarios.

---

## 1. System Overview

LaundryPro UAE is a specialized Point of Sale (POS) and Enterprise Resource Planning (ERP) system built for the garment care industry. 

### Key Capabilities
*   **Offline Resilience:** The application is installed directly on your Windows computers. If the internet goes down, your cashiers can continue serving customers, printing receipts, and opening the cash drawer. The system automatically syncs data when the connection returns.
*   **Financial Integrity:** Once an invoice is finalized, it cannot be deleted or altered. This ensures complete auditability and prevents fraud. Mistakes are handled through formal "Correction Memos."
*   **Hardware Integration:** Native support for ESC/POS receipt printers, barcode scanners for garment tracking, weight scales for "per kilo" services, and customer-facing displays.

---

## 2. User Roles & Permissions

The system uses strict Role-Based Access Control (RBAC). A user can only see and interact with features they have permission to access.

### Standard Roles

*   **System Administrator (`administrator`)**
    *   *Permissions:* Unrestricted access to all features (`*`).
    *   *Use Case:* The business owner or IT manager configuring the system, setting up hardware, or viewing top-level financial analytics.
*   **Store Manager (`manager`)**
    *   *Permissions:* Can manage inventory, approve expenses, authorize refunds, and view daily sales reports. Cannot alter global system settings or delete user accounts.
    *   *Use Case:* The branch manager handling daily operations, overseeing cashiers, and ordering supplies from vendors.
*   **Cashier (`cashier`)**
    *   *Permissions:* Can create sales drafts, accept payments, search for customers, and print receipts (`sales.create`, `customers.view`). Cannot view overall business profitability or access HR modules.
    *   *Use Case:* Front-desk staff greeting customers, taking garments, and processing transactions.
*   **Factory/Production Staff (`production`)**
    *   *Permissions:* Can update the status of garments (e.g., from "Washing" to "Ready for Collection") and generate batch transfer documents (Challans).
    *   *Use Case:* Staff in the back-room or central facility tracking the actual cleaning process.
*   **Delivery Driver (`driver`)**
    *   *Permissions:* Can view assigned delivery tasks and mark them as complete.
    *   *Use Case:* Drivers handling pickup and delivery routes.

---

## 3. Core Workflows & Features

### 3.1 The Sales & Checkout Workflow (Point of Sale)

The POS interface is designed for speed. 

**Scenario:** A customer walks in with 3 shirts for dry cleaning and 1 carpet for washing (priced per kilo).

1.  **Customer Identification:** The cashier searches for the customer by phone number. If it's a new customer, they are added instantly with basic details.
2.  **Item Entry:**
    *   The cashier taps "Dry Clean" -> "Shirt". They increase the quantity to 3.
    *   The cashier taps "Carpet Wash". The system prompts for a weight. The scale automatically inputs "4.5 kg", and the price is calculated based on the per-kilo rate.
3.  **Modifiers & Notes:** One shirt has a heavy wine stain. The cashier selects the shirt and applies a "Heavy Stain" modifier (which may add a small fee) and types a note: "Customer warned about potential color fade."
4.  **Drafting:** The order is saved as a "Draft." The system prints a preliminary ticket to attach to the garments.
5.  **Payment & Confirmation:** The customer pays via Credit Card. The cashier selects "Card" as the tender type. The system finalizes the invoice, opening the cash drawer (if cash was used), and prints the final customer receipt.

### 3.2 Advanced Garment Care (The Production Cycle)

Once garments are taken in, they move through the production lifecycle.

**Scenario:** Tracking garments through a central processing facility.

1.  **Sorting & Tagging:** Garments are tagged with unique barcodes.
2.  **Batch Transfer (Challans):** If garments need to move from a retail storefront to a central factory, the manager creates a "Challan" (a batch transfer document). The driver uses this document to verify the load.
3.  **Status Updates:** At the factory, a worker scans the garment barcode. The system updates the item's status from "Received" to "Processing."
4.  **Quality Check:** After cleaning, the garment is inspected. If it fails, it is placed on "Quality Hold" and re-routed for re-washing.
5.  **Ready for Collection:** Once packed, the status changes to "Ready." The system automatically sends an SMS to the customer notifying them their order is ready for pickup.

### 3.3 Inventory & Purchasing

Managing retail items (like detergents sold over the counter) and raw materials (chemicals used for cleaning).

**Scenario:** Restocking liquid detergent.

1.  **Low Stock Alert:** The store manager sees a notification that "Premium Liquid Detergent" has fallen below the minimum threshold.
2.  **Purchase Order:** The manager creates a Purchase Order (PO) for the vendor "Chemical Supplies LLC" for 50 bottles.
3.  **Receiving Stock:** The delivery arrives. The manager opens the PO in the system and marks it as "Received." The inventory levels are automatically increased by 50.
4.  **Sales Deduction:** Every time a cashier sells a bottle of detergent at the POS, the inventory is automatically reduced by 1.

### 3.4 Human Resources & Payroll

Managing staff shifts, leaves, and compensation.

**Scenario:** Processing monthly payroll with a salary advance.

1.  **Attendance:** Employees clock in and out daily using a PIN code at the terminal.
2.  **Salary Advance:** Mid-month, an employee requests a 500 AED advance. The manager approves it in the system. The amount is disbursed from the cash drawer (logging an expense).
3.  **Payroll Run:** At the end of the month, the manager clicks "Run Payroll." The system calculates the base salary, adds any overtime based on attendance records, and automatically deducts the 500 AED advance.
4.  **Payslips:** The system generates PDF payslips for distribution.

### 3.5 Accounting & Expense Management

Tracking money going out of the business.

**Scenario:** Paying a utility bill from the till.

1.  **Expense Creation:** The manager takes 200 AED from the cash drawer to pay the water bill. They log an expense in the system under the category "Utilities".
2.  **Approval:** Because the amount is small, it is auto-approved (based on business rules).
3.  **Financial Impact:** The system records the outflow. When the shift is closed, the system expects the physical cash drawer to have 200 AED less, ensuring cash reconciliation matches perfectly.

---

## 4. Key Assumptions & Safeguards

To maintain enterprise-grade reliability, LaundryPro UAE operates on several strict assumptions:

1.  **No Deletions (Soft Deletes Only):** To prevent accidental data loss or malicious tampering, users cannot permanently delete records (like old customers or past inventory movements). Records are instead marked as "inactive" and hidden from daily views.
2.  **Immutability of Sales:** Once an invoice is paid and confirmed, it is locked. If a cashier makes a mistake, they cannot "edit" the invoice. They must issue a formal refund or correction memo, leaving a clear paper trail.
3.  **Offline Integrity:** If the system is offline, cashiers can still create orders. However, they are warned that these orders are "pending sync." Complex operations that require centralized validation (like registering a new branch) require an active internet connection.
4.  **Device Binding:** Terminals (the physical computers) must be registered to a specific branch. A cashier logging into Terminal A will automatically be processing sales for Branch A.

---

## 5. End-to-End Walkthrough Example: A Day in the Life

**Morning (8:00 AM)**
*   The Manager unlocks the store.
*   Employees arrive and use the POS terminal to clock in via the HR module.
*   The Manager checks the Dashboard for any pending online orders (Customer Portal) and verifies the cash float in the drawer.

**Mid-Day (12:00 PM)**
*   The Cashier processes a steady stream of walk-in customers.
*   The internet provider has an outage. The POS displays a yellow "Offline" indicator, but the Cashier continues working without interruption. The local database securely stores all transactions.
*   A delivery driver arrives to pick up garments for the central factory. The Manager generates a Challan, prints it, and hands the garments over.

**Afternoon (3:00 PM)**
*   The internet comes back online. The Sync Engine immediately pushes the offline transactions to the server in the background. The "Offline" indicator turns green.
*   The Manager receives an automated notification that washing chemicals are running low and creates a Purchase Order.

**Evening (9:00 PM)**
*   The store closes. Employees clock out.
*   The Manager runs the "End of Day" report, counting the physical cash in the drawer and comparing it to the system's expected cash total (accounting for today's sales minus any petty cash expenses logged).
*   The system performs an automated encrypted backup of the day's data.

---

*This manual covers the core operational flows of LaundryPro UAE. For technical configuration, hardware setup, or API integration, please refer to the README and API_DOCS.*
