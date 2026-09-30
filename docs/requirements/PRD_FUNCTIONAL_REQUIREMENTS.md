# LaundryPro UAE — Product Requirements Document (PRD)

> **Version:** 2.0.0 | **Authoritative Product Specification** | **Status:** Approved for Implementation

---

## 1. Product Scope & Vision

LaundryPro UAE is an offline-first enterprise management system designed specifically for the United Arab Emirates textile care industry (dry cleaners, commercial laundries, hotel linen services, and boutique garment care). It bridges high-speed, zero-latency front-desk POS operations with central multi-tenant cloud reporting and automated compliance with UAE tax (FTA VAT) and labor regulations (MOHRE WPS).

---

## 2. Functional Requirements by Module

### FR-1: Point of Sale (POS) & Intake Operations
- **FR-1.1**: The system must allow cashiers to complete a customer garment intake in under **30 seconds**.
- **FR-1.2**: Cashiers must be able to search customers by 10-digit UAE phone number (`05x...`), customer name, or barcode card.
- **FR-1.3**: The system must support item-specific modifiers (e.g., Starch: None/Light/Medium/Heavy; Hanger: Wire/Wooden/Folded; Treatment: Stain Removal).
- **FR-1.4**: The system must support turnaround service tier selection: Standard (48 hrs), Express (24 hrs, +25%), Urgent (4 hrs, +50%).
- **FR-1.5**: Upon order confirmation, the system must trigger simultaneous printing of customer intake receipts and water-resistant care tags.

### FR-2: UAE Billing & Invoicing Compliance
- **FR-2.1**: Invoices must be fully bilingual (Arabic and English) with right-to-left layout compliance for Arabic text.
- **FR-2.2**: The system must calculate standard 5% UAE VAT with exact precision using string math (`bcmath`), preventing penny rounding errors.
- **FR-2.3**: Every invoice must include a dynamic FTA TLV-encoded Base64 QR code verifiable by FTA inspection scanners.
- **FR-2.4**: In the event of an order cancellation or return, the system must generate a formal FTA Tax Credit Note referencing the original invoice.

### FR-3: Central Factory Logistics & Challans
- **FR-3.1**: The system must group tagged garments into numbered Factory Dispatch Challans for van transfer.
- **FR-3.2**: Factory intake must support barcode batch scanning to verify garment count against the dispatch manifest.
- **FR-3.3**: Returning factory van manifests must reconcile received clean items and flag any missing garments.

### FR-4: Human Resources & WPS Payroll
- **FR-4.1**: The system must track employee clock-in and clock-out with hardware terminal identification.
- **FR-4.2**: The system must generate the standard UAE Wages Protection System (WPS) SIF file formatted for bank and exchange house submission.
- **FR-4.3**: End-of-service gratuity (EOSG) calculations must strictly adhere to UAE Labor Law (Decree-Law No. 33 of 2021).

### FR-5: Offline-First Synchronization Engine
- **FR-5.1**: All POS transactions, receipts, and order updates must execute locally with **zero dependency on internet connectivity**.
- **FR-5.2**: The background sync daemon must continuously poll for internet access and transmit queued outbox mutations to the Cloud API.
- **FR-5.3**: Concurrent edits must be resolved via the 3-way merge conflict engine without user interruption.

---

## 3. Non-Functional Requirements (NFR)

| Metric | Target Requirement | Verification Method |
|---|---|---|
| **POS Transaction Latency** | $< 200\text{ ms}$ from tap to receipt print | Stopwatch & telemetry profiler |
| **Offline Availability** | 100% functionality during complete network disconnection | Simulated air-gapped test bench |
| **Data Recovery Time (RTO)** | $< 15\text{ minutes}$ from total hardware destruction | Full restore from cloud snapshot |
| **Data Recovery Point (RPO)** | Zero lost committed transactions ($RPO = 0$) | Write-ahead logging & outbox verification |
| **System Security** | Argon2id password hashing, RS256 JWT, write-once anti-tamper | Third-party penetration testing |
