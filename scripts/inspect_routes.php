<?php

require_once __DIR__ . '/../api/bootstrap.php';
require_once __DIR__ . '/../api/routes/api.php';

use LaundryPro\Api\Core\Router;
use LaundryPro\Api\Core\RouteRegistry;

$router = new Router();
register_api_routes($router);

echo "Total registered routes: " . RouteRegistry::count() . PHP_EOL;

$tags = [];
foreach (RouteRegistry::all() as $entry) {
    $tag = $entry['tag'] ?? 'Untagged';
    if (!isset($tags[$tag])) {
        $tags[$tag] = [];
    }
    $tags[$tag][] = $entry['method'] . ' ' . $entry['path'];
}

ksort($tags);
foreach ($tags as $tag => $routes) {
    echo "=== {$tag} (" . count($routes) . ") ===\n";
    foreach ($routes as $route) {
        echo "  " . $route . "\n";
    }
}
