# API Documentation - LaundryPro UAE
> **Version:** 1.0.0

## Base URL
`http://localhost/api/v1/`

## Authentication
All endpoints (except login/refresh) require: `Authorization: Bearer {access_token}`

## Response Format
```json
{
  "success": true,
  "data": { ... },
  "meta": { "page": 1, "limit": 20, "total": 100 },
  "error": null
}
```

## Error Format
```json
{
  "success": false,
  "data": null,
  "meta": null,
  "error": {
    "code": "LP-ERR-AUTH-1001",
    "message": "Invalid credentials",
    "details": []
  }
}
```

## Common Headers
| Header | Required | Description |
|--------|----------|-------------|
| Authorization | Yes* | Bearer JWT access token |
| X-Idempotency-Key | Yes (writes) | UUID for write operations |
| Content-Type | Yes | application/json |
| Accept-Language | No | en or ar (default: en) |

## Endpoint Groups
| Group | Base Path | Description |
|-------|-----------|-------------|
| Auth | /auth | Login, refresh, logout |
| Orders | /orders | Order CRUD and status |
| Customers | /customers | Customer CRUD |
| Services | /services | Service catalog |
| Inventory | /inventory | Stock management |
| Invoices | /invoices | Invoice management |
| Payments | /payments | Payment processing |
| Employees | /employees | Employee management |
| Attendance | /attendance | Clock in/out |
| Payroll | /payroll | Payroll calculations |
| Reports | /reports | Report generation |
| Sync | /sync | Push/pull sync |
| Settings | /settings | System configuration |