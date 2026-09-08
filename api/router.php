<?php
declare(strict_types=1);

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '');
$publicDir = __DIR__ . '/public';
$filePath = $publicDir . $uri;

if ($uri !== '/' && file_exists($filePath) && !is_dir($filePath)) {
    return false;
}

require $publicDir . '/index.php';
