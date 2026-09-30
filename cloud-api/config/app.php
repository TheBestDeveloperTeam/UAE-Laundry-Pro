<?php

declare(strict_types=1);

use LaundryPro\Cloud\Core\Env;

return [
    'app_name' => 'LaundryPro UAE Cloud Super-Admin',
    'app_env' => Env::get('CLOUD_APP_ENV') ?: Env::get('APP_ENV', 'production'),
    'app_url' => Env::get('CLOUD_APP_URL') ?: Env::get('APP_URL', 'https://laundrypro-cloudapi.magnificentsolution.co.in'),
    'version' => '1.2.0',
    'license_master_secret' => Env::get('LICENSE_MASTER_SECRET', 'LP_CLOUD_MASTER_SIGNING_SECRET_KEY_2026_UAE_SECURITY_LAYER'),
    'session_name' => 'LP_CLOUD_SESS',
    'session_lifetime' => 28800, // 8 hours
];
