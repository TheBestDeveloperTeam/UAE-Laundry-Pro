<?php

declare(strict_types=1);

use LaundryPro\Cloud\Core\Env;

return [
    'host' => Env::get('CLOUD_DB_HOST') ?: Env::get('DB_HOST', 'localhost'),
    'port' => (int) (Env::get('CLOUD_DB_PORT') ?: Env::get('DB_PORT', '3306')),
    'database' => Env::get('CLOUD_DB_NAME') ?: Env::get('DB_NAME', 'laundrypro'),
    'username' => Env::get('CLOUD_DB_USER') ?: Env::get('DB_USER', 'root'),
    'password' => Env::get('CLOUD_DB_PASS') ?? Env::get('DB_PASS', ''),
    'charset' => 'utf8mb4',
];
