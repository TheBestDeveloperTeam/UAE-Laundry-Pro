<?php

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/bootstrap.php';

use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Security\PasswordHasher;

$config = require API_ROOT . '/config/database.php';
$pdo = PdoFactory::create($config);
$hasher = new PasswordHasher();

$sql = file_get_contents(API_ROOT . '/database/seeds/002_dev_users.sql');
if ($sql !== false) {
  $pdo->exec($sql);
}

$hash = $hasher->hash('cashier123');
$stmt = $pdo->prepare('UPDATE users SET password_hash = :hash WHERE username = :username');
$stmt->execute(['hash' => $hash, 'username' => 'cashier']);

echo "Cashier user ready: cashier / cashier123\n";
