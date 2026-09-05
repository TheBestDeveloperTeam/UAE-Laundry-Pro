<?php

declare(strict_types=1);

define('API_ROOT', __DIR__);

require_once API_ROOT . '/src/Core/Autoloader.php';

use LaundryPro\Api\Core\Autoloader;
use LaundryPro\Api\Core\Env;

Autoloader::register(API_ROOT);

Env::load(API_ROOT . '/.env');

date_default_timezone_set('UTC');
