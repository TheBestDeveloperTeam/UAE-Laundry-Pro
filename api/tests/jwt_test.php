<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Security\JwtService;

$jwt = new JwtService('test_secret_key_for_unit_tests_only_123456', 3600, 7200);
$token = $jwt->createAccessToken(1, ['role' => 'administrator']);
$payload = $jwt->decode($token);

assert(($payload['sub'] ?? '') === '1', 'sub claim mismatch');
assert(($payload['type'] ?? '') === 'access', 'type claim mismatch');

echo "JWT service test passed.\n";
