# API Quick Reference - LaundryPro UAE
> **Version:** 1.0.0

## Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/auth/login | Login (returns tokens) |
| POST | /api/v1/auth/refresh | Refresh access token |
| POST | /api/v1/auth/logout | Revoke tokens |

## Orders
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/orders | List orders (paginated) |
| POST | /api/v1/orders | Create order |
| GET | /api/v1/orders/:id | Get order detail |
| PATCH | /api/v1/orders/:id | Update order |
| POST | /api/v1/orders/:id/status | Update order status |

## Customers
| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/customers | List customers |
| POST | /api/v1/customers | Create customer |
| GET | /api/v1/customers/:id | Get customer |
| PATCH | /api/v1/customers/:id | Update customer |

## Sync
| Method | Path | Description |
|--------|------|-------------|
| POST | /api/v1/sync/push | Push outbox entries |
| GET | /api/v1/sync/pull | Pull cloud changes |