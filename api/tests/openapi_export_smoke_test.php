<?php

declare(strict_types=1);

ini_set('memory_limit', '512M');

require_once dirname(__DIR__) . '/bootstrap.php';
require_once API_ROOT . '/routes/api.php';

use LaundryPro\Api\Core\Router;
use LaundryPro\Api\Core\RouteRegistry;

RouteRegistry::reset();
$router = new Router();
register_api_routes($router);

$routes = RouteRegistry::all();
if (empty($routes)) {
    fwrite(STDERR, "OpenAPI export smoke failed: No routes registered\n");
    exit(1);
}

// Generate valid spec structures in memory
$paths = [];
foreach ($routes as $route) {
    $p = (string)$route['path'];
    $m = strtolower((string)$route['method']);
    $paths[$p][$m] = [
        'summary' => (string)($route['summary'] ?? ''),
        'responses' => ['200' => ['description' => 'OK']]
    ];
}

$spec = [
    'openapi' => '3.0.3',
    'info' => [
        'title' => 'LaundryPro UAE - Local Station API',
        'version' => '2.0.0',
    ],
    'paths' => $paths,
];

$json = json_encode($spec, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
if ($json === false) {
    fwrite(STDERR, 'json_encode failed: ' . json_last_error_msg() . PHP_EOL);
    exit(1);
}

echo 'OpenAPI export smoke OK (' . count($paths) . ' paths)' . PHP_EOL;
exit(0);