# LaundryPro UAE: Database Entity-Relationship (ER) Diagram

This document defines the core relational data model underpinning the LaundryPro UAE offline-first system.

## Core Schema

```mermaid
erDiagram
    BUSINESS ||--o{ BRANCHES : "owns"
    BRANCHES ||--o{ TERMINALS : "contains"
    
    ROLES ||--o{ USERS : "defines permissions for"
    USERS ||--o{ REFRESH_TOKENS : "issues"
    USERS ||--o{ AUDIT_LOGS : "performs"
    
    CUSTOMERS ||--o{ SALES_ORDERS : "places"
    
    CATEGORIES ||--o{ SERVICES : "groups"
    SERVICES ||--o{ SERVICE_PRODUCT_MAP : "consumes"
    PRODUCTS ||--o{ SERVICE_PRODUCT_MAP : "is consumed by"
    
    SALES_ORDERS ||--o{ SALES_ORDER_LINES : "contains"
    SALES_ORDERS ||--o{ PAYMENT_TRANSACTIONS : "paid via"
    
    PRODUCTS ||--o{ INVENTORY_MOVEMENTS : "tracked by"
    VENDORS ||--o{ PURCHASE_ORDERS : "receives"
    PURCHASE_ORDERS ||--o{ INVENTORY_MOVEMENTS : "restocks via"
    
    TERMINALS ||--o{ SYNC_OUTBOX : "queues data to"
    SYNC_OUTBOX ||--o{ SYNC_STATE : "monitored by"
    
    BUSINESS {
        int id PK
        string name
        string trn
        boolean is_active
    }
    
    USERS {
        int id PK
        string uuid
        int role_id FK
        string username
        string password_hash
    }
    
    ROLES {
        int id PK
        string name
        json permissions
    }
    
    CUSTOMERS {
        int id PK
        string uuid
        string name
        string phone
        decimal outstanding_balance
    }
    
    SALES_ORDERS {
        int id PK
        string uuid
        int customer_id FK
        string status
        string payment_status
        decimal grand_total
        decimal balance_due
    }
    
    SALES_ORDER_LINES {
        int id PK
        int sales_order_id FK
        int service_id FK
        int quantity
        decimal unit_price
        decimal subtotal
    }
    
    PRODUCTS {
        int id PK
        string sku
        string name
        int qty_on_hand
        int reorder_point
    }
    
    INVENTORY_MOVEMENTS {
        int id PK
        int product_id FK
        string type
        int quantity_change
    }
    
    SYNC_OUTBOX {
        int id PK
        string entity_type
        string entity_uuid
        string action
        json payload
        string status
        int attempts
        timestamp next_retry_at
    }
```

## Design Constraints
- All primary keys (`id`) are unsigned integers auto-incremented for local database speed.
- All replicated tables possess a `uuid` `CHAR(36)` used as the global primary key when synchronizing to the central cloud.
- Monetary values (`grand_total`, `subtotal`, etc.) are STRICTLY typed as `DECIMAL(18,2)`.
- The `sync_outbox` acts as an event-store for the offline-first replication engine.
