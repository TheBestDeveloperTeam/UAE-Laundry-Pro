<?php

declare(strict_types=1);

use LaundryPro\Api\Core\Env;

return [
    'jwt_secret' => Env::get('JWT_SECRET', ''),
    'jwt_access_ttl' => (int) Env::get('JWT_ACCESS_TTL', '28800'),
    'jwt_refresh_ttl' => (int) Env::get('JWT_REFRESH_TTL', '2592000'),
    'install_secret' => Env::get('INSTALL_SECRET', ''),
    'login_rate_limit' => 100,
    'login_rate_window' => 60,
    'install_rate_limit' => 5,
    'install_rate_window' => 60,
];
