<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

final class Env
{
  private static bool $loaded = false;

  /** @var array<string, string> */
  private static array $values = [];

  public static function load(string $path): void
  {
    if (self::$loaded) {
      return;
    }

    if (!is_file($path)) {
      self::$loaded = true;
      return;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($lines === false) {
      self::$loaded = true;
      return;
    }

    foreach ($lines as $line) {
      $line = trim($line);
      if ($line === '' || str_starts_with($line, '#')) {
        continue;
      }

      $parts = explode('=', $line, 2);
      if (count($parts) !== 2) {
        continue;
      }

      $key = trim($parts[0]);
      $value = trim($parts[1]);
      $value = trim($value, "\"'");

      self::$values[$key] = $value;
      $_ENV[$key] = $value;
      putenv($key . '=' . $value);
    }

    self::$loaded = true;
  }

  public static function get(string $key, ?string $default = null): ?string
  {
    return self::$values[$key] ?? $_ENV[$key] ?? getenv($key) ?: $default;
  }

  public static function bool(string $key, bool $default = false): bool
  {
    $value = self::get($key);
    if ($value === null) {
      return $default;
    }

    return filter_var($value, FILTER_VALIDATE_BOOLEAN);
  }
}
