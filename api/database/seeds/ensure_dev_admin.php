<?php

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/bootstrap.php';

use LaundryPro\Api\Core\Env;
use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Security\PasswordHasher;

$config = require API_ROOT . '/config/database.php';
$pdo = PdoFactory::create($config);
$hasher = new PasswordHasher();

$password = $argv[1] ?? 'admin123';
$hash = $hasher->hash($password);

$stmt = $pdo->prepare('UPDATE users SET password_hash = :hash WHERE username = :username');
$stmt->execute(['hash' => $hash, 'username' => 'admin']);

echo "Admin password updated for user 'admin'.\n";
