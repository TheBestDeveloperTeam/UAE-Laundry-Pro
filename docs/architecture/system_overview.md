# System Architecture Overview - LaundryPro UAE
> **Version:** 1.0.0

## Architecture Layers

```
+------------------------------------------+
|        PRESENTATION LAYER                |
|  Flutter Windows Desktop (Dart)          |
|  MVVM + Riverpod + go_router             |
|  LTR/RTL + Offline-capable UI            |
+------------------------------------------+
           |                |
     [REST API]        [SQLite]
           |           (local cache)
+------------------------------------------+
|        APPLICATION LAYER                 |
|  PHP 8.2 REST API (Slim/Lumen)           |
|  Controllers -> Services -> Repositories |
|  JWT Auth + RBAC + Idempotency           |
+------------------------------------------+
           |
+------------------------------------------+
|        DATA LAYER                        |
|  MariaDB 10.4 (InnoDB)                  |
|  Multi-tenant (business_owner_id)        |
|  DECIMAL(18,2) for money                 |
+------------------------------------------+

+------------------------------------------+
|        SYNC LAYER                        |
|  Sync Outbox (append-only)               |
|  Push/Pull Protocols                     |
|  Conflict Resolution (LWW)              |
+------------------------------------------+

+------------------------------------------+
|        HARDWARE LAYER                    |
|  ESC/POS Printers | Barcode Scanners    |
|  Cash Drawers | RFID Readers | Scales   |
|  Auto-Discovery + Adapter Pattern        |
+------------------------------------------+

+------------------------------------------+
|        SECURITY LAYER                    |
|  UMAC Licensing | RBAC Scopes           |
|  Audit Trail (hash-chained)             |
|  AES-256 Encryption | SHA-256 Backup    |
+------------------------------------------+
```

## Key Architectural Decisions
1. **Offline-First**: Local XAMPP server is primary; cloud sync is secondary.
2. **Multi-Tenant**: business_owner_id on all data tables; strict isolation.
3. **Zero-Float Money**: DECIMAL(18,2) everywhere; bcmath in PHP.
4. **Clean Architecture**: Presentation -> Domain -> Data layer separation.
5. **Adapter Pattern**: All hardware behind generic interfaces.