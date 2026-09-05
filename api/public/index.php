<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

$docsRoot = __DIR__ . '/docs';
$requestUri = (string) ($_SERVER['REQUEST_URI'] ?? '');
$path = parse_url($requestUri, PHP_URL_PATH);
if (is_string($path) && str_contains($path, '/docs')) {
  $docsPos = strpos($path, '/docs');
  $relative = substr($path, $docsPos + strlen('/docs'));
  $relative = $relative === '' || $relative === '/' ? '/index.html' : $relative;
  $candidate = $docsRoot . str_replace('/', DIRECTORY_SEPARATOR, $relative);
  $realDocs = realpath($docsRoot);
  $realFile = realpath($candidate);
  if ($realDocs !== false && $realFile !== false && str_starts_with($realFile, $realDocs) && is_file($realFile)) {
  $ext = strtolower(pathinfo($realFile, PATHINFO_EXTENSION));
  $types = [
    'html' => 'text/html; charset=utf-8',
    'css' => 'text/css; charset=utf-8',
    'js' => 'application/javascript; charset=utf-8',
    'json' => 'application/json; charset=utf-8',
    'png' => 'image/png',
    'svg' => 'image/svg+xml',
  ];
  header('Content-Type: ' . ($types[$ext] ?? 'application/octet-stream'));
  readfile($realFile);
  exit;
  }
}

use LaundryPro\Api\Core\Application;

$app = Application::create();
$app->run();
