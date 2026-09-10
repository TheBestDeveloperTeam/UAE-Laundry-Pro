# LaundryPro UAE - Internal API Documentation

## Overview
The LaundryPro API is a custom, zero-dependency PHP 8.2 micro-framework designed specifically for low-latency, offline-first execution on Windows edge terminals. It serves as the local interface for the Flutter POS application and manages bidirectional synchronization with the cloud.

## Architectural Standards
1. **Response Format:** All endpoints return a standard JSON envelope:
   ```json
   {
     "success": true,
     "code": "OPERATION_SUCCESS",
     "message": "Human readable message",
     "data": {}
   }
   ```
2. **Authentication:** Bearer JWT required in the `Authorization` header.
3. **Data Types:** Monetary fields are represented as strings in JSON to preserve precision before being cast to `DECIMAL(18,2)` in MariaDB.

## Core Services

### Authentication Module
Handles identity verification, token issuance, and role-based access control (RBAC).
- `POST /auth/login` - Validates credentials, checks rate limits, and issues access/refresh tokens.
- `POST /auth/refresh` - Issues a new access token using a valid refresh token.
- `POST /auth/logout` - Invalidates the active session.

### Sales & Point of Sale (POS)
Manages the core transaction lifecycle.
- `GET /sales` - Retrieves paginated invoices and orders.
- `POST /sales` - Commits a new transaction (requires `sales.write` permission).
- `POST /sales/{id}/pay` - Records a payment against an outstanding invoice.
- `POST /sales/{id}/refund` - Reverses a transaction, writing a correction memo (Invoices are never mutated directly).

### Inventory & Catalog
Strictly controls stock levels using atomic row-locking to prevent race conditions.
- `GET /catalog/products` - Lists physical retail items tracked in inventory.
- `GET /catalog/services` - Lists service operations (Dry Cleaning, Pressing).
- `POST /inventory/transfer` - Executes a multi-step branch-to-branch stock transfer inside an atomic `PDO` transaction.
- `POST /inventory/receipt` - Adjusts local stock levels upwards.

### Synchronization Engine
The heart of the offline-first architecture.
- `GET /sync/status` - Checks outbox depth and connection health.
- `POST /sync/push` - Flushes the `sync_outbox` to the cloud API, applying exponential backoff on network failures.
- `POST /sync/pull` - Downloads remote state changes (e.g., global catalog updates, new branch definitions).

### Infrastructure & Administration
- `POST /backup/run` - Triggers a localized `mysqldump`, compresses it, and generates a SHA-256 manifest.
- `POST /backup/restore` - Validates the cryptographic integrity of a `.zip` payload and overwrites the active database.

## Security Controls
- **Rate Limiting:** IP-based sliding window throttle on `/auth/*` routes.
- **SQL Injection:** Strict utilization of PDO prepared statements in all Repositories.
- **Audit Trails:** All modifications are recorded in `audit_logs` with the responsible `user_id`.
