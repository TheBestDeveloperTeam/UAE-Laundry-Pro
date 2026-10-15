<?php

declare(strict_types=1);

/**
 * HTTP fallback apply when internal API routes are not deployed yet.
 * Lives at docroot/lp_deploy_apply.php or cloud-api/public/lp_deploy_apply.php
 * Header: X-LaundryPro-Deploy-Token (must match DEPLOY_AUTOMATION_TOKEN in cloud-api/.env)
 */

header('Content-Type: application/json; charset=utf-8');

$cloudApi = is_dir(__DIR__ . '/cloud-api')
    ? __DIR__ . '/cloud-api'
    : dirname(__DIR__);
$deployRoot = dirname($cloudApi);

$envFile = is_file($cloudApi . '/.env') ? $cloudApi . '/.env' : $cloudApi . '/.env.production';

$expected = '';
if (is_file($envFile)) {
    foreach (file($envFile, FILE_IGNORE_NEW_LINES) ?: [] as $line) {
        $line = trim($line);
        if (str_starts_with($line, 'DEPLOY_AUTOMATION_TOKEN=')) {
            $expected = trim(substr($line, strlen('DEPLOY_AUTOMATION_TOKEN=')), " \t\"'");
            break;
        }
    }
}

$token = $_SERVER['HTTP_X_LAUNDRYPRO_DEPLOY_TOKEN'] ?? '';
if ($token === '' && isset($_SERVER['HTTP_AUTHORIZATION']) && str_starts_with($_SERVER['HTTP_AUTHORIZATION'], 'Bearer ')) {
    $token = trim(substr($_SERVER['HTTP_AUTHORIZATION'], 7));
}

if ($expected === '' || $token === '' || !hash_equals($expected, $token)) {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'code' => 'UNAUTHORIZED',
        'message' => $expected === '' ? 'Set DEPLOY_AUTOMATION_TOKEN in cloud-api/.env' : 'Invalid or missing token',
    ]);
    exit;
}

$package = 'deploy_staging/cloud-cpanel-upload.zip';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw = file_get_contents('php://input') ?: '';
    $json = json_decode($raw, true);
    if (is_array($json) && isset($json['package'])) {
        $package = (string) $json['package'];
    }
}

require_once $cloudApi . '/scripts/automation/ReleaseAutomation.php';
$engine = new ReleaseAutomation($cloudApi . '/scripts/automation');
$result = $engine->applyPackage($deployRoot, $package);

http_response_code($result['exitCode'] === 0 ? 200 : 500);
echo json_encode([
    'success' => $result['exitCode'] === 0,
    'code' => $result['exitCode'] === 0 ? 'HTTP_APPLY_OK' : 'HTTP_APPLY_FAILED',
    'data' => ['exit_code' => $result['exitCode'], 'output' => mb_substr($result['output'], 0, 120000)],
], JSON_UNESCAPED_SLASHES);
