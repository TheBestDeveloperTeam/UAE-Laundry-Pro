<?php

declare(strict_types=1);

spl_autoload_register(function (string $class): void {
    $prefix = 'LaundryPro\\Cloud\\';
    $baseDir = dirname(__DIR__) . '/src/';
    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }
    $relativeClass = substr($class, $len);
    $file = $baseDir . str_replace('\\', '/', $relativeClass) . '.php';
    if (file_exists($file)) {
        require_once $file;
    }
});

require_once dirname(__DIR__) . '/routes/api.php';

use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Core\Router;

Response::$shouldExit = false;

$passed = 0;
$failed = 0;

function assertTest(string $name, bool $condition): void
{
    global $passed, $failed;
    if ($condition) {
        echo "[PASS] $name\n";
        $passed++;
    } else {
        echo "[FAIL] $name\n";
        $failed++;
    }
}

echo "=== Running Cloud Domain Parity Tests ===\n";

$router = new Router();
register_cloud_api_routes($router);

// Test 1: Health check
ob_start();
$req = new Request('GET', '/api/v1/health');
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Health endpoint returns JSON envelope', isset($data['code']));

// Test 2: Auth login validation
ob_start();
$req = new Request('POST', '/api/v1/auth/login', [], ['username' => 'admin', 'password' => 'admin']);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
$token = $data['data']['token'] ?? '';
assertTest('Auth login returns valid JWT token', !empty($token));
$authHeader = ['Authorization' => 'Bearer ' . $token];

// Test 3: Customers list
ob_start();
$req = new Request('GET', '/api/v1/customers', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Customers list returns envelope', ($data['code'] ?? '') === 'CUSTOMERS_RETRIEVED');

// Test 4: Catalog Services list
ob_start();
$req = new Request('GET', '/api/v1/services', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Catalog services list returns envelope', ($data['code'] ?? '') === 'SERVICES_RETRIEVED');

// Test 5: Sales Orders list
ob_start();
$req = new Request('GET', '/api/v1/sales', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Sales orders list returns envelope', ($data['code'] ?? '') === 'ORDERS_RETRIEVED');

// Test 6: Invoices list
ob_start();
$req = new Request('GET', '/api/v1/invoices', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Invoices list returns envelope', ($data['code'] ?? '') === 'INVOICES_RETRIEVED');

// Test 7: Delivery tasks list
ob_start();
$req = new Request('GET', '/api/v1/delivery-tasks', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Delivery tasks list returns envelope', ($data['code'] ?? '') === 'DELIVERY_TASKS_RETRIEVED');

// Test 8: Challans list
ob_start();
$req = new Request('GET', '/api/v1/challans', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Challans list returns envelope', ($data['code'] ?? '') === 'CHALLANS_RETRIEVED');

// Test 9: Inventory movements
ob_start();
$req = new Request('GET', '/api/v1/inventory/movements', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Inventory movements returns envelope', ($data['code'] ?? '') === 'MOVEMENTS_RETRIEVED');

// Test 10: Expense categories
ob_start();
$req = new Request('GET', '/api/v1/expense-categories', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Expense categories returns envelope', ($data['code'] ?? '') === 'EXPENSE_CATEGORIES_RETRIEVED');

// Test 11: Employees list
ob_start();
$req = new Request('GET', '/api/v1/employees', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Employees list returns envelope', ($data['code'] ?? '') === 'EMPLOYEES_RETRIEVED');

// Test 12: Reports dashboard KPIs
ob_start();
$req = new Request('GET', '/api/v1/reports/dashboard-kpis', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Reports dashboard KPIs returns AED currency', ($data['data']['currency'] ?? '') === 'AED');

// Test 13: License status
ob_start();
$req = new Request('GET', '/api/v1/license/status', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('License status returns valid status', ($data['data']['is_valid'] ?? false) === true);

// Test 14: Sync status
ob_start();
$req = new Request('GET', '/api/v1/sync/status', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Sync status returns healthy', ($data['data']['is_healthy'] ?? false) === true);

// Test 15: Storefront catalog
ob_start();
$req = new Request('GET', '/api/v1/storefront/catalog', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Storefront catalog returns items', ($data['code'] ?? '') === 'STOREFRONT_CATALOG_RETRIEVED');

// Test 16: Localization profiles
ob_start();
$req = new Request('GET', '/api/v1/localization/profiles', $authHeader);
$router->dispatch($req);
$out = ob_get_clean();
$data = json_decode($out, true);
assertTest('Localization profiles returns UAE profile', isset($data['data'][0]['country_code']));

echo "\nSummary: $passed Passed | $failed Failed\n";
exit($failed === 0 ? 0 : 1);
