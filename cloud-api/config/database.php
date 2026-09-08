<?php

declare(strict_types=1);

return [
    'host' => getenv('CLOUD_DB_HOST') ?: 'localhost',
    'port' => (int) (getenv('CLOUD_DB_PORT') ?: 3306),
    'database' => getenv('CLOUD_DB_NAME') ?: 'laundrypro_cloud',
    'username' => getenv('CLOUD_DB_USER') ?: 'root',
    'password' => getenv('CLOUD_DB_PASS') !== false ? getenv('CLOUD_DB_PASS') : '',
    'charset' => 'utf8mb4',
];
