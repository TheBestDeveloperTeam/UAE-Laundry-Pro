<?php

declare(strict_types=1);

use LaundryPro\Cloud\Controllers\AdminPortalController;
use LaundryPro\Cloud\Controllers\AuthController;
use LaundryPro\Cloud\Controllers\CatalogController;
use LaundryPro\Cloud\Controllers\ChallanController;
use LaundryPro\Cloud\Controllers\CloudApiController;
use LaundryPro\Cloud\Controllers\CustomerController;
use LaundryPro\Cloud\Controllers\DeliveryController;
use LaundryPro\Cloud\Controllers\ExpenseController;
use LaundryPro\Cloud\Controllers\HrController;
use LaundryPro\Cloud\Controllers\InventoryController;
use LaundryPro\Cloud\Controllers\OperationsController;
use LaundryPro\Cloud\Controllers\PlatformController;
use LaundryPro\Cloud\Controllers\ReportsController;
use LaundryPro\Cloud\Controllers\SalesController;
use LaundryPro\Cloud\Controllers\SyncManagementController;
use LaundryPro\Cloud\Controllers\TenantApiController;
use LaundryPro\Cloud\Controllers\VendorController;
use LaundryPro\Cloud\Core\Router;

function register_cloud_api_routes(Router $router): void
{
    // ===== 1. Platform & Telemetry =====
    $router->get('/api/v1/health', [CloudApiController::class, 'health']);
    $router->get('/api/v1/docs/openapi.json', [CloudApiController::class, 'openapiJson']);
    $router->get('/api/v1/docs', [CloudApiController::class, 'docs']);

    // ===== 2. Identity & Authentication =====
    $router->post('/api/v1/auth/login', [AuthController::class, 'login']);
    $router->post('/api/v1/auth/refresh', [AuthController::class, 'refresh']);
    $router->post('/api/v1/auth/logout', [AuthController::class, 'logout']);
    $router->get('/api/v1/auth/me', [AuthController::class, 'me']);

    // ===== 3. Settings & Business =====
    $router->get('/api/v1/settings', [PlatformController::class, 'settings']);
    $router->put('/api/v1/settings', [PlatformController::class, 'updateSettings']);
    $router->get('/api/v1/business', [PlatformController::class, 'business']);
    $router->put('/api/v1/business', [PlatformController::class, 'updateBusiness']);
    $router->post('/api/v1/businesses/register', [CloudApiController::class, 'registerBusiness']);

    // ===== 4. Roles & Permissions =====
    $router->get('/api/v1/roles', [PlatformController::class, 'roles']);
    $router->post('/api/v1/roles', [PlatformController::class, 'createRole']);
    $router->put('/api/v1/roles/{id}', [PlatformController::class, 'updateRole']);

    // Install routes removed on Cloud Hub (Local-only provisioning)

    // ===== 6. Customers =====
    $router->get('/api/v1/customers', [CustomerController::class, 'list']);
    $router->get('/api/v1/customers/{id}', [CustomerController::class, 'get']);
    $router->post('/api/v1/customers', [CustomerController::class, 'create']);
    $router->put('/api/v1/customers/{id}', [CustomerController::class, 'update']);

    // ===== 7. Vendors =====
    $router->get('/api/v1/vendors', [VendorController::class, 'list']);
    $router->get('/api/v1/vendors/{id}', [VendorController::class, 'get']);
    $router->post('/api/v1/vendors', [VendorController::class, 'create']);
    $router->put('/api/v1/vendors/{id}', [VendorController::class, 'update']);

    // ===== 8. Catalog (Services, Products, Modifiers) =====
    $router->get('/api/v1/services', [CatalogController::class, 'listServices']);
    $router->get('/api/v1/services/{id}', [CatalogController::class, 'getService']);
    $router->post('/api/v1/services', [CatalogController::class, 'createService']);
    $router->put('/api/v1/services/{id}', [CatalogController::class, 'updateService']);
    $router->get('/api/v1/services/{id}/products', [CatalogController::class, 'serviceProducts']);
    $router->post('/api/v1/services/{id}/products', [CatalogController::class, 'addServiceProduct']);
    $router->delete('/api/v1/services/{id}/products/{productId}', [CatalogController::class, 'removeServiceProduct']);
    $router->get('/api/v1/services/{id}/modifiers', [CatalogController::class, 'serviceModifiers']);
    $router->post('/api/v1/services/{id}/modifiers', [CatalogController::class, 'addServiceModifier']);

    $router->get('/api/v1/products', [CatalogController::class, 'listProducts']);
    $router->post('/api/v1/products', [CatalogController::class, 'createProduct']);
    $router->get('/api/v1/products/{id}', [CatalogController::class, 'getProduct']);
    $router->put('/api/v1/products/{id}', [CatalogController::class, 'updateProduct']);
    $router->get('/api/v1/products/{id}/modifiers', [CatalogController::class, 'productModifiers']);
    $router->post('/api/v1/products/{id}/modifiers', [CatalogController::class, 'addProductModifier']);

    // ===== 9. Sales & Invoices =====
    $router->get('/api/v1/sales', [SalesController::class, 'list']);
    $router->get('/api/v1/sales/{id}', [SalesController::class, 'get']);
    $router->post('/api/v1/sales/draft', [SalesController::class, 'draft']);
    $router->post('/api/v1/sales/{id}/confirm', [SalesController::class, 'confirm']);
    $router->post('/api/v1/sales/{id}/payment', [SalesController::class, 'payment']);
    $router->patch('/api/v1/sales/{id}/status', [SalesController::class, 'updateStatus']);
    $router->get('/api/v1/sales/{id}/status-history', [SalesController::class, 'statusHistory']);
    $router->get('/api/v1/sales/{id}/delivery-tasks', [SalesController::class, 'deliveryTasks']);
    $router->post('/api/v1/sales/{id}/delivery-tasks', [SalesController::class, 'createDeliveryTask']);

    $router->get('/api/v1/invoices', [SalesController::class, 'invoices']);
    $router->get('/api/v1/invoices/{id}', [SalesController::class, 'getInvoice']);
    $router->post('/api/v1/invoices/{id}/post', [SalesController::class, 'postInvoice']);
    $router->post('/api/v1/invoices/{id}/correction', [SalesController::class, 'correctInvoice']);

    // ===== 10. Delivery Tasks =====
    $router->get('/api/v1/delivery-tasks', [DeliveryController::class, 'list']);
    $router->get('/api/v1/delivery-tasks/{id}', [DeliveryController::class, 'get']);
    $router->post('/api/v1/delivery-tasks', [DeliveryController::class, 'create']);
    $router->patch('/api/v1/delivery-tasks/{id}', [DeliveryController::class, 'patch']);
    $router->post('/api/v1/delivery-tasks/{id}/complete', [DeliveryController::class, 'complete']);

    // ===== 11. Challans =====
    $router->get('/api/v1/challans', [ChallanController::class, 'list']);
    $router->get('/api/v1/challans/{id}', [ChallanController::class, 'get']);
    $router->post('/api/v1/challans', [ChallanController::class, 'create']);
    $router->put('/api/v1/challans/{id}', [ChallanController::class, 'update']);
    $router->post('/api/v1/challans/{id}/cancel', [ChallanController::class, 'cancel']);

    // ===== 12. Inventory & Purchasing =====
    $router->get('/api/v1/inventory/movements', [InventoryController::class, 'movements']);
    $router->post('/api/v1/inventory/receipt', [InventoryController::class, 'receipt']);
    $router->post('/api/v1/inventory/adjustment', [InventoryController::class, 'adjustment']);
    $router->post('/api/v1/inventory/transfer', [InventoryController::class, 'transfer']);
    $router->get('/api/v1/inventory/stock', [InventoryController::class, 'stock']);
    $router->post('/api/v1/inventory/reconcile', [InventoryController::class, 'reconcile']);

    $router->get('/api/v1/purchase-orders', [InventoryController::class, 'purchaseOrders']);
    $router->get('/api/v1/purchase-orders/{id}', [InventoryController::class, 'getPurchaseOrder']);
    $router->post('/api/v1/purchase-orders', [InventoryController::class, 'createPurchaseOrder']);
    $router->put('/api/v1/purchase-orders/{id}', [InventoryController::class, 'updatePurchaseOrder']);
    $router->post('/api/v1/purchase-orders/{id}/receive', [InventoryController::class, 'receivePurchaseOrder']);

    // ===== 13. Expenses =====
    $router->get('/api/v1/expense-categories', [ExpenseController::class, 'categories']);
    $router->post('/api/v1/expense-categories', [ExpenseController::class, 'createCategory']);
    $router->get('/api/v1/expenses', [ExpenseController::class, 'list']);
    $router->get('/api/v1/expenses/{id}', [ExpenseController::class, 'get']);
    $router->post('/api/v1/expenses', [ExpenseController::class, 'create']);
    $router->post('/api/v1/expenses/{id}/approve', [ExpenseController::class, 'approve']);
    $router->post('/api/v1/expenses/{id}/reject', [ExpenseController::class, 'reject']);
    $router->post('/api/v1/expenses/{id}/attachments', [ExpenseController::class, 'attachments']);

    // ===== 14. Employees & HR =====
    $router->get('/api/v1/employees', [HrController::class, 'employees']);
    $router->get('/api/v1/employees/{id}', [HrController::class, 'getEmployee']);
    $router->post('/api/v1/employees', [HrController::class, 'createEmployee']);
    $router->put('/api/v1/employees/{id}', [HrController::class, 'updateEmployee']);
    $router->delete('/api/v1/employees/{id}', [HrController::class, 'deleteEmployee']);

    $router->get('/api/v1/attendance', [HrController::class, 'attendance']);
    $router->post('/api/v1/attendance', [HrController::class, 'clockAttendance']);

    $router->get('/api/v1/leave-requests', [HrController::class, 'leaveRequests']);
    $router->get('/api/v1/leave-types', [HrController::class, 'leaveTypes']);
    $router->post('/api/v1/leave-requests', [HrController::class, 'createLeaveRequest']);
    $router->post('/api/v1/leave-requests/{id}/approve', [HrController::class, 'approveLeaveRequest']);
    $router->post('/api/v1/leave-requests/{id}/reject', [HrController::class, 'rejectLeaveRequest']);

    $router->get('/api/v1/payroll/periods', [HrController::class, 'payrollPeriods']);
    $router->post('/api/v1/payroll/periods', [HrController::class, 'createPayrollPeriod']);
    $router->post('/api/v1/payroll/run', [HrController::class, 'runPayroll']);
    $router->post('/api/v1/payroll/periods/{id}/run', [HrController::class, 'runPayrollPeriod']);
    $router->get('/api/v1/payroll/runs', [HrController::class, 'payrollRuns']);
    $router->get('/api/v1/payroll/runs/{id}', [HrController::class, 'getPayrollRun']);

    $router->get('/api/v1/salary-advances', [HrController::class, 'salaryAdvances']);
    $router->post('/api/v1/salary-advances', [HrController::class, 'createSalaryAdvance']);

    // ===== 15. Notifications & Channels =====
    $router->get('/api/v1/notifications', [PlatformController::class, 'notifications']);
    $router->get('/api/v1/notifications/{id}', [PlatformController::class, 'getNotification']);
    $router->post('/api/v1/notifications/{id}/read', [PlatformController::class, 'readNotification']);
    $router->post('/api/v1/notifications/read-all', [PlatformController::class, 'readAllNotifications']);
    $router->post('/api/v1/notifications/generate', [PlatformController::class, 'generateNotification']);

    $router->get('/api/v1/channels', [PlatformController::class, 'channels']);
    $router->post('/api/v1/channels', [PlatformController::class, 'createChannel']);
    $router->post('/api/v1/channels/{id}/test', [PlatformController::class, 'testChannel']);

    // ===== 16. Reports & Analytics =====
    $router->get('/api/v1/reports/dashboard-kpis', [ReportsController::class, 'dashboardKpis']);
    $router->get('/api/v1/reports/operational-pnl', [ReportsController::class, 'operationalPnl']);
    $router->get('/api/v1/reports/aging', [ReportsController::class, 'aging']);
    $router->get('/api/v1/reports/payment-breakdown', [ReportsController::class, 'paymentBreakdown']);
    $router->get('/api/v1/reports/sales/summary', [ReportsController::class, 'salesSummary']);
    $router->get('/api/v1/reports/expenses/summary', [ReportsController::class, 'expensesSummary']);
    $router->get('/api/v1/reports/payroll/summary', [ReportsController::class, 'payrollSummary']);
    $router->get('/api/v1/reports/inventory/valuation', [ReportsController::class, 'inventoryValuation']);
    $router->get('/api/v1/reports/production/throughput', [ReportsController::class, 'productionThroughput']);
    $router->get('/api/v1/reports/inventory', [ReportsController::class, 'inventoryReport']);
    $router->get('/api/v1/reports/payroll', [ReportsController::class, 'payrollReport']);
    $router->get('/api/v1/reports/expenses', [ReportsController::class, 'expensesReport']);
    $router->get('/api/v1/reports/production', [ReportsController::class, 'productionReport']);
    $router->get('/api/v1/reports/purchasing', [ReportsController::class, 'purchasingReport']);
    $router->get('/api/v1/reports/delivery', [ReportsController::class, 'deliveryReport']);
    $router->get('/api/v1/reports/accounting/export', [ReportsController::class, 'accountingExport']);
    $router->get('/api/v1/reports/aggregation', [CloudApiController::class, 'centralizedReports']);

    $router->get('/api/v1/analytics/summary', [ReportsController::class, 'analyticsSummary']);
    $router->get('/api/v1/analytics/trends', [ReportsController::class, 'analyticsTrends']);
    $router->post('/api/v1/analytics/refresh', [ReportsController::class, 'analyticsRefresh']);

    // ===== 17. License =====
    $router->get('/api/v1/license/status', [SyncManagementController::class, 'licenseStatus']);
    $router->post('/api/v1/license/activate', [SyncManagementController::class, 'licenseActivate']);
    $router->post('/api/v1/license/validate', [CloudApiController::class, 'validateLicense']);
    $router->post('/api/v1/license/approve', [SyncManagementController::class, 'licenseApprove']);
    $router->post('/api/v1/license/revoke', [SyncManagementController::class, 'licenseRevoke']);

    // ===== 18. Sync Gateway =====
    $router->get('/api/v1/sync/status', [SyncManagementController::class, 'syncStatus']);
    $router->post('/api/v1/sync/push', [CloudApiController::class, 'syncPush']);
    $router->get('/api/v1/sync/pull', [CloudApiController::class, 'syncPull']);
    $router->put('/api/v1/sync/config', [SyncManagementController::class, 'syncConfig']);
    $router->get('/api/v1/sync/entities', [SyncManagementController::class, 'syncEntities']);

    // ===== 19. Backup =====
    $router->post('/api/v1/backup/run', [SyncManagementController::class, 'backupRun']);
    $router->post('/api/v1/backup/verify', [SyncManagementController::class, 'backupVerify']);
    $router->post('/api/v1/backup/restore/validate', [SyncManagementController::class, 'backupRestoreValidate']);
    $router->post('/api/v1/backup/restore', [SyncManagementController::class, 'backupRestore']);
    $router->get('/api/v1/backup/history', [SyncManagementController::class, 'backupHistory']);
    $router->post('/api/v1/sync/backup', [CloudApiController::class, 'uploadBackup']);

    // ===== 20. Branches & Terminals =====
    $router->get('/api/v1/branches', [PlatformController::class, 'branches']);
    $router->get('/api/v1/branches/{id}', [PlatformController::class, 'getBranch']);
    $router->post('/api/v1/branches', [PlatformController::class, 'createBranch']);
    $router->put('/api/v1/branches/{id}', [PlatformController::class, 'updateBranch']);

    $router->get('/api/v1/terminals', [PlatformController::class, 'terminals']);
    $router->post('/api/v1/terminals', [PlatformController::class, 'createTerminal']);
    $router->post('/api/v1/terminals/{id}/register', [PlatformController::class, 'registerTerminal']);

    // ===== 21. Equipment & Operators =====
    $router->get('/api/v1/equipment', [OperationsController::class, 'equipment']);
    $router->post('/api/v1/equipment/{id}/calibrate', [OperationsController::class, 'calibrateEquipment']);
    $router->post('/api/v1/equipment/{id}/status', [OperationsController::class, 'equipmentStatus']);

    $router->get('/api/v1/operators/certifications', [OperationsController::class, 'operatorCertifications']);
    $router->post('/api/v1/operators/{id}/certify', [OperationsController::class, 'certifyOperator']);

    // Local hardware routes (/rfid/scan, /lan/*) removed on Cloud Hub

    // ===== 22. Advanced Cycles & Sterilization =====
    $router->get('/api/v1/advanced-cycles/presets', [OperationsController::class, 'advancedCyclePresets']);
    $router->post('/api/v1/advanced-cycles/start', [OperationsController::class, 'startAdvancedCycle']);
    $router->post('/api/v1/advanced-cycles/{id}/complete', [OperationsController::class, 'completeAdvancedCycle']);
    $router->post('/api/v1/advanced-cycles/{id}/process-logs', [OperationsController::class, 'processLogsAdvancedCycle']);

    $router->post('/api/v1/sterilization/batch', [OperationsController::class, 'sterilizationBatch']);
    $router->post('/api/v1/sterilization/scan', [OperationsController::class, 'sterilizationScan']);
    $router->post('/api/v1/sterilization/log', [OperationsController::class, 'sterilizationLog']);
    $router->post('/api/v1/sterilization/sign', [OperationsController::class, 'sterilizationSign']);
    $router->get('/api/v1/sterilization/logs/{cycleRunId}', [OperationsController::class, 'sterilizationLogs']);

    // ===== 23. Storefront & Customer Portal =====
    $router->get('/api/v1/storefront/catalog', [OperationsController::class, 'storefrontCatalog']);
    $router->post('/api/v1/storefront/orders', [OperationsController::class, 'createStorefrontOrder']);
    $router->get('/api/v1/storefront/orders', [OperationsController::class, 'storefrontOrders']);
    $router->post('/api/v1/storefront/orders/{id}/convert', [OperationsController::class, 'convertStorefrontOrder']);

    $router->post('/api/v1/portal/tokens', [OperationsController::class, 'portalTokens']);
    $router->get('/api/v1/portal/order', [OperationsController::class, 'portalOrder']);

    // ===== 24. Accounting =====
    $router->get('/api/v1/accounting/batches', [OperationsController::class, 'accountingBatches']);
    $router->get('/api/v1/accounting/batches/{id}', [OperationsController::class, 'getAccountingBatch']);
    $router->post('/api/v1/accounting/export', [OperationsController::class, 'accountingExport']);

    // ===== 27. Localization =====
    $router->get('/api/v1/localization/profiles', [PlatformController::class, 'localizationProfiles']);
    $router->put('/api/v1/localization/country', [PlatformController::class, 'localizationCountry']);

    // ===== 28. Tenant-Scoped Direct Aliases =====
    $router->get('/api/v1/tenant/profile', [TenantApiController::class, 'profile']);
    $router->get('/api/v1/tenant/customers', [TenantApiController::class, 'listCustomers']);
    $router->post('/api/v1/tenant/customers', [TenantApiController::class, 'createCustomer']);
    $router->get('/api/v1/tenant/catalog/services', [TenantApiController::class, 'listServices']);
    $router->post('/api/v1/tenant/catalog/services', [TenantApiController::class, 'createService']);
    $router->get('/api/v1/tenant/orders', [TenantApiController::class, 'listOrders']);
    $router->post('/api/v1/tenant/orders', [TenantApiController::class, 'createOrder']);
    $router->get('/api/v1/tenant/reports/summary', [TenantApiController::class, 'reportsSummary']);
}
