<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

final class RequestPathResolver
{
  /**
   * @param array<string, mixed> $server
   */
  public static function resolve(string $path, string $appBasePath = '', array $server = []): string
  {
    $server = $server !== [] ? $server : $_SERVER;

    $pathInfo = $server['PATH_INFO'] ?? '';
    if (is_string($pathInfo) && $pathInfo !== '') {
      return self::normalize($pathInfo);
    }

    $path = self::normalize($path);

    $scriptName = $server['SCRIPT_NAME'] ?? '';
    if (is_string($scriptName) && $scriptName !== '') {
      $scriptDir = str_replace('\\', '/', dirname($scriptName));
      if ($scriptDir !== '/' && str_starts_with($path, $scriptDir)) {
        $path = substr($path, strlen($scriptDir)) ?: '/';
        $path = self::normalize($path);
      }
    }

    if (str_contains($path, '/index.php')) {
      $path = substr($path, strpos($path, '/index.php') + strlen('/index.php')) ?: '/';
      $path = self::normalize($path);
    }

    $configuredBase = trim($appBasePath);
    if ($configuredBase !== '') {
      $normalizedBase = self::normalize($configuredBase);
      if ($normalizedBase !== '/' && str_starts_with($path, $normalizedBase)) {
        $path = substr($path, strlen($normalizedBase)) ?: '/';
        $path = self::normalize($path);
      }
    }

    if (str_contains($path, '/api/v1')) {
      $path = substr($path, strpos($path, '/api/v1'));
      $path = self::normalize($path);
    }

    return $path === '' ? '/' : $path;
  }

  private static function normalize(string $path): string
  {
    if ($path === '') {
      return '/';
    }

    $path = str_replace('\\', '/', $path);
    $path = '/' . ltrim($path, '/');
    $path = preg_replace('#/+#', '/', $path) ?? $path;

    return $path;
  }
}
