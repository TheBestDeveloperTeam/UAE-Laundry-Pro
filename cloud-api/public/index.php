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

// Load root or local .env if present
Env::load(dirname(__DIR__) . '/.env');

use LaundryPro\Cloud\Controllers\AdminPortalController;
use LaundryPro\Cloud\Controllers\CloudApiController;
use LaundryPro\Cloud\Controllers\TenantApiController;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Core\Router;
use LaundryPro\Cloud\Middleware\CsrfMiddleware;
use LaundryPro\Cloud\Middleware\RateLimitMiddleware;

$request = new Request();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Business-Owner-Id, X-License-Key, X-Device-UMAC, X-CSRF-Token');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Security: Rate limiting on API routes
if (str_starts_with($request->path(), '/api/')) {
    if (!RateLimitMiddleware::handle($request, 120)) {
        exit;
    }
}

// Security: CSRF protection on portal state-modifying requests
if (str_starts_with($request->path(), '/admin') && in_array($request->method(), ['POST', 'PUT', 'DELETE'], true)) {
    if ($request->path() !== '/admin/login' && !CsrfMiddleware::validate($request)) {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        $_SESSION['flash_error'] = 'Security validation failed (invalid CSRF token). Please try again.';
        Response::redirect('/admin');
        exit;
    }
}

require_once dirname(__DIR__) . '/routes/api.php';

$router = new Router();

// Register Full Cloud API Routes (178 endpoints for 100% parity across all 35 operational domains)
register_cloud_api_routes($router);

// Super-Admin Web Portal Endpoints
$router->get('/admin/login', [AdminPortalController::class, 'loginView']);
$router->post('/admin/login', [AdminPortalController::class, 'handleLogin']);
$router->post('/admin/logout', [AdminPortalController::class, 'logout']);

$router->get('/admin', [AdminPortalController::class, 'dashboard']);
$router->get('/admin/tenants', [AdminPortalController::class, 'tenants']);
$router->get('/admin/licenses', [AdminPortalController::class, 'licenses']);
$router->post('/admin/licenses/issue', [AdminPortalController::class, 'issueLicense']);
$router->post('/admin/licenses/revoke/{id}', [AdminPortalController::class, 'revokeLicense']);
$router->get('/admin/sync', [AdminPortalController::class, 'syncInspector']);
$router->get('/admin/audit', [AdminPortalController::class, 'audit']);

// Default root redirect
$router->get('/', function (Request $req) {
    Response::redirect('/admin');
});

$router->dispatch($request);
