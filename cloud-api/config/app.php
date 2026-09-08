<?php

declare(strict_types=1);

return [
    'app_name' => 'LaundryPro UAE Cloud Super-Admin',
    'app_env' => getenv('CLOUD_APP_ENV') ?: 'production',
    'app_url' => getenv('CLOUD_APP_URL') ?: 'https://www.laundrypro-cloudapi.magnificentsolution.co.in',
    'version' => '1.2.0',
    'license_master_secret' => getenv('LICENSE_MASTER_SECRET') ?: 'LP_CLOUD_MASTER_SIGNING_SECRET_KEY_2026_UAE_SECURITY_LAYER',
    'session_name' => 'LP_CLOUD_SESS',
    'session_lifetime' => 28800, // 8 hours
];
