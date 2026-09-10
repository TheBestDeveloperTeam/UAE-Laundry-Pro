# LaundryPro UAE - Internal API Documentation

## Overview
This API is a custom PHP 8.2 micro-framework tailored for Windows/XAMPP offline-first deployments. It powers the LaundryPro POS system and synchronizes with the central cloud.

## Authentication
All protected routes require a JWT Bearer token:
`Authorization: Bearer <token>`

## Key Endpoints

### 1. Auth (`/auth/*`)
- `POST /auth/login`: Authenticates a user and returns an access token.
- `POST /auth/refresh`: Refreshes an expired JWT.

### 2. POS / Sales (`/sales/*`)
- `POST /sales`: Create a new sales order.
- `GET /sales`: List orders.
- `POST /sales/{id}/pay`: Register a payment against an order.

### 3. Catalog (`/catalog/*`)
- `GET /catalog/services`: List available laundry services.
- `GET /catalog/products`: List retail products.

### 4. Inventory (`/inventory/*`)
- `POST /inventory/receipt`: Receive stock.
- `POST /inventory/transfer`: Transfer stock between branches.

### 5. Sync (`/sync/*`)
- `GET /sync/status`: Get local sync state.
- `POST /sync/push`: Push local outbox to cloud.
- `POST /sync/pull`: Pull cloud changes.

## Security Notes
- Inventory and ledger entries are immutable.
- Passwords are hashed securely.
- Cross-site Origin is controlled via `CorsMiddleware`.
- Brute force logins are throttled via `RateLimitMiddleware`.
