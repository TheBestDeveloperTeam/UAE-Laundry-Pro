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

use LaundryPro\Cloud\Controllers\AdminPortalController;
use LaundryPro\Cloud\Controllers\CloudApiController;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Core\Router;

$request = new Request();
$router = new Router();

// API Endpoints
$router->get('/api/v1/health', [CloudApiController::class, 'health']);
$router->post('/api/v1/businesses/register', [CloudApiController::class, 'registerBusiness']);
$router->post('/api/v1/sync/push', [CloudApiController::class, 'syncPush']);
$router->get('/api/v1/sync/pull', [CloudApiController::class, 'syncPull']);

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
