# LaundryPro UAE â€” Super-Admin & Cloud Portal Guide

**Document Version:** 2.0 (Production Release)  
**Target Audience:** Magnificent Solution System Administrators, Cloud Operators, Franchise IT Heads  

---

## Table of Contents
1. [Cloud Architecture & Security Overview](#1-cloud-architecture--security-overview)
2. [Accessing the Super-Admin Web Portal](#2-accessing-the-super-admin-web-portal)
3. [Dashboard Metrics & Operational Telemetry](#3-dashboard-metrics--operational-telemetry)
4. [Tenant & Client Laundry Node Management](#4-tenant--client-laundry-node-management)
5. [Cryptographic License Issuance & Management](#5-cryptographic-license-issuance--management)
6. [Offline License Request Processing (laundrypro_req.lic)](#6-offline-license-request-processing-laundrypro_reqlic)
7. [Remote Revocation & Kill-Switch](#7-remote-revocation--kill-switch)
8. [Real-time Sync Payload Stream Inspector](#8-real-time-sync-payload-stream-inspector)
9. [System Audit Trail & Security Logs](#9-system-audit-trail--security-logs)
10. [Database Backup & Maintenance](#10-database-backup--maintenance)

---

## 1. Cloud Architecture & Security Overview

The Central Cloud API & Super-Admin Web Portal resides in cloud-api/ and is designed for standard cPanel shared hosting or Linux Apache servers:
- **Framework:** Pure PHP 8.2 with PDO MariaDB/MySQL.
- **Frontend UI:** AdminLTE v4 (Bootstrap 5, FontAwesome/Bootstrap Icons).
- **Public Root:** cloud-api/public/ (accessible via VirtualHost or sub-folder).
- **Database:** laundrypro_cloud.

---

## 2. Accessing the Super-Admin Web Portal

1. Navigate to:
   http://localhost/cloud-api/public/admin or http://cloud-api/admin  
   (Production URL: https://www.laundrypro-cloudapi.magnificentsolution.co.in/admin)
2. Enter your super-admin credentials:
   - **Username:** superadmin
   - **Password:** SuperAdmin@LaundryPro2026!
3. The session is protected by cryptographic cookie signatures and CSRF tokens.

---

## 3. Dashboard Metrics & Operational Telemetry

The executive dashboard displays:
- **Total Registered Tenants:** Count of laundry business nodes.
- **Active Licenses:** Count of valid, unexpired licenses.
- **Total Sync Events:** All-time ingested data records.
- **24-Hour Telemetry:** Pushes, orders, and pings received in the last 24 hours.
- **Recent Tenants Table:** Quick links to client profiles and activation statuses.

---

## 4. Tenant & Client Laundry Node Management

Navigate to **Tenants** in the sidebar:
1. **View Tenants:** View all registered laundry owners, trade license numbers, contact info, and node status.
2. **Cloud Tokens:** Each tenant has an auto-generated high-entropy Bearer token (	oken_...) used by their local XAMPP node for authentication.
3. **Status Control:** Toggle status between **Active**, **Suspended**, or **Archived**.

---

## 5. Cryptographic License Issuance & Management

Navigate to **Licenses** in the sidebar:
1. Click **Issue New License**.
2. Select the client **Tenant / Business**.
3. Choose Plan:
   - **Standard** (Full features, 1 year validity)
   - **Enterprise** (Multi-branch, unlimited terminals)
   - **Trial / Evaluation** (7 days, 9 invoices quota)
4. Enter target hardware **UMAC Code** (e.g., UMAC-8F2A-49C1-77B0).
5. Click **Generate License**.
6. The system generates a cryptographically signed license key:
   LP-1A2B3C4D-5E6F-7G8H
   which is returned to the client.

---

## 6. Offline License Request Processing (laundrypro_req.lic)

For client machines without internet access:
1. Client generates laundrypro_req.lic from the Flutter License Screen.
2. Client sends this file to Magnificent Solution support.
3. Super-Admin opens the License Generator, inputs the client details and hardware UMAC from the file.
4. Download the signed laundrypro_license.lic file and return it to the client.
5. Client imports the file into their desktop app to unlock permanent operation.

---

## 7. Remote Revocation & Kill-Switch

If a client terminates their contract or fails payment:
1. Navigate to **Licenses**.
2. Locate the client license and click **Revoke License**.
3. On the next cloud handshake (or sync attempt), the local node receives the revocation signal and locks POS transaction capabilities.

---

## 8. Real-time Sync Payload Stream Inspector

Navigate to **Sync Records** in the sidebar:
- Inspect inbound JSON payloads stream pushed by client workstations.
- Filter by Tenant, Entity Type (customer, sales_order, payment, expense).
- View exact timestamps, local record IDs, and payload snapshots for technical troubleshooting.

---

## 9. System Audit Trail & Security Logs

Navigate to **Audit Logs**:
- Every super-admin login, tenant creation, license issuance, and revocation is recorded with:
  - Admin User ID
  - Action Name
  - Timestamp
  - Client IP Address
  - Action Details

---

## 10. Database Backup & Maintenance

The cloud database laundrypro_cloud should be backed up using mysqldump:
`ash
mysqldump -u root -p laundrypro_cloud > laundrypro_cloud_backup_.sql
`