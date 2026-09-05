<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Middleware\AuditMiddleware;
use LaundryPro\Api\Middleware\AuthMiddleware;
use LaundryPro\Api\Middleware\CorsMiddleware;
use LaundryPro\Api\Middleware\MiddlewareInterface;
use LaundryPro\Api\Middleware\RateLimitMiddleware;

assert(interface_exists(MiddlewareInterface::class), 'MiddlewareInterface not found');
assert(class_exists(CorsMiddleware::class), 'CorsMiddleware not found');
assert(class_exists(AuthMiddleware::class), 'AuthMiddleware not found');
assert(class_exists(RateLimitMiddleware::class), 'RateLimitMiddleware not found');
assert(class_exists(AuditMiddleware::class), 'AuditMiddleware not found');

echo "Autoload test passed.\n";
