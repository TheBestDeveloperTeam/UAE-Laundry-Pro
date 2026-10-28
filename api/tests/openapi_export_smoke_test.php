<?php

declare(strict_types=1);

ini_set('memory_limit', '512M');

try {
    require_once dirname(__DIR__) . '/bootstrap.php';
    require_once API_ROOT . '/routes/api.php';

    // Call export_swagger directly in CI mode which is tested and handles runner paths
    putenv('LAUNDRYPRO_EXPORT_CI=1');
    require_once dirname(__DIR__, 2) . '/scripts/export_swagger.php';
} catch (\Throwable $e) {
    fwrite(STDERR, 'OpenAPI export smoke failed: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}