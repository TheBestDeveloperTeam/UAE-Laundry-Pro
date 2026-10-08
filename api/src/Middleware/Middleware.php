<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

/**
 * Middleware loader / compatibility layer
 *
 * Discrete middleware classes have been decomposed into individual PSR-compliant files:
 * - CorsMiddleware.php
 * - AuthMiddleware.php
 * - AuditLogMiddleware.php
 * - IdempotencyMiddleware.php
 * - InstallTokenMiddleware.php
 * - InstallRateLimitMiddleware.php
 * - RateLimitMiddleware.php
 * - PermissionMiddleware.php
 */

require_once __DIR__ . '/MiddlewareInterface.php';
require_once __DIR__ . '/CorsMiddleware.php';
require_once __DIR__ . '/AuthMiddleware.php';
require_once __DIR__ . '/AuditLogMiddleware.php';
require_once __DIR__ . '/IdempotencyMiddleware.php';
require_once __DIR__ . '/InstallTokenMiddleware.php';
require_once __DIR__ . '/InstallRateLimitMiddleware.php';
require_once __DIR__ . '/RateLimitMiddleware.php';
require_once __DIR__ . '/PermissionMiddleware.php';
