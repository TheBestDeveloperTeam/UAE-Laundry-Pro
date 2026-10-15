<?php

declare(strict_types=1);

ini_set('memory_limit', '512M');

require_once dirname(__DIR__) . '/bootstrap.php';
require_once API_ROOT . '/routes/api.php';

use LaundryPro\Api\Core\Router;
use LaundryPro\Api\Core\RouteRegistry;
use LaundryPro\Api\Docs\OpenApiGenerator;

RouteRegistry::reset();
$router = new Router();
register_api_routes($router);

$spec = (new OpenApiGenerator(
    'LaundryPro UAE - Local Station API',
    '2.0.0',
    'http://127.0.0.1:8080'
))->generate();

$flags = JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES;
if (defined('JSON_INVALID_UTF8_SUBSTITUTE')) {
    $flags |= JSON_INVALID_UTF8_SUBSTITUTE;
}

$json = json_encode($spec, $flags);
if ($json === false) {
    fwrite(STDERR, 'json_encode failed: ' . json_last_error_msg() . PHP_EOL);
    exit(1);
}

$outDir = getenv('RUNNER_TEMP') ?: sys_get_temp_dir();
$outFile = rtrim($outDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . 'laundrypro-openapi-smoke.json';
if (file_put_contents($outFile, $json) === false) {
    fwrite(STDERR, 'Cannot write smoke output: ' . $outFile . PHP_EOL);
    exit(1);
}

echo 'OpenAPI export smoke OK (' . count($spec['paths']) . ' paths)' . PHP_EOL;
exit(0);
