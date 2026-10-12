<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Core\Env;
use LaundryPro\Api\Services\BackupService;

$backupDir = rtrim((string) Env::get('BACKUP_PATH', 'C:/LaundryPro/backups/'), '/\\');
$service = new BackupService(
  $backupDir,
  (string) Env::get('DB_DATABASE', 'laundrypro'),
  (string) Env::get('DB_USERNAME', 'root'),
  (string) Env::get('DB_PASSWORD', ''),
  (string) Env::get('DB_HOST', 'localhost'),
);

try {
  $result = $service->run();
  echo 'Backup OK: ' . ($result['file'] ?? 'unknown') . PHP_EOL;
  exit(0);
} catch (Throwable $e) {
  fwrite(STDERR, 'Backup failed: ' . $e->getMessage() . PHP_EOL);
  exit(1);
}
