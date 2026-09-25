<?php
declare(strict_types=1);

require dirname(__DIR__) . '/src/Core/Database.php';

use LaundryPro\Cloud\Core\Database;

$pdo = Database::connect();
if ($pdo === null) {
    error_log("Prune Script: Database connection failed");
    exit(1);
}

// Prune sync records older than 30 days
$stmt = $pdo->prepare('DELETE FROM sync_records WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)');
$stmt->execute();
$deleted = $stmt->rowCount();

error_log("Prune Script: Pruned $deleted old sync records.");
echo "Pruned $deleted old sync records.\n";
