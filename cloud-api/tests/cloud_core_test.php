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

use LaundryPro\Cloud\Core\Env;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Core\Router;
use LaundryPro\Cloud\Middleware\CsrfMiddleware;
use LaundryPro\Cloud\Middleware\RateLimitMiddleware;

echo "=== Running Cloud API Core Unit Tests ===\n";

$pass = 0;
$fail = 0;

function assertTest(string $name, bool $condition, ?string $detail = null): void {
    global $pass, $fail;
    if ($condition) {
        echo "[PASS] $name\n";
        $pass++;
    } else {
        echo "[FAIL] $name" . ($detail ? " ($detail)" : "") . "\n";
        $fail++;
    }
}

// 1. Test CsrfMiddleware Token Generation
$token1 = CsrfMiddleware::getToken();
assertTest('CSRF token is generated and non-empty', !empty($token1) && strlen($token1) === 64);

$token2 = CsrfMiddleware::getToken();
assertTest('CSRF token persists across calls in same session', $token1 === $token2);

$fieldHtml = CsrfMiddleware::field();
assertTest('CSRF field generates valid HTML input', str_contains($fieldHtml, '<input type="hidden" name="_csrf_token" value="' . $token1 . '">'));

// 2. Test CsrfMiddleware Validation
$_POST['_csrf_token'] = $token1;
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['REQUEST_URI'] = '/admin/licenses/issue';
$reqValid = new Request();
assertTest('CSRF validation passes with correct token in body', CsrfMiddleware::validate($reqValid));

$_POST['_csrf_token'] = 'invalid_tampered_token_12345';
$reqInvalid = new Request();
assertTest('CSRF validation fails with tampered token', !CsrfMiddleware::validate($reqInvalid));

// 3. Test Router Route Registration and Regex Parameter Matching
$router = new Router();
$matchedParam = null;
$router->get('/test/users/{id}', function(Request $req, array $params) use (&$matchedParam) {
    $matchedParam = $params['id'] ?? null;
});

$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/test/users/42';
$reqRoute = new Request();
$router->dispatch($reqRoute);
assertTest('Router dispatches and extracts route parameters correctly', $matchedParam === '42');

// 4. Test RateLimitMiddleware Sliding Window
$_SERVER['REMOTE_ADDR'] = '192.168.100.50';
$_SERVER['REQUEST_URI'] = '/api/v1/test_rate';
$reqRate = new Request();
$underLimit = RateLimitMiddleware::handle($reqRate, 5);
assertTest('Rate limiter allows requests under threshold', $underLimit);
// 5. Test Bearer Token extraction in Request
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer test_token_xyz_999';
$reqBearer = new Request();
assertTest('Request correctly parses Bearer token', $reqBearer->bearerToken() === 'test_token_xyz_999');

// 6. Test TenantScopeMiddleware initial state
assertTest('TenantScopeMiddleware initializes with null tenant', \LaundryPro\Cloud\Middleware\TenantScopeMiddleware::getTenant() === null);
assertTest('TenantScopeMiddleware getTenantId returns 0 when unauthenticated', \LaundryPro\Cloud\Middleware\TenantScopeMiddleware::getTenantId() === 0);

// 7. Test Tenant Route Dispatching
$tenantRouteHit = false;
$router->get('/api/v1/tenant/customers', function(Request $req) use (&$tenantRouteHit) {
    $tenantRouteHit = true;
});
$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REQUEST_URI'] = '/api/v1/tenant/customers';
$router->dispatch(new Request());
assertTest('Router dispatches tenant route correctly', $tenantRouteHit === true);

echo "\nSummary: $pass Passed | $fail Failed\n";
exit($fail === 0 ? 0 : 1);
