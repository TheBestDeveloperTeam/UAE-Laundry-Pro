<?php

declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/bootstrap.php';

use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Security\PasswordHasher;
use LaundryPro\Api\Services\SeedService;

$config = require API_ROOT . '/config/database.php';
$pdo = PdoFactory::create($config);
$hasher = new PasswordHasher();

$adminPassword = $argv[1] ?? 'admin123';
$service = new SeedService($pdo, API_ROOT . '/database/seeds', $hasher);
$result = $service->run($adminPassword);

echo 'Seed files: ' . implode(', ', $result['seed_files'] ?? []) . PHP_EOL;
echo "Default admin: admin / {$adminPassword}" . PHP_EOL;
echo 'Default cashier: cashier / cashier123' . PHP_EOL;
