<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

use Closure;
use PDO;

final class Container
{
  /** @var array<string, mixed> */
  private array $bindings = [];

  /** @var array<string, mixed> */
  private array $instances = [];

  public function set(string $id, mixed $value): void
  {
    $this->bindings[$id] = $value;
  }

  public function singleton(string $id, Closure $factory): void
  {
    $this->bindings[$id] = static function (Container $container) use ($factory) {
      static $instance;
      if ($instance === null) {
        $instance = $factory($container);
      }

      return $instance;
    };
  }

  public function get(string $id): mixed
  {
    if (array_key_exists($id, $this->instances)) {
      return $this->instances[$id];
    }

    if (!array_key_exists($id, $this->bindings)) {
      throw new \RuntimeException("Service not found: {$id}");
    }

    $binding = $this->bindings[$id];
    $resolved = $binding instanceof Closure ? $binding($this) : $binding;
    $this->instances[$id] = $resolved;

    return $resolved;
  }

  public function has(string $id): bool
  {
    return array_key_exists($id, $this->bindings) || array_key_exists($id, $this->instances);
  }

  public function pdo(): PDO
  {
    return $this->get(PDO::class);
  }
}
