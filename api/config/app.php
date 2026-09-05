<?php

declare(strict_types=1);

use LaundryPro\Api\Core\Env;

return [
    'env' => Env::get('APP_ENV', 'local'),
    'debug' => Env::bool('APP_DEBUG', false),
    'url' => Env::get('APP_URL', 'http://localhost/laundrypro-api'),
    'base_path' => Env::get('APP_BASE_PATH', ''),
    'version' => Env::get('APP_VERSION', '1.2.0'),
    'paths' => [
        'backup' => Env::get('BACKUP_PATH', 'C:/LaundryPro/backups/'),
        'invoice' => Env::get('INVOICE_PATH', 'C:/LaundryPro/invoices/'),
        'image' => Env::get('IMAGE_PATH', 'C:/LaundryPro/images/'),
        'log' => Env::get('LOG_PATH', 'C:/LaundryPro/logs/'),
        'export' => Env::get('EXPORT_PATH', 'C:/LaundryPro/exports/'),
    ],
    'cors_allowed_origins' => array_filter(array_map(
        'trim',
        explode(',', Env::get('CORS_ALLOWED_ORIGINS', 'http://localhost'))
    )),
];
