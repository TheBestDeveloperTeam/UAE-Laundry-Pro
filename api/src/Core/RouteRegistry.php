<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

final class RouteRegistry
{
  /** @var array<int, array<string, mixed>> */
  private static array $entries = [];

  /** @param array<string, mixed> $meta */
  public static function register(
    string $method,
    string $path,
    array $handler,
    array $middleware,
    array $meta,
  ): void {
    self::$entries[] = array_merge([
      'method' => strtoupper($method),
      'path' => $path,
      'handler' => $handler,
      'middleware' => $middleware,
    ], $meta);
  }

  /** @return array<int, array<string, mixed>> */
  public static function all(): array
  {
    return self::$entries;
  }

  public static function count(): int
  {
    return count(self::$entries);
  }

  public static function reset(): void
  {
    self::$entries = [];
  }
}
