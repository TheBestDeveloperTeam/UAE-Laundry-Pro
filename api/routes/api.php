<?php

declare(strict_types=1);

use LaundryPro\Api\Controllers\AccountingController;
use LaundryPro\Api\Controllers\AnalyticsController;
use LaundryPro\Api\Controllers\AuthController;
use LaundryPro\Api\Controllers\BackupController;
use LaundryPro\Api\Controllers\BranchController;
use LaundryPro\Api\Controllers\BusinessController;
use LaundryPro\Api\Controllers\CatalogController;
use LaundryPro\Api\Controllers\ChallanController;
use LaundryPro\Api\Controllers\ChannelController;
use LaundryPro\Api\Controllers\CustomerController;
use LaundryPro\Api\Controllers\CustomerPortalController;
use LaundryPro\Api\Controllers\DeliveryController;
use LaundryPro\Api\Controllers\DocsController;
use LaundryPro\Api\Controllers\ExpenseController;
use LaundryPro\Api\Controllers\HealthController;
use LaundryPro\Api\Controllers\HrController;
use LaundryPro\Api\Controllers\InstallController;
use LaundryPro\Api\Controllers\InventoryController;
use LaundryPro\Api\Controllers\LanController;
use LaundryPro\Api\Controllers\LicenseController;
use LaundryPro\Api\Controllers\LocalizationController;
use LaundryPro\Api\Controllers\NotificationController;
use LaundryPro\Api\Controllers\PurchaseController;
use LaundryPro\Api\Controllers\ReportsController;
use LaundryPro\Api\Controllers\SalesController;
use LaundryPro\Api\Controllers\SettingsController;
use LaundryPro\Api\Controllers\StorefrontController;
use LaundryPro\Api\Controllers\SyncController;
use LaundryPro\Api\Controllers\TerminalController;
use LaundryPro\Api\Controllers\VendorController;
use LaundryPro\Api\Core\Router;
use LaundryPro\Api\Middleware\AuditMiddleware;
use LaundryPro\Api\Middleware\AuthMiddleware;
use LaundryPro\Api\Middleware\InstallRateLimitMiddleware;
use LaundryPro\Api\Middleware\InstallTokenMiddleware;
use LaundryPro\Api\Middleware\PermissionMiddleware;
use LaundryPro\Api\Middleware\RateLimitMiddleware;

