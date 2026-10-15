<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/src/Core/Router.php';
require_once dirname(__DIR__) . '/routes/api.php';

$router = new LaundryPro\Cloud\Core\Router();
register_cloud_api_routes($router);

$ref = new ReflectionProperty($router, 'routes');
$ref->setAccessible(true);
/** @var list<array{method:string,pattern:string,handler:mixed}> $routes */
$routes = $ref->getValue($router);

$patterns = array_column($routes, 'pattern');
$required = [
    '/api/v1/health',
    '/api/v1/auth/login',
    '/api/v1/internal/deploy/apply',
    '/api/v1/internal/deploy/logs',
    '/api/v1/internal/deploy/status',
    '/api/v1/sync/push',
    '/api/v1/sync/pull',
];

$missing = [];
foreach ($required as $path) {
    if (!in_array($path, $patterns, true)) {
        $missing[] = $path;
    }
}

if ($missing !== []) {
    fwrite(STDERR, 'Missing required cloud routes: ' . implode(', ', $missing) . PHP_EOL);
    exit(1);
}

$openapiPath = dirname(__DIR__) . '/docs/openapi.json';
if (!is_file($openapiPath)) {
    fwrite(STDERR, "Missing cloud OpenAPI: {$openapiPath}\n");
    exit(1);
}

$spec = json_decode((string) file_get_contents($openapiPath), true);
$pathCount = is_array($spec['paths'] ?? null) ? count($spec['paths']) : 0;
if ($pathCount < 100) {
    fwrite(STDERR, "Cloud OpenAPI path count too low: {$pathCount}\n");
    exit(1);
}

foreach (['/api/v1/internal/deploy/apply', '/api/v1/internal/deploy/status'] as $deployPath) {
    if (!isset($spec['paths'][$deployPath])) {
        fwrite(STDERR, "OpenAPI missing deploy path: {$deployPath}\n");
        exit(1);
    }
}

echo 'Cloud route registry OK (' . count($routes) . ' routes, ' . $pathCount . " OpenAPI paths)\n";
exit(0);
