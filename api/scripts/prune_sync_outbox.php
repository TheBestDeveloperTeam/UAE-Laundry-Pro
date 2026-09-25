<?php
/**
 * Prune synced records from sync_outbox older than 30 days.
 * Run this via cron (e.g. daily).
 */

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use LaundryPro\Api\Core\Database;
use LaundryPro\Api\Core\Config;

$config = Config::load();
$pdo = Database::connect($config['db']);

$stmt = $pdo->prepare("DELETE FROM sync_outbox WHERE status = 'synced' AND updated_at < DATE_SUB(NOW(), INTERVAL 30 DAY)");
$stmt->execute();

$deleted = $stmt->rowCount();
echo "Pruned {$deleted} synced records from sync_outbox older than 30 days.\n";
