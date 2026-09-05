<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Repositories\SyncOutboxRepository;
use LaundryPro\Api\Services\SyncService;

$config = require API_ROOT . '/config/database.php';
$pdo = PdoFactory::create($config);
$sync = new SyncService($pdo, new SyncOutboxRepository($pdo));
$status = $sync->status();

if (!($status['enabled'] ?? false)) {
  echo "Sync disabled.\n";
  exit(0);
}

$result = $sync->push();
echo 'Pushed: ' . ($result['pushed'] ?? 0) . PHP_EOL;
exit(0);
