<?php

declare(strict_types=1);

use LaundryPro\Cloud\Controllers\AdminPortalController;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Core\Router;

function register_cloud_web_routes(Router $router): void
{
    // Super-Admin Web Portal Authentication
    $router->get('/admin/login', [AdminPortalController::class, 'loginView']);
    $router->post('/admin/login', [AdminPortalController::class, 'handleLogin']);
    $router->post('/admin/logout', [AdminPortalController::class, 'logout']);

    // Super-Admin Portal Views & Actions
    $router->get('/admin', [AdminPortalController::class, 'dashboard']);
    $router->get('/admin/tenants', [AdminPortalController::class, 'tenants']);
    $router->get('/admin/licenses', [AdminPortalController::class, 'licenses']);
    $router->post('/admin/licenses/issue', [AdminPortalController::class, 'issueLicense']);
    $router->post('/admin/licenses/revoke/{id}', [AdminPortalController::class, 'revokeLicense']);
    $router->get('/admin/sync', [AdminPortalController::class, 'syncInspector']);
    $router->get('/admin/audit', [AdminPortalController::class, 'audit']);

    // Default root redirect to admin portal
    $router->get('/', function (Request $req): void {
        Response::redirect('/admin');
    });
}
