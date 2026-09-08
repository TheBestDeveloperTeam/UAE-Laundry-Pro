# Dependency Graphs & Interaction Topologies

This document provides visual Mermaid architectural graphs capturing component relationships, data flows, and runtime dependencies for **LaundryPro UAE**.

---

## 1. High-Level System Architecture & Boundaries

`mermaid
graph TB
    subgraph Client Workstation [Local Windows Workstation]
        UI[Flutter Windows Desktop UI<br/>(Provider / MVVM / GoRouter)]
        Peripherals[Hardware Layer<br/>(ESC/POS 80mm Printer / Scanner / Cash Drawer)]
        LocalApache[Apache Web Server<br/>(VirtualHost: laundrypro-localapi)]
        LocalPHP[Pure PHP 8.2 Local API<br/>(api/src - 150+ Endpoints)]
        LocalDB[(MariaDB/MySQL<br/>Database: laundrypro)]
        SystemGuard[SystemGuardService<br/>(UMAC + HKCU Registry Heartbeat)]
        
        UI -->|ESC/POS Raw Bytes| Peripherals
        UI -->|HTTP JSON / Bearer JWT| LocalApache
        LocalApache --> LocalPHP
        LocalPHP -->|PDO MySQL| LocalDB
        UI -->|Hardware Identity Check| SystemGuard
    end

    subgraph Central Cloud [Central Multi-Tenant Cloud Platform]
        CloudApache[Apache / cPanel Web Server<br/>(cloud-api/public)]
        CloudAPI[Pure PHP 8.2 Cloud API<br/>(cloud-api/src)]
        AdminLTE[Super-Admin Web Portal<br/>(AdminLTE v4 / Bootstrap 5)]
        CloudDB[(MariaDB/MySQL<br/>Database: laundrypro_cloud)]
        
        CloudApache --> CloudAPI
        CloudApache --> AdminLTE
        CloudAPI -->|PDO MySQL| CloudDB
        AdminLTE -->|Session Auth| CloudDB
    end

    %% Cross-boundary communication
    LocalPHP -->|Outbox Sync / Handshake<br/>HTTPS + X-Business-Owner-Id| CloudAPI
    UI -.->|Background Online Check| CloudAPI
`

---

## 2. Flutter Desktop MVVM Layer Hierarchy

`mermaid
graph TD
    subgraph Presentation Layer
        Views[Screens & Views<br/>(POS, CRM, Delivery, Attendance, License, Settings)]
        Widgets[Reusable UI Widgets<br/>(MetricCards, OrderCartTable, CustomerPicker)]
    end

    subgraph State & ViewModel Layer
        AuthVM[AuthProvider]
        LocaleVM[LocaleProvider]
        PosVM[PosProvider / OrderState]
        SyncVM[SyncProvider]
        GuardVM[SystemGuardProvider]
    end

    subgraph Service & Repository Layer
        ApiClient[ApiClient / HttpInterceptor]
        PrintService[PeripheralPrintService / PosReceiptBuilder]
        ScannerService[ScannerService / RawKeyboardListener]
        LicenseClient[SystemGuardService / WmiHardwareIdentity]
    end

    subgraph Local Native Windows OS
        WinSpooler[win32 Spooler / PrintQueue]
        WinRegistry[HKCU Registry Heartbeat]
        WMI[Win32_Processor / Win32_BaseBoard]
    end

    Views --> State & ViewModel Layer
    Widgets --> State & ViewModel Layer
    State & ViewModel Layer --> Service & Repository Layer
    PrintService --> WinSpooler
    LicenseClient --> WinRegistry
    LicenseClient --> WMI
    ApiClient -->|REST API Calls| LocalApache
`

---

## 3. Local API Request Pipeline & Dependency Flow

`mermaid
sequenceDiagram
    autonumber
    actor Flutter as Flutter App
    participant Router as Core/Router.php
    participant Auth as Middleware/JwtMiddleware.php
    participant Guard as Middleware/PermissionMiddleware.php
    participant Controller as Controllers/*Controller.php
    participant Repo as Repositories/*Repository.php
    participant DB as MariaDB (laundrypro)
    participant Outbox as sync_outbox Table

    Flutter->>Router: POST /api/v1/sales/orders (Payload + Bearer Token)
    Router->>Auth: Validate JWT & Expiration
    Auth-->>Router: Authorized (User Context)
    Router->>Guard: Check RBAC Permission ('sales.create')
    Guard-->>Router: Permission Granted
    Router->>Controller: SalesController::store(Request)
    Controller->>Repo: Begin Transaction
    Repo->>DB: INSERT INTO sales_orders & sales_order_lines
    Repo->>DB: INSERT INTO payment_transactions
    Repo->>Outbox: INSERT INTO sync_outbox (Payload Snapshot)
    Repo->>DB: Commit Transaction
    Controller-->>Flutter: 200 OK (Envelope: success, code, data, meta)
`

---

## 4. Hardware Peripheral Integration Pipeline

`mermaid
graph LR
    subgraph Input Devices
        BarScanner[Handheld Barcode Scanner]
    end

    subgraph Flutter Processing
        KeyWedge[Keyboard Wedge Listener]
        Parser[Code128 / QR Parser]
        PosCart[POS Cart State Machine]
    end

    subgraph Output Devices
        ThermalPrint[ESC/POS Thermal Printer (80mm/58mm)]
        CashDrawer[RJ11 Cash Drawer]
    end

    BarScanner -->|HID Keystroke Stream| KeyWedge
    KeyWedge --> Parser
    Parser -->|Add Line Item| PosCart
    PosCart -->|Generate ESC/POS Bytes| ThermalPrint
    ThermalPrint -->|Kick Pin 2 Pulse (ESC p 0 25 250)| CashDrawer
`

---

## 5. Multi-Tenant Cloud Synchronization Topology

`mermaid
graph TD
    subgraph Local Node A [Laundry Branch 1]
        OutboxA[Local sync_outbox]
        DaemonA[sync_scheduler.php]
    end

    subgraph Local Node B [Laundry Branch 2]
        OutboxB[Local sync_outbox]
        DaemonB[sync_scheduler.php]
    end

    subgraph Central Cloud [laundrypro_cloud]
        SyncIngest[POST /api/v1/sync/push]
        SyncPull[GET /api/v1/sync/pull]
        CloudStorage[(cloud_sync_records<br/>Multi-Tenant Partitioned by tenant_id)]
    end

    OutboxA --> DaemonA
    DaemonA -->|POST Push Chunk<br/>X-Business-Owner-Id: tenant-1| SyncIngest
    SyncIngest --> CloudStorage

    OutboxB --> DaemonB
    DaemonB -->|POST Push Chunk<br/>X-Business-Owner-Id: tenant-2| SyncIngest
    
    CloudStorage --> SyncPull
    SyncPull -->|Delta Updates| DaemonA
    SyncPull -->|Delta Updates| DaemonB
`
