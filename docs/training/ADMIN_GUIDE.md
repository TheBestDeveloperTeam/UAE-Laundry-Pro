# LaundryPro UAE — Store Administrator & Manager Guide

> **Version:** 2.0.0 | **Authoritative Operations Manual**

---

## 1. Store Management Portal Overview

The Local Admin Portal (`http://localhost:8080/admin`) provides store managers with real-time operational control over catalog pricing, customer accounts, staff attendance, inventory levels, and financial audits.

---

## 2. Day-to-Day Manager Responsibilities

### 2.1 Daily Morning Opening Checklist
1. **System Health Verification**: Check the top-bar status pill. Ensure both MariaDB database and Cloud Sync daemon indicate `Connected (Green)`.
2. **Till Float Reconciliation**: Verify that the opening cash float in the cash drawer matches the amount entered by the opening cashier.
3. **Dispatch Manifest Review**: Inspect orders scheduled for central factory pickup. Ensure all bags are sealed with Challan barcodes attached.

### 2.2 Catalog & Pricing Management
To adjust service prices or add seasonal laundry packages:
1. Navigate to **Catalog $\rightarrow$ Services**.
2. Click **Edit** on the target service (e.g., "Men's Kandora - Dry Clean").
3. Update base rate, express surcharge percentage, and standard turnaround hours.
4. Click **Save Changes**. The update automatically syncs to all local POS terminals.

### 2.3 Inventory Auditing & Purchase Orders
1. Review stock levels under **Inventory $\rightarrow$ Stock on Hand**.
2. When detergent, poly-rolls, or hangers hit the `Reorder Point`, generate a Purchase Order under **Purchasing $\rightarrow$ New PO**.
3. Select the supplier, input line quantities, and email the PO directly from the portal.
4. Upon delivery, click **Receive Goods (GRN)** to automatically adjust stock balances and credit the vendor ledger.

### 2.4 Staff Attendance & Payroll Review
1. Review biometric clock-in logs under **HR $\rightarrow$ Attendance**.
2. Approve leave requests and authorize salary advances.
3. At month-end, click **Payroll $\rightarrow$ Run Payroll** to review salary breakdowns and export the UAE WPS SIF file for bank transfer.

---

## 3. Resolving Sync Conflicts & Cloud Status

If a network outage occurred and the Cloud Sync badge indicates `Conflict Pending`:
1. Navigate to **System $\rightarrow$ Sync Inspector $\rightarrow$ Conflict Queue**.
2. Compare the **Local Version** and **Cloud Version** in the visual side-by-side diff viewer.
3. Click **Accept Local**, **Accept Cloud**, or manually select the correct field value.
4. Click **Resolve & Re-Sync** to clear the conflict.
