<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Services\MigrationService;

$config = require API_ROOT . '/config/database.php';

try {
  $pdo = PdoFactory::create($config);
} catch (Throwable $e) {
  fwrite(STDERR, "Database connection failed: {$e->getMessage()}\n");
  exit(1);
}

$service = new MigrationService($pdo, API_ROOT . '/database/migrations');
$result = $service->runPending();

foreach ($result['executed'] as $migration) {
  echo "Applying {$migration}...\n";
}

echo "Migrations complete.\n";