function register_api_routes(Router $router): void
{
  $auth = [AuthMiddleware::class, PermissionMiddleware::class];
  $audit = [AuthMiddleware::class, PermissionMiddleware::class, AuditMiddleware::class];
  $loginRateLimit = [RateLimitMiddleware::class];
  $installAuth = [InstallRateLimitMiddleware::class, InstallTokenMiddleware::class, AuditMiddleware::class];

  $envelope = ['200' => 'OK', '400' => 'VALIDATION_ERROR', '401' => 'AUTH_SESSION_EXPIRED', '500' => 'SERVER_ERROR'];

  $router->get('/api/v1/health', [HealthController::class, 'index'], [], [
    'tag' => 'Platform',
    'summary' => 'Health check',
    'security' => false,
    'responses' => ['200' => 'HEALTH_OK', '500' => 'SERVER_ERROR'],
  ]);

  $router->get('/api/v1/docs/openapi.json', [DocsController::class, 'openapi'], [], [
    'tag' => 'Platform',
    'summary' => 'Live OpenAPI specification',
    'security' => false,
    'responses' => $envelope,
  ]);

  $router->get('/api/v1/docs', [DocsController::class, 'index'], [], [
    'tag' => 'Platform',
    'summary' => 'Swagger UI documentation shell',
    'security' => false,
    'responses' => ['200' => 'OK'],
  ]);

  $router->post('/api/v1/auth/login', [AuthController::class, 'login'], $loginRateLimit, [
    'tag' => 'Identity',
    'summary' => 'Login with username and password',
    'security' => false,
    'requestBody' => 'LoginRequest',
    'responses' => ['200' => 'AUTH_LOGIN_SUCCESS', '401' => 'AUTH_INVALID_CREDENTIALS', '422' => 'VALIDATION_ERROR', '429' => 'RATE_LIMIT_EXCEEDED'],
  ]);

  $router->post('/api/v1/auth/refresh', [AuthController::class, 'refresh'], $loginRateLimit, [
    'tag' => 'Identity',
    'summary' => 'Refresh access token',
    'security' => false,
    'requestBody' => 'RefreshRequest',
    'responses' => ['200' => 'AUTH_REFRESH_SUCCESS', '401' => 'AUTH_SESSION_EXPIRED', '422' => 'VALIDATION_ERROR', '429' => 'RATE_LIMIT_EXCEEDED'],
  ]);

  $router->post('/api/v1/auth/logout', [AuthController::class, 'logout'], $auth, [
    'tag' => 'Identity',
    'summary' => 'Logout and revoke refresh token',
    'responses' => ['200' => 'AUTH_LOGOUT_SUCCESS', '401' => 'AUTH_SESSION_EXPIRED'],
  ]);

  $router->get('/api/v1/auth/me', [AuthController::class, 'me'], $auth, [
    'tag' => 'Identity',
    'summary' => 'Current authenticated user',
    'responses' => ['200' => 'AUTH_ME_SUCCESS', '401' => 'AUTH_SESSION_EXPIRED'],
  ]);

  $router->get('/api/v1/settings', [SettingsController::class, 'index'], $auth, [
    'tag' => 'Configuration',
    'summary' => 'List application settings',
    'responses' => ['200' => 'SETTINGS_LIST', '401' => 'AUTH_SESSION_EXPIRED'],
  ]);

  $router->put('/api/v1/settings', [SettingsController::class, 'update'], $audit, [
    'tag' => 'Configuration',
    'summary' => 'Update application settings',
    'permission' => 'settings.update',
    'requestBody' => 'SettingsUpdateRequest',
    'responses' => ['200' => 'SETTINGS_UPDATED', '401' => 'AUTH_SESSION_EXPIRED', '403' => 'FORBIDDEN', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/business', [BusinessController::class, 'show'], $auth, [
    'tag' => 'Configuration', 'summary' => 'Get business profile', 'permission' => 'settings.read',
    'responses' => ['200' => 'BUSINESS_PROFILE', '404' => 'NOT_FOUND'],
  ]);
  $router->put('/api/v1/business', [BusinessController::class, 'update'], $audit, [
    'tag' => 'Configuration', 'summary' => 'Update business profile', 'permission' => 'settings.update',
    'responses' => ['200' => 'BUSINESS_UPDATED', '404' => 'NOT_FOUND', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/install/status', [InstallController::class, 'status'], [], [
    'tag' => 'Install',
    'summary' => 'Installation status',
    'security' => false,
    'responses' => ['200' => 'INSTALL_STATUS', '500' => 'SERVER_ERROR'],
  ]);

  $router->post('/api/v1/install/migrate', [InstallController::class, 'migrate'], $installAuth, [
    'tag' => 'Install',
    'summary' => 'Run pending database migrations',
    'security' => false,
    'securityScheme' => 'installToken',
    'responses' => ['200' => 'INSTALL_MIGRATED', '401' => 'INSTALL_UNAUTHORIZED', '403' => 'INSTALL_LOCKED', '429' => 'RATE_LIMIT_EXCEEDED'],
  ]);

  $router->post('/api/v1/install/seed', [InstallController::class, 'seed'], $installAuth, [
    'tag' => 'Install',
    'summary' => 'Run database seeds and set admin password',
    'security' => false,
    'securityScheme' => 'installToken',
    'requestBody' => 'SeedRequest',
    'responses' => ['200' => 'INSTALL_SEEDED', '401' => 'INSTALL_UNAUTHORIZED', '403' => 'INSTALL_LOCKED', '429' => 'RATE_LIMIT_EXCEEDED'],
  ]);

  $router->post('/api/v1/install/complete', [InstallController::class, 'complete'], $installAuth, [
    'tag' => 'Install',
    'summary' => 'Lock installer after successful setup',
    'security' => false,
    'securityScheme' => 'installToken',
    'responses' => ['200' => 'INSTALL_COMPLETE', '401' => 'INSTALL_UNAUTHORIZED', '403' => 'INSTALL_LOCKED', '409' => 'MIGRATIONS_PENDING', '429' => 'RATE_LIMIT_EXCEEDED'],
  ]);

  $router->get('/api/v1/customers', [CustomerController::class, 'index'], $auth, [
    'tag' => 'Customers', 'summary' => 'List customers', 'permission' => 'customers.read',
    'responses' => ['200' => 'CUSTOMERS_LIST', '401' => 'AUTH_SESSION_EXPIRED', '403' => 'FORBIDDEN'],
  ]);
  $router->get('/api/v1/customers/{id}', [CustomerController::class, 'show'], $auth, [
    'tag' => 'Customers', 'summary' => 'Get customer', 'permission' => 'customers.read',
    'responses' => ['200' => 'CUSTOMER_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/customers', [CustomerController::class, 'store'], $audit, [
    'tag' => 'Customers', 'summary' => 'Create customer', 'permission' => 'customers.create',
    'responses' => ['201' => 'CUSTOMER_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->put('/api/v1/customers/{id}', [CustomerController::class, 'update'], $audit, [
    'tag' => 'Customers', 'summary' => 'Update customer', 'permission' => 'customers.update',
    'responses' => ['200' => 'CUSTOMER_UPDATED', '404' => 'NOT_FOUND'],
  ]);

  $router->get('/api/v1/vendors', [VendorController::class, 'index'], $auth, [
    'tag' => 'Vendors', 'summary' => 'List vendors', 'permission' => 'vendors.read',
    'responses' => ['200' => 'VENDORS_LIST'],
  ]);
  $router->get('/api/v1/vendors/{id}', [VendorController::class, 'show'], $auth, [
    'tag' => 'Vendors', 'summary' => 'Get vendor', 'permission' => 'vendors.read',
    'responses' => ['200' => 'VENDOR_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/vendors', [VendorController::class, 'store'], $audit, [
    'tag' => 'Vendors', 'summary' => 'Create vendor', 'permission' => 'vendors.create',
    'responses' => ['201' => 'VENDOR_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->put('/api/v1/vendors/{id}', [VendorController::class, 'update'], $audit, [
    'tag' => 'Vendors', 'summary' => 'Update vendor', 'permission' => 'vendors.update',
    'responses' => ['200' => 'VENDOR_UPDATED', '404' => 'NOT_FOUND'],
  ]);

  $router->get('/api/v1/services', [CatalogController::class, 'services'], $auth, [
    'tag' => 'Catalog', 'summary' => 'List services', 'permission' => 'catalog.read',
    'responses' => ['200' => 'SERVICES_LIST'],
  ]);
  $router->get('/api/v1/services/{id}', [CatalogController::class, 'showService'], $auth, [
    'tag' => 'Catalog', 'summary' => 'Get service', 'permission' => 'catalog.read',
    'responses' => ['200' => 'SERVICE_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->put('/api/v1/services/{id}', [CatalogController::class, 'updateService'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Update service', 'permission' => 'catalog.update',
    'responses' => ['200' => 'SERVICE_UPDATED', '404' => 'NOT_FOUND', '422' => 'HIERARCHY_CYCLE'],
  ]);
  $router->get('/api/v1/services/{id}/products', [CatalogController::class, 'serviceProducts'], $auth, [
    'tag' => 'Catalog', 'summary' => 'List service products', 'permission' => 'catalog.read',
    'responses' => ['200' => 'SERVICE_PRODUCTS', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/services/{id}/products', [CatalogController::class, 'attachServiceProduct'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Attach product to service', 'permission' => 'catalog.update',
    'responses' => ['201' => 'SERVICE_PRODUCT_ATTACHED', '404' => 'NOT_FOUND', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->delete('/api/v1/services/{id}/products/{productId}', [CatalogController::class, 'detachServiceProduct'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Detach product from service', 'permission' => 'catalog.update',
    'responses' => ['200' => 'SERVICE_PRODUCT_DETACHED', '404' => 'NOT_FOUND'],
  ]);
  $router->get('/api/v1/services/{id}/modifiers', [CatalogController::class, 'serviceModifiers'], $auth, [
    'tag' => 'Catalog', 'summary' => 'List service modifiers', 'permission' => 'catalog.read',
    'responses' => ['200' => 'SERVICE_MODIFIERS', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/services/{id}/modifiers', [CatalogController::class, 'createServiceModifier'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Create service modifier', 'permission' => 'catalog.create',
    'responses' => ['201' => 'SERVICE_MODIFIER_CREATED', '404' => 'NOT_FOUND', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/products/{id}', [CatalogController::class, 'showProduct'], $auth, [
    'tag' => 'Catalog', 'summary' => 'Get product', 'permission' => 'catalog.read',
    'responses' => ['200' => 'PRODUCT_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->put('/api/v1/products/{id}', [CatalogController::class, 'updateProduct'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Update product', 'permission' => 'catalog.update',
    'responses' => ['200' => 'PRODUCT_UPDATED', '404' => 'NOT_FOUND', '422' => 'HIERARCHY_CYCLE'],
  ]);
  $router->get('/api/v1/products/{id}/modifiers', [CatalogController::class, 'productModifiers'], $auth, [
    'tag' => 'Catalog', 'summary' => 'List product modifiers', 'permission' => 'catalog.read',
    'responses' => ['200' => 'PRODUCT_MODIFIERS', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/products/{id}/modifiers', [CatalogController::class, 'createProductModifier'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Create product modifier', 'permission' => 'catalog.create',
    'responses' => ['201' => 'PRODUCT_MODIFIER_CREATED', '404' => 'NOT_FOUND', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/services', [CatalogController::class, 'createService'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Create service', 'permission' => 'catalog.create',
    'responses' => ['201' => 'SERVICE_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/products', [CatalogController::class, 'products'], $auth, [
    'tag' => 'Catalog', 'summary' => 'List products', 'permission' => 'catalog.read',
    'responses' => ['200' => 'PRODUCTS_LIST'],
  ]);
  $router->post('/api/v1/products', [CatalogController::class, 'createProduct'], $audit, [
    'tag' => 'Catalog', 'summary' => 'Create product', 'permission' => 'catalog.create',
    'responses' => ['201' => 'PRODUCT_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/sales', [SalesController::class, 'index'], $auth, [
    'tag' => 'Sales', 'summary' => 'List sales orders', 'permission' => 'sales.read',
    'responses' => ['200' => 'SALES_LIST', '401' => 'AUTH_SESSION_EXPIRED'],
  ]);
  $router->get('/api/v1/sales/{id}', [SalesController::class, 'show'], $auth, [
    'tag' => 'Sales', 'summary' => 'Get sale', 'permission' => 'sales.read',
    'responses' => ['200' => 'SALE_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/sales/draft', [SalesController::class, 'draft'], $audit, [
    'tag' => 'Sales', 'summary' => 'Create draft sale', 'permission' => 'sales.create',
    'responses' => ['201' => 'SALE_DRAFT_CREATED'],
  ]);
  $router->post('/api/v1/sales/{id}/confirm', [SalesController::class, 'confirm'], $audit, [
    'tag' => 'Sales', 'summary' => 'Confirm sale', 'permission' => 'sales.create',
    'responses' => ['200' => 'SALE_CONFIRMED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/sales/{id}/payment', [SalesController::class, 'payment'], $audit, [
    'tag' => 'Sales', 'summary' => 'Post payment', 'permission' => 'sales.receive_payment',
    'responses' => ['200' => 'SALE_PAYMENT_POSTED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->patch('/api/v1/sales/{id}/status', [SalesController::class, 'updateStatus'], $audit, [
    'tag' => 'Sales', 'summary' => 'Update order status', 'permission' => 'sales.update_status',
    'responses' => ['200' => 'SALE_STATUS_UPDATED', '422' => 'VALIDATION_ERROR', '404' => 'NOT_FOUND'],
  ]);
  $router->get('/api/v1/sales/{id}/status-history', [SalesController::class, 'statusHistory'], $auth, [
    'tag' => 'Sales', 'summary' => 'Order status history', 'permission' => 'sales.read',
    'responses' => ['200' => 'SALE_STATUS_HISTORY', '404' => 'NOT_FOUND'],
  ]);
  $router->get('/api/v1/sales/{id}/delivery-tasks', [SalesController::class, 'listDeliveryTasks'], $auth, [
    'tag' => 'Sales', 'summary' => 'List delivery tasks for order', 'permission' => 'delivery.read',
    'responses' => ['200' => 'SALE_DELIVERY_TASKS', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/sales/{id}/delivery-tasks', [SalesController::class, 'storeDeliveryTask'], $audit, [
    'tag' => 'Sales', 'summary' => 'Create delivery task for order', 'permission' => 'delivery.write',
    'responses' => ['201' => 'SALE_DELIVERY_CREATED', '404' => 'NOT_FOUND', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/employees', [HrController::class, 'listEmployees'], $auth, [
    'tag' => 'HR', 'summary' => 'List employees', 'permission' => 'hr.read',
    'responses' => ['200' => 'EMPLOYEES_LIST'],
  ]);
  $router->get('/api/v1/employees/{id}', [HrController::class, 'showEmployee'], $auth, [
    'tag' => 'HR', 'summary' => 'Get employee', 'permission' => 'hr.read',
    'responses' => ['200' => 'EMPLOYEE_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/employees', [HrController::class, 'storeEmployee'], $audit, [
    'tag' => 'HR', 'summary' => 'Create employee', 'permission' => 'hr.write',
    'responses' => ['201' => 'EMPLOYEE_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->put('/api/v1/employees/{id}', [HrController::class, 'updateEmployee'], $audit, [
    'tag' => 'HR', 'summary' => 'Update employee', 'permission' => 'hr.write',
    'responses' => ['200' => 'EMPLOYEE_UPDATED', '404' => 'NOT_FOUND'],
  ]);
  $router->delete('/api/v1/employees/{id}', [HrController::class, 'deactivateEmployee'], $audit, [
    'tag' => 'HR', 'summary' => 'Deactivate employee', 'permission' => 'hr.write',
    'responses' => ['200' => 'EMPLOYEE_DEACTIVATED', '404' => 'NOT_FOUND'],
  ]);
  $router->get('/api/v1/attendance', [HrController::class, 'listAttendance'], $auth, [
    'tag' => 'HR', 'summary' => 'List attendance', 'permission' => 'hr.read',
    'responses' => ['200' => 'ATTENDANCE_LIST'],
  ]);
  $router->post('/api/v1/attendance', [HrController::class, 'recordAttendance'], $audit, [
    'tag' => 'HR', 'summary' => 'Record attendance', 'permission' => 'attendance.write',
    'responses' => ['201' => 'ATTENDANCE_RECORDED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/leave-requests', [HrController::class, 'listLeave'], $auth, [
    'tag' => 'HR', 'summary' => 'List leave requests', 'permission' => 'hr.read',
    'responses' => ['200' => 'LEAVE_LIST'],
  ]);
  $router->get('/api/v1/leave-types', [HrController::class, 'listLeaveTypes'], $auth, [
    'tag' => 'HR', 'summary' => 'List leave types', 'permission' => 'hr.read',
    'responses' => ['200' => 'LEAVE_TYPES'],
  ]);
  $router->post('/api/v1/leave-requests', [HrController::class, 'storeLeave'], $audit, [
    'tag' => 'HR', 'summary' => 'Create leave request', 'permission' => 'hr.write',
    'responses' => ['201' => 'LEAVE_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/leave-requests/{id}/approve', [HrController::class, 'approveLeave'], $audit, [
    'tag' => 'HR', 'summary' => 'Approve leave request', 'permission' => 'leave.approve',
    'responses' => ['200' => 'LEAVE_APPROVED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/leave-requests/{id}/reject', [HrController::class, 'rejectLeave'], $audit, [
    'tag' => 'HR', 'summary' => 'Reject leave request', 'permission' => 'leave.approve',
    'responses' => ['200' => 'LEAVE_REJECTED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/payroll/periods', [HrController::class, 'listPayrollPeriods'], $auth, [
    'tag' => 'HR', 'summary' => 'List payroll periods', 'permission' => 'payroll.read',
    'responses' => ['200' => 'PAYROLL_PERIODS'],
  ]);
  $router->post('/api/v1/payroll/periods', [HrController::class, 'storePayrollPeriod'], $audit, [
    'tag' => 'HR', 'summary' => 'Create payroll period', 'permission' => 'payroll.run',
    'responses' => ['201' => 'PAYROLL_PERIOD_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/payroll/run', [HrController::class, 'runPayroll'], $audit, [
    'tag' => 'HR', 'summary' => 'Run payroll for period', 'permission' => 'payroll.run',
    'responses' => ['201' => 'PAYROLL_RUN_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/payroll/periods/{id}/run', [HrController::class, 'runPayroll'], $audit, [
    'tag' => 'HR', 'summary' => 'Run payroll for period by id', 'permission' => 'payroll.run',
    'responses' => ['201' => 'PAYROLL_RUN_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/payroll/runs', [HrController::class, 'listPayrollRuns'], $auth, [
    'tag' => 'HR', 'summary' => 'List payroll runs', 'permission' => 'payroll.read',
    'responses' => ['200' => 'PAYROLL_RUNS'],
  ]);
  $router->get('/api/v1/payroll/runs/{id}', [HrController::class, 'showPayrollRun'], $auth, [
    'tag' => 'HR', 'summary' => 'Get payroll run detail', 'permission' => 'payroll.read',
    'responses' => ['200' => 'PAYROLL_RUN_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->get('/api/v1/salary-advances', [HrController::class, 'listSalaryAdvances'], $auth, [
    'tag' => 'HR', 'summary' => 'List salary advances', 'permission' => 'payroll.read',
    'responses' => ['200' => 'SALARY_ADVANCES'],
  ]);
  $router->post('/api/v1/salary-advances', [HrController::class, 'storeSalaryAdvance'], $audit, [
    'tag' => 'HR', 'summary' => 'Create salary advance', 'permission' => 'hr.write',
    'responses' => ['201' => 'SALARY_ADVANCE_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/expense-categories', [ExpenseController::class, 'listCategories'], $auth, [
    'tag' => 'Expenses', 'summary' => 'List expense categories', 'permission' => 'expenses.read',
    'responses' => ['200' => 'EXPENSE_CATEGORIES'],
  ]);
  $router->post('/api/v1/expense-categories', [ExpenseController::class, 'storeCategory'], $audit, [
    'tag' => 'Expenses', 'summary' => 'Create expense category', 'permission' => 'expenses.write',
    'responses' => ['201' => 'EXPENSE_CATEGORY_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/expenses', [ExpenseController::class, 'index'], $auth, [
    'tag' => 'Expenses', 'summary' => 'List expenses', 'permission' => 'expenses.read',
    'responses' => ['200' => 'EXPENSES_LIST'],
  ]);
  $router->get('/api/v1/expenses/{id}', [ExpenseController::class, 'show'], $auth, [
    'tag' => 'Expenses', 'summary' => 'Get expense', 'permission' => 'expenses.read',
    'responses' => ['200' => 'EXPENSE_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/expenses', [ExpenseController::class, 'store'], $audit, [
    'tag' => 'Expenses', 'summary' => 'Create expense', 'permission' => 'expenses.write',
    'responses' => ['201' => 'EXPENSE_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/expenses/{id}/approve', [ExpenseController::class, 'approve'], $audit, [
    'tag' => 'Expenses', 'summary' => 'Approve expense', 'permission' => 'expenses.approve',
    'responses' => ['200' => 'EXPENSE_APPROVED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/expenses/{id}/reject', [ExpenseController::class, 'reject'], $audit, [
    'tag' => 'Expenses', 'summary' => 'Reject expense', 'permission' => 'expenses.approve',
    'responses' => ['200' => 'EXPENSE_REJECTED', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/delivery-tasks', [DeliveryController::class, 'index'], $auth, [
    'tag' => 'Delivery', 'summary' => 'List delivery tasks', 'permission' => 'delivery.read',
    'responses' => ['200' => 'DELIVERY_TASKS'],
  ]);
  $router->get('/api/v1/delivery-tasks/{id}', [DeliveryController::class, 'show'], $auth, [
    'tag' => 'Delivery', 'summary' => 'Get delivery task', 'permission' => 'delivery.read',
    'responses' => ['200' => 'DELIVERY_TASK', '404' => 'NOT_FOUND'],
  ]);
  $router->patch('/api/v1/delivery-tasks/{id}', [DeliveryController::class, 'update'], $audit, [
    'tag' => 'Delivery', 'summary' => 'Update delivery task', 'permission' => 'delivery.write',
    'responses' => ['200' => 'DELIVERY_UPDATED', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/delivery-tasks', [DeliveryController::class, 'store'], $audit, [
    'tag' => 'Delivery', 'summary' => 'Schedule delivery task', 'permission' => 'delivery.write',
    'responses' => ['201' => 'DELIVERY_TASK_SCHEDULED', '404' => 'NOT_FOUND', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/delivery-tasks/{id}/complete', [DeliveryController::class, 'complete'], $audit, [
    'tag' => 'Delivery', 'summary' => 'Complete delivery task', 'permission' => 'delivery.write',
    'responses' => ['200' => 'DELIVERY_TASK_COMPLETED', '404' => 'NOT_FOUND'],
  ]);

  $router->get('/api/v1/challans', [ChallanController::class, 'index'], $auth, [
    'tag' => 'Challans', 'summary' => 'List challans', 'permission' => 'challans.read',
    'responses' => ['200' => 'CHALLANS_LIST'],
  ]);
  $router->get('/api/v1/challans/{id}', [ChallanController::class, 'show'], $auth, [
    'tag' => 'Challans', 'summary' => 'Get challan', 'permission' => 'challans.read',
    'responses' => ['200' => 'CHALLAN_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/challans', [ChallanController::class, 'store'], $audit, [
    'tag' => 'Challans', 'summary' => 'Create challan', 'permission' => 'challans.write',
    'responses' => ['201' => 'CHALLAN_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->put('/api/v1/challans/{id}', [ChallanController::class, 'update'], $audit, [
    'tag' => 'Challans', 'summary' => 'Update challan', 'permission' => 'challans.write',
    'responses' => ['200' => 'CHALLAN_UPDATED', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/challans/{id}/cancel', [ChallanController::class, 'cancel'], $audit, [
    'tag' => 'Challans', 'summary' => 'Cancel challan', 'permission' => 'challans.write',
    'responses' => ['200' => 'CHALLAN_CANCELLED', '404' => 'NOT_FOUND'],
  ]);

  $router->get('/api/v1/purchase-orders', [PurchaseController::class, 'index'], $auth, [
    'tag' => 'Purchasing', 'summary' => 'List purchase orders', 'permission' => 'purchasing.read',
    'responses' => ['200' => 'PURCHASE_ORDERS'],
  ]);
  $router->get('/api/v1/purchase-orders/{id}', [PurchaseController::class, 'show'], $auth, [
    'tag' => 'Purchasing', 'summary' => 'Get purchase order', 'permission' => 'purchasing.read',
    'responses' => ['200' => 'PURCHASE_ORDER', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/purchase-orders', [PurchaseController::class, 'store'], $audit, [
    'tag' => 'Purchasing', 'summary' => 'Create purchase order', 'permission' => 'purchasing.write',
    'responses' => ['201' => 'PURCHASE_ORDER_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->put('/api/v1/purchase-orders/{id}', [PurchaseController::class, 'update'], $audit, [
    'tag' => 'Purchasing', 'summary' => 'Update purchase order', 'permission' => 'purchasing.write',
    'responses' => ['200' => 'PURCHASE_ORDER_UPDATED', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/purchase-orders/{id}/receive', [PurchaseController::class, 'receive'], $audit, [
    'tag' => 'Purchasing', 'summary' => 'Receive goods against PO', 'permission' => 'purchasing.write',
    'responses' => ['200' => 'PURCHASE_ORDER_RECEIVED', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/notifications', [NotificationController::class, 'index'], $auth, [
    'tag' => 'Notifications', 'summary' => 'List notifications', 'permission' => 'notifications.read',
    'responses' => ['200' => 'NOTIFICATIONS_LIST'],
  ]);
  $router->get('/api/v1/notifications/{id}', [NotificationController::class, 'show'], $auth, [
    'tag' => 'Notifications', 'summary' => 'Get notification', 'permission' => 'notifications.read',
    'responses' => ['200' => 'NOTIFICATION_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/notifications/{id}/read', [NotificationController::class, 'markRead'], $audit, [
    'tag' => 'Notifications', 'summary' => 'Mark notification read', 'permission' => 'notifications.read',
    'responses' => ['200' => 'NOTIFICATION_READ', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/notifications/read-all', [NotificationController::class, 'markAllRead'], $audit, [
    'tag' => 'Notifications', 'summary' => 'Mark all notifications read', 'permission' => 'notifications.read',
    'responses' => ['200' => 'NOTIFICATIONS_READ_ALL'],
  ]);
  $router->post('/api/v1/notifications/generate', [NotificationController::class, 'generate'], $audit, [
    'tag' => 'Notifications', 'summary' => 'Generate alert notifications', 'permission' => 'notifications.write',
    'responses' => ['200' => 'NOTIFICATIONS_GENERATED'],
  ]);

  $router->get('/api/v1/reports/sales/summary', [ReportsController::class, 'salesSummary'], $auth, [
    'tag' => 'Reports', 'summary' => 'Sales summary report', 'permission' => 'reports.read',
    'responses' => ['200' => 'SALES_SUMMARY', '401' => 'AUTH_SESSION_EXPIRED'],
  ]);
  $router->get('/api/v1/reports/expenses/summary', [ReportsController::class, 'expensesSummary'], $auth, [
    'tag' => 'Reports', 'summary' => 'Expenses summary report', 'permission' => 'reports.read',
    'responses' => ['200' => 'EXPENSES_SUMMARY'],
  ]);
  $router->get('/api/v1/reports/payroll/summary', [ReportsController::class, 'payrollSummary'], $auth, [
    'tag' => 'Reports', 'summary' => 'Payroll summary report', 'permission' => 'reports.read',
    'responses' => ['200' => 'PAYROLL_SUMMARY'],
  ]);
  $router->get('/api/v1/reports/inventory/valuation', [ReportsController::class, 'inventoryValuation'], $auth, [
    'tag' => 'Reports', 'summary' => 'Inventory valuation report', 'permission' => 'reports.read',
    'responses' => ['200' => 'INVENTORY_VALUATION'],
  ]);
  $router->get('/api/v1/reports/production/throughput', [ReportsController::class, 'productionThroughput'], $auth, [
    'tag' => 'Reports', 'summary' => 'Production throughput report', 'permission' => 'reports.read',
    'responses' => ['200' => 'PRODUCTION_THROUGHPUT'],
  ]);
  $router->get('/api/v1/reports/inventory', [ReportsController::class, 'inventoryReport'], $auth, [
    'tag' => 'Reports', 'summary' => 'Inventory report', 'permission' => 'reports.read',
    'responses' => ['200' => 'INVENTORY_REPORT'],
  ]);
  $router->get('/api/v1/reports/payroll', [ReportsController::class, 'payrollReport'], $auth, [
    'tag' => 'Reports', 'summary' => 'Payroll report', 'permission' => 'reports.read',
    'responses' => ['200' => 'PAYROLL_REPORT'],
  ]);
  $router->get('/api/v1/reports/expenses', [ReportsController::class, 'expensesReport'], $auth, [
    'tag' => 'Reports', 'summary' => 'Expense report', 'permission' => 'reports.read',
    'responses' => ['200' => 'EXPENSE_REPORT'],
  ]);
  $router->get('/api/v1/reports/production', [ReportsController::class, 'productionReport'], $auth, [
    'tag' => 'Reports', 'summary' => 'Production report', 'permission' => 'reports.read',
    'responses' => ['200' => 'PRODUCTION_REPORT'],
  ]);
  $router->get('/api/v1/reports/purchasing', [ReportsController::class, 'purchasingReport'], $auth, [
    'tag' => 'Reports', 'summary' => 'Purchasing report', 'permission' => 'reports.read',
    'responses' => ['200' => 'PURCHASING_REPORT'],
  ]);
  $router->get('/api/v1/reports/delivery', [ReportsController::class, 'deliveryReport'], $auth, [
    'tag' => 'Reports', 'summary' => 'Delivery report', 'permission' => 'reports.read',
    'responses' => ['200' => 'DELIVERY_REPORT'],
  ]);

  $router->get('/api/v1/sync/status', [SyncController::class, 'status'], $auth, [
    'tag' => 'Sync', 'summary' => 'Sync status', 'permission' => 'sync.read',
    'responses' => ['200' => 'SYNC_STATUS'],
  ]);
  $router->post('/api/v1/sync/push', [SyncController::class, 'push'], $audit, [
    'tag' => 'Sync', 'summary' => 'Push pending changes', 'permission' => 'sync.push',
    'responses' => ['200' => 'SYNC_PUSHED'],
  ]);
  $router->get('/api/v1/sync/pull', [SyncController::class, 'pull'], $auth, [
    'tag' => 'Sync', 'summary' => 'Pull remote changes', 'permission' => 'sync.pull',
    'responses' => ['200' => 'SYNC_PULLED'],
  ]);
  $router->put('/api/v1/sync/config', [SyncController::class, 'configure'], $audit, [
    'tag' => 'Sync', 'summary' => 'Configure sync', 'permission' => 'sync.manage',
    'responses' => ['200' => 'SYNC_CONFIGURED'],
  ]);
  $router->get('/api/v1/sync/entities', [SyncController::class, 'entities'], $auth, [
    'tag' => 'Sync', 'summary' => 'List sync entity types', 'permission' => 'sync.read',
    'responses' => ['200' => 'SYNC_ENTITIES'],
  ]);

  $router->get('/api/v1/license/status', [LicenseController::class, 'status'], $auth, [
    'tag' => 'License', 'summary' => 'License status', 'permission' => 'license.read',
    'responses' => ['200' => 'LICENSE_STATUS'],
  ]);
  $router->post('/api/v1/license/activate', [LicenseController::class, 'activate'], $audit, [
    'tag' => 'License', 'summary' => 'Activate license', 'permission' => 'license.manage',
    'responses' => ['200' => 'LICENSE_ACTIVATED', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->get('/api/v1/inventory/movements', [InventoryController::class, 'movements'], $auth, [
    'tag' => 'Inventory', 'summary' => 'List inventory movements', 'permission' => 'inventory.read',
    'responses' => ['200' => 'INVENTORY_MOVEMENTS'],
  ]);
  $router->post('/api/v1/inventory/receipt', [InventoryController::class, 'receipt'], $audit, [
    'tag' => 'Inventory', 'summary' => 'Stock receipt', 'permission' => 'inventory.create',
    'responses' => ['201' => 'INVENTORY_RECEIPT', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/inventory/adjustment', [InventoryController::class, 'adjustment'], $audit, [
    'tag' => 'Inventory', 'summary' => 'Stock adjustment', 'permission' => 'inventory.update',
    'responses' => ['200' => 'INVENTORY_ADJUSTED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/inventory/stock', [InventoryController::class, 'stock'], $auth, [
    'tag' => 'Inventory', 'summary' => 'Current stock levels from movements', 'permission' => 'inventory.read',
    'responses' => ['200' => 'INVENTORY_STOCK'],
  ]);
  $router->post('/api/v1/inventory/reconcile', [InventoryController::class, 'reconcile'], $audit, [
    'tag' => 'Inventory', 'summary' => 'Stock reconciliation dry-run or confirm', 'permission' => 'inventory.reconcile',
    'responses' => ['200' => 'INVENTORY_RECONCILE_PREVIEW', '422' => 'VALIDATION_ERROR'],
  ]);

  $router->post('/api/v1/backup/run', [BackupController::class, 'run'], $audit, [
    'tag' => 'Backup', 'summary' => 'Run backup', 'permission' => 'backup.run',
    'responses' => ['200' => 'BACKUP_CREATED', '500' => 'BACKUP_FAILED'],
  ]);
  $router->post('/api/v1/backup/verify', [BackupController::class, 'verify'], $audit, [
    'tag' => 'Backup', 'summary' => 'Verify backup', 'permission' => 'backup.run',
    'responses' => ['200' => 'BACKUP_VERIFIED', '404' => 'BACKUP_NOT_FOUND', '422' => 'BACKUP_INVALID'],
  ]);
  $router->post('/api/v1/backup/restore/validate', [BackupController::class, 'restoreValidate'], $audit, [
    'tag' => 'Backup', 'summary' => 'Validate restore dry-run', 'permission' => 'backup.run',
    'responses' => ['200' => 'BACKUP_RESTORE_VALIDATED', '422' => 'BACKUP_INVALID'],
  ]);
  $router->post('/api/v1/backup/restore', [BackupController::class, 'restore'], $audit, [
    'tag' => 'Backup', 'summary' => 'Restore backup to staging', 'permission' => 'backup.run',
    'responses' => ['200' => 'BACKUP_RESTORED', '422' => 'CONFIRM_REQUIRED', '500' => 'RESTORE_FAILED'],
  ]);
  $router->get('/api/v1/backup/history', [BackupController::class, 'history'], $auth, [
    'tag' => 'Backup', 'summary' => 'Backup history', 'permission' => 'backup.read',
    'responses' => ['200' => 'BACKUP_HISTORY'],
  ]);

  // Phase 3 — Branches & Terminals
  $router->get('/api/v1/branches', [BranchController::class, 'index'], $auth, [
    'tag' => 'Branches', 'summary' => 'List branches', 'permission' => 'business.read',
    'responses' => ['200' => 'BRANCHES_LIST'],
  ]);
  $router->get('/api/v1/branches/{id}', [BranchController::class, 'show'], $auth, [
    'tag' => 'Branches', 'summary' => 'Branch detail', 'permission' => 'business.read',
    'responses' => ['200' => 'BRANCH_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/branches', [BranchController::class, 'store'], $audit, [
    'tag' => 'Branches', 'summary' => 'Create branch', 'permission' => 'business.write',
    'responses' => ['201' => 'BRANCH_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->put('/api/v1/branches/{id}', [BranchController::class, 'update'], $audit, [
    'tag' => 'Branches', 'summary' => 'Update branch', 'permission' => 'business.write',
    'responses' => ['200' => 'BRANCH_UPDATED', '404' => 'NOT_FOUND'],
  ]);

  $router->get('/api/v1/terminals', [TerminalController::class, 'index'], $auth, [
    'tag' => 'Terminals', 'summary' => 'List terminals', 'permission' => 'business.read',
    'responses' => ['200' => 'TERMINALS_LIST'],
  ]);
  $router->post('/api/v1/terminals', [TerminalController::class, 'store'], $audit, [
    'tag' => 'Terminals', 'summary' => 'Create terminal', 'permission' => 'business.write',
    'responses' => ['201' => 'TERMINAL_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/terminals/{id}/register', [TerminalController::class, 'register'], $audit, [
    'tag' => 'Terminals', 'summary' => 'Register terminal session', 'permission' => 'business.write',
    'responses' => ['201' => 'TERMINAL_REGISTERED', '404' => 'NOT_FOUND', '409' => 'TERMINAL_LIMIT'],
  ]);

  // Phase 3 — LAN node
  $router->get('/api/v1/lan/status', [LanController::class, 'status'], $auth, [
    'tag' => 'LAN', 'summary' => 'LAN node status', 'permission' => 'sync.read',
    'responses' => ['200' => 'LAN_NODE_STATUS'],
  ]);
  $router->put('/api/v1/lan/bind', [LanController::class, 'bind'], $audit, [
    'tag' => 'LAN', 'summary' => 'Configure LAN bind', 'permission' => 'sync.manage',
    'responses' => ['200' => 'LAN_NODE_CONFIGURED'],
  ]);

  // Phase 3 — Analytics
  $router->get('/api/v1/analytics/summary', [AnalyticsController::class, 'summary'], $auth, [
    'tag' => 'Analytics', 'summary' => 'Today analytics summary', 'permission' => 'reports.read',
    'responses' => ['200' => 'ANALYTICS_SUMMARY'],
  ]);
  $router->get('/api/v1/analytics/trends', [AnalyticsController::class, 'trends'], $auth, [
    'tag' => 'Analytics', 'summary' => 'Analytics trend series', 'permission' => 'reports.read',
    'responses' => ['200' => 'ANALYTICS_TRENDS'],
  ]);
  $router->post('/api/v1/analytics/refresh', [AnalyticsController::class, 'refresh'], $audit, [
    'tag' => 'Analytics', 'summary' => 'Refresh analytics snapshots', 'permission' => 'reports.read',
    'responses' => ['200' => 'ANALYTICS_REFRESHED'],
  ]);

  // Phase 3 — Localization / KSA
  $router->get('/api/v1/localization/profiles', [LocalizationController::class, 'profiles'], $auth, [
    'tag' => 'Localization', 'summary' => 'Country profiles', 'permission' => 'settings.read',
    'responses' => ['200' => 'LOCALIZATION_PROFILES'],
  ]);
  $router->put('/api/v1/localization/country', [LocalizationController::class, 'setCountry'], $audit, [
    'tag' => 'Localization', 'summary' => 'Set business country profile', 'permission' => 'settings.write',
    'responses' => ['200' => 'LOCALIZATION_UPDATED', '404' => 'NOT_FOUND'],
  ]);

  // Phase 3 — Notification channels
  $router->get('/api/v1/channels', [ChannelController::class, 'index'], $auth, [
    'tag' => 'Channels', 'summary' => 'List notification channels', 'permission' => 'settings.read',
    'responses' => ['200' => 'CHANNELS_LIST'],
  ]);
  $router->post('/api/v1/channels', [ChannelController::class, 'store'], $audit, [
    'tag' => 'Channels', 'summary' => 'Create notification channel', 'permission' => 'settings.write',
    'responses' => ['201' => 'CHANNEL_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->post('/api/v1/channels/{id}/test', [ChannelController::class, 'test'], $audit, [
    'tag' => 'Channels', 'summary' => 'Send test message', 'permission' => 'settings.write',
    'responses' => ['200' => 'CHANNEL_TEST_SENT', '404' => 'NOT_FOUND'],
  ]);

  // Phase 3 — Accounting export
  $router->get('/api/v1/accounting/batches', [AccountingController::class, 'index'], $auth, [
    'tag' => 'Accounting', 'summary' => 'List export batches', 'permission' => 'reports.read',
    'responses' => ['200' => 'ACCOUNTING_BATCHES_LIST'],
  ]);
  $router->get('/api/v1/accounting/batches/{id}', [AccountingController::class, 'show'], $auth, [
    'tag' => 'Accounting', 'summary' => 'Export batch detail', 'permission' => 'reports.read',
    'responses' => ['200' => 'ACCOUNTING_BATCH_DETAIL', '404' => 'NOT_FOUND'],
  ]);
  $router->post('/api/v1/accounting/export', [AccountingController::class, 'export'], $audit, [
    'tag' => 'Accounting', 'summary' => 'Create accounting export', 'permission' => 'reports.read',
    'responses' => ['201' => 'ACCOUNTING_EXPORT_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);

  // Phase 3 — Storefront (public catalog + order submit)
  $router->get('/api/v1/storefront/catalog', [StorefrontController::class, 'catalog'], [], [
    'tag' => 'Storefront', 'summary' => 'Public catalog', 'security' => false,
    'responses' => ['200' => 'STOREFRONT_CATALOG'],
  ]);
  $router->post('/api/v1/storefront/orders', [StorefrontController::class, 'submitOrder'], [], [
    'tag' => 'Storefront', 'summary' => 'Submit storefront order', 'security' => false,
    'responses' => ['201' => 'STOREFRONT_ORDER_CREATED', '422' => 'VALIDATION_ERROR'],
  ]);
  $router->get('/api/v1/storefront/orders', [StorefrontController::class, 'listOrders'], $auth, [
    'tag' => 'Storefront', 'summary' => 'List storefront orders', 'permission' => 'sales.read',
    'responses' => ['200' => 'STOREFRONT_ORDERS_LIST'],
  ]);
  $router->post('/api/v1/storefront/orders/{id}/convert', [StorefrontController::class, 'convert'], $audit, [
    'tag' => 'Storefront', 'summary' => 'Convert storefront order to sales draft', 'permission' => 'sales.create',
    'responses' => ['200' => 'STOREFRONT_CONVERTED', '404' => 'NOT_FOUND'],
  ]);

  // Phase 3 — Customer portal
  $router->post('/api/v1/portal/tokens', [CustomerPortalController::class, 'createToken'], $auth, [
    'tag' => 'Portal', 'summary' => 'Create customer portal token', 'permission' => 'sales.read',
    'responses' => ['201' => 'PORTAL_TOKEN_CREATED', '404' => 'NOT_FOUND'],
  ]);
  $router->get('/api/v1/portal/order', [CustomerPortalController::class, 'orderStatus'], [], [
    'tag' => 'Portal', 'summary' => 'Customer order status by token', 'security' => false,
    'responses' => ['200' => 'PORTAL_ORDER_STATUS', '404' => 'NOT_FOUND'],
  ]);
}
