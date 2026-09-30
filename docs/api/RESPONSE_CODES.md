# LaundryPro UAE — API Response Codes

> **Version:** 2.0.0 | **Last Updated:** 2026-09-30

---

## Standard Envelope

All API responses use this envelope format:

```json
{
  "success": true|false,
  "code": "RESPONSE_CODE",
  "message_key": "localization.key",
  "data": {},
  "errors": [],
  "meta": {
    "request_id": "hex",
    "server_time": "ISO8601",
    "version": "1.2.0"
  }
}
```

## Response Code Registry

### Platform

| Code | HTTP | Description |
|---|---|---|
| `HEALTH_OK` | 200 | API and database healthy |
| `SERVICE_UNAVAILABLE` | 503 | Database or service down |
| `SERVER_ERROR` | 500 | Unhandled internal error |
| `NOT_FOUND` | 404 | Route or resource not found |
| `METHOD_NOT_ALLOWED` | 405 | HTTP method not supported |
| `VALIDATION_ERROR` | 422 | Request body validation failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |

### Authentication

| Code | HTTP | Description |
|---|---|---|
| `AUTH_LOGIN_SUCCESS` | 200 | Login successful, tokens issued |
| `AUTH_REFRESH_SUCCESS` | 200 | Token refresh successful |
| `AUTH_LOGOUT_SUCCESS` | 200 | Logout and token revocation complete |
| `AUTH_INVALID_CREDENTIALS` | 401 | Wrong username or password |
| `AUTH_SESSION_EXPIRED` | 401 | JWT expired or revoked |
| `AUTH_FORBIDDEN` | 403 | Insufficient permissions |
| `AUTH_ACCOUNT_LOCKED` | 403 | Account locked after failed attempts |

### Customers

| Code | HTTP | Description |
|---|---|---|
| `CUSTOMER_LIST` | 200 | Customer list retrieved |
| `CUSTOMER_DETAIL` | 200 | Single customer retrieved |
| `CUSTOMER_CREATED` | 201 | Customer created |
| `CUSTOMER_UPDATED` | 200 | Customer updated |
| `CUSTOMER_NOT_FOUND` | 404 | Customer ID not found |
| `CUSTOMER_DUPLICATE` | 409 | Duplicate phone/email |

### Sales / Orders

| Code | HTTP | Description |
|---|---|---|
| `ORDER_DRAFT_CREATED` | 201 | Draft order created |
| `ORDER_CONFIRMED` | 200 | Order confirmed |
| `ORDER_PAYMENT_RECORDED` | 200 | Payment recorded |
| `ORDER_STATUS_UPDATED` | 200 | Status changed |
| `ORDER_NOT_FOUND` | 404 | Order ID not found |
| `ORDER_INVALID_STATUS` | 422 | Invalid status transition |
| `INSUFFICIENT_STOCK` | 422 | Product stock below required qty |

### Catalog

| Code | HTTP | Description |
|---|---|---|
| `SERVICE_LIST` | 200 | Services list retrieved |
| `SERVICE_CREATED` | 201 | Service created |
| `SERVICE_UPDATED` | 200 | Service updated |
| `PRODUCT_LIST` | 200 | Products list retrieved |
| `PRODUCT_CREATED` | 201 | Product created |
| `PRODUCT_UPDATED` | 200 | Product updated |
| `MODIFIER_CREATED` | 201 | Modifier created |

### Inventory

| Code | HTTP | Description |
|---|---|---|
| `STOCK_LEVELS` | 200 | Current stock levels |
| `MOVEMENT_RECORDED` | 201 | Inventory movement recorded |
| `ADJUSTMENT_APPLIED` | 200 | Stock adjustment applied |
| `TRANSFER_COMPLETED` | 200 | Inter-branch transfer done |
| `RECEIPT_RECORDED` | 201 | Goods receipt recorded |
| `RECONCILE_COMPLETED` | 200 | Reconciliation completed |

### HR / Payroll

| Code | HTTP | Description |
|---|---|---|
| `EMPLOYEE_LIST` | 200 | Employee list retrieved |
| `EMPLOYEE_CREATED` | 201 | Employee created |
| `ATTENDANCE_RECORDED` | 201 | Attendance entry recorded |
| `LEAVE_REQUESTED` | 201 | Leave request submitted |
| `LEAVE_APPROVED` | 200 | Leave request approved |
| `LEAVE_REJECTED` | 200 | Leave request rejected |
| `PAYROLL_RUN_STARTED` | 200 | Payroll run initiated |
| `PAYROLL_RUN_COMPLETE` | 200 | Payroll run completed |

### Expenses

| Code | HTTP | Description |
|---|---|---|
| `EXPENSE_CREATED` | 201 | Expense created |
| `EXPENSE_APPROVED` | 200 | Expense approved |
| `EXPENSE_REJECTED` | 200 | Expense rejected |
| `EXPENSE_ATTACHMENT_UPLOADED` | 201 | Attachment uploaded |

### Sync

| Code | HTTP | Description |
|---|---|---|
| `SYNC_STATUS` | 200 | Sync status retrieved |
| `SYNC_PUSH_SUCCESS` | 200 | Records pushed to cloud |
| `SYNC_PULL_SUCCESS` | 200 | Records pulled from cloud |
| `SYNC_RECEIVED` | 200 | Cloud received push batch |
| `SYNC_CONFLICT` | 409 | Merge conflict detected |
| `SYNC_FAILED` | 500 | Sync operation failed |

### License

| Code | HTTP | Description |
|---|---|---|
| `LICENSE_STATUS` | 200 | License status retrieved |
| `LICENSE_ACTIVATED` | 200 | License activated |
| `LICENSE_EXPIRED` | 401 | License has expired |
| `LICENSE_INVALID` | 401 | Invalid license key |
| `LICENSE_LIMIT_EXCEEDED` | 403 | Device/branch limit exceeded |
| `LICENSE_REVOKED` | 403 | License has been revoked |

### Cloud-Only Codes

| Code | HTTP | Description |
|---|---|---|
| `TENANT_REQUIRED` | 401 | Missing X-Business-Owner-Id header |
| `TENANT_NOT_FOUND` | 401 | Tenant not registered |
| `INVALID_TOKEN` | 401 | Invalid cloud auth token |
| `BUSINESS_REGISTERED` | 201 | New tenant registered |
| `REPORTS_AGGREGATION` | 200 | Cross-tenant report generated |
| `BACKUP_UPLOADED` | 200 | Backup file received |

### Notifications

| Code | HTTP | Description |
|---|---|---|
| `NOTIFICATION_LIST` | 200 | Notifications retrieved |
| `NOTIFICATION_READ` | 200 | Notification marked as read |
| `NOTIFICATION_ALL_READ` | 200 | All notifications marked read |

### Backup

| Code | HTTP | Description |
|---|---|---|
| `BACKUP_STARTED` | 200 | Backup process started |
| `BACKUP_COMPLETED` | 200 | Backup completed |
| `BACKUP_RESTORE_STARTED` | 200 | Restore started |
| `BACKUP_VALIDATION_OK` | 200 | Backup file validated |

---

*This document is the authoritative response code reference. All new endpoints MUST use codes from this registry.*
