# LaundryPro UAE - API Documentation

This document outlines the architecture and endpoints of the LaundryPro UAE PHP 8.2 micro-framework backend.

## Framework Architecture

The backend is a custom, zero-dependency PHP micro-framework designed for maximum performance and explicit control.

- **Routing**: Regex-based URI matching mapped to controller methods.
- **Dependency Injection**: Custom `Container` mapping interfaces to implementations via closures.
- **Middleware Pipeline**: Request/Response lifecycle intercepted by a chain (e.g., `CorsMiddleware`, `RateLimitMiddleware`, `AuthMiddleware`, `PermissionMiddleware`, `AuditMiddleware`).
- **Standardized Envelope**: All JSON responses adhere to a strict envelope format:
  ```json
  {
    "success": true,
    "code": "OPERATION_SUCCESS_CODE",
    "message_key": "localization.key",
    "data": { ... },
    "errors": [],
    "meta": {
      "request_id": "hex_string",
      "server_time": "ISO8601",
      "version": "1.2.0"
    }
  }
  ```

## Security & Authentication

- **JWT Bearer Auth**: Stateless authentication using short-lived Access Tokens and long-lived Refresh Tokens.
- **RBAC (Role-Based Access Control)**: Enforced via `PermissionMiddleware`. Users require specific permissions (e.g., `sales.create`, `reports.view`) encoded in their JWT scope.
- **Rate Limiting**: IP-based limiting enforced on sensitive routes (e.g., `/auth/login` is limited to 5 attempts per minute).
- **Prepared Statements**: Absolute prevention of SQL injection via PDO.
- **Data Integrity**: Monetary values processed via `bcmath` and stored as `DECIMAL(18,2)`.

## Sync Engine Mechanics

The offline-first architecture relies on the **Sync Outbox Pattern**:
1. When the client executes an offline mutation, it writes to a local outbox.
2. The `SyncService` polls the outbox and pushes changes to the `/sync/push` endpoint.
3. The server processes the mutation and returns a synchronized state.
4. Failed syncs implement **Exponential Backoff**, incrementing the `sync_attempts` counter up to a hard limit, preventing network storms.

## Endpoint Reference

### Health & Installation (`HealthController`, `InstallController`)
- `GET /api/v1/health` - Basic connectivity and database health check.
- `GET /api/v1/install/status` - Returns installation and configuration state.
- `POST /api/v1/install/migrate` - Executes SQL schema migrations (Requires `X-Install-Token`).
- `POST /api/v1/install/seed` - Seeds database with default roles, branches, and admin user.
- `POST /api/v1/install/complete` - Finalizes installation and locks the system.

### Authentication (`AuthController`)
- `POST /api/v1/auth/login` - Authenticates user and returns JWT pair. Rate limited.
- `POST /api/v1/auth/refresh` - Issues a new access token using a valid refresh token.
- `POST /api/v1/auth/logout` - Revokes current refresh token.
- `GET /api/v1/auth/me` - Retrieves authenticated user profile.

### Sales & Point of Sale (`SalesController`)
- `GET /api/v1/sales` - Lists sales orders with pagination and filtering.
- `POST /api/v1/sales/draft` - Creates a draft sales order.
- `PUT /api/v1/sales/{id}/confirm` - Confirms a draft order, finalizing prices.
- `POST /api/v1/sales/{id}/payment` - Records a payment against an order.
- `PUT /api/v1/sales/{id}/status` - Updates order processing status (e.g., Ready for Collection).
- `GET /api/v1/sales/summary` - Retrieves aggregated sales data for reports.

### Catalog & Pricing (`CatalogController`)
- `GET /api/v1/catalog/services` - Lists available services and modifiers.
- `POST /api/v1/catalog/services` - Creates a new service definition.
- `PUT /api/v1/catalog/services/{id}` - Updates a service definition.
- `GET /api/v1/catalog/products` - Lists retail products.
- `POST /api/v1/catalog/products` - Creates a new retail product.

### Inventory (`InventoryController`)
- `GET /api/v1/inventory/movements` - Lists stock movements.
- `POST /api/v1/inventory/receipt` - Records a stock receipt against a purchase order.
- `POST /api/v1/inventory/adjustment` - Processes manual stock adjustments.

### Human Resources (`HrController`, `PayrollController`)
- `GET /api/v1/hr/employees` - Lists employees.
- `POST /api/v1/hr/employees` - Registers a new employee.
- `POST /api/v1/hr/attendance` - Records clock-in/out events.
- `POST /api/v1/hr/leave` - Submits a leave request.
- `POST /api/v1/payroll/advance` - Issues a salary advance.
- `POST /api/v1/payroll/run` - Generates payroll run for a period, deducting advances automatically.

### Delivery & Logistics (`DeliveryController`, `ChallanController`)
- `GET /api/v1/delivery/tasks` - Lists active delivery tasks.
- `POST /api/v1/delivery/tasks/{id}/complete` - Marks a task as completed.
- `POST /api/v1/challans` - Generates a batch transfer document (Challan) for factory processing.

### Reporting & Analytics (`ReportsController`, `AnalyticsController`)
- `GET /api/v1/reports/inventory` - Current stock valuation.
- `GET /api/v1/reports/payroll` - Payroll summary.
- `GET /api/v1/reports/expenses` - Expense breakdown.
- `GET /api/v1/reports/production` - Factory output metrics.
- `GET /api/v1/analytics/summary` - High-level executive dashboard metrics.

### System Settings & Backup (`SettingsController`, `BackupController`)
- `GET /api/v1/settings` - Retrieves global configurations.
- `PUT /api/v1/settings` - Bulk updates settings.
- `GET /api/v1/backup/history` - Lists available backups.
- `POST /api/v1/backup/run` - Triggers an encrypted ZIP backup of the database and files.

### Synchronization (`SyncController`)
- `GET /api/v1/sync/status` - Returns unpushed outbox counts and sync health.
- `POST /api/v1/sync/push` - Receives offline mutations from the client and applies them.
- `GET /api/v1/sync/pull` - Returns changes originating from the server since the last sync.

## Error Handling

Standard HTTP status codes are used alongside domain-specific error keys:
- `401 Unauthorized` - Missing or expired JWT.
- `403 Forbidden` - Insufficient RBAC permissions.
- `404 Not Found` - Resource does not exist.
- `422 Unprocessable Entity` - Validation failure.
- `429 Too Many Requests` - Rate limit exceeded.
- `500 Internal Server Error` - Unhandled exception (safely obfuscated in production).
