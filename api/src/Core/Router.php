<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

use Closure;

final class Route
{
  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function __construct(
    public readonly string $method,
    public readonly string $pattern,
    public readonly array $handler,
    public readonly array $middleware = [],
    public readonly array $meta = [],
  ) {
  }
}

final class Router
{
  /** @var array<int, Route> */
  private array $routes = [];

  private string $basePath;

  public function __construct(string $basePath = '')
  {
    $this->basePath = rtrim($basePath, '/');
  }

  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function add(string $method, string $path, array $handler, array $middleware = [], array $meta = []): void
  {
    $this->routes[] = new Route(strtoupper($method), $path, $handler, $middleware, $meta);
    RouteRegistry::register($method, $path, $handler, $middleware, $meta);
  }

  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function get(string $path, array $handler, array $middleware = [], array $meta = []): void
  {
    $this->add('GET', $path, $handler, $middleware, $meta);
  }

  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function post(string $path, array $handler, array $middleware = [], array $meta = []): void
  {
    $this->add('POST', $path, $handler, $middleware, $meta);
  }

  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function put(string $path, array $handler, array $middleware = [], array $meta = []): void
  {
    $this->add('PUT', $path, $handler, $middleware, $meta);
  }

  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function patch(string $path, array $handler, array $middleware = [], array $meta = []): void
  {
    $this->add('PATCH', $path, $handler, $middleware, $meta);
  }

  /** @param array<int, class-string|Closure>> $middleware */
  /** @param array<string, mixed> $meta */
  public function delete(string $path, array $handler, array $middleware = [], array $meta = []): void
  {
    $this->add('DELETE', $path, $handler, $middleware, $meta);
  }

  public function count(): int
  {
    return count($this->routes);
  }

  public function match(Request $request): ?array
  {
    $path = $request->getPath();

    if ($this->basePath !== '' && str_starts_with($path, $this->basePath)) {
      $path = substr($path, strlen($this->basePath)) ?: '/';
    }

    foreach ($this->routes as $route) {
      if ($route->method !== $request->getMethod()) {
        continue;
      }

      $regex = $this->compilePattern($route->pattern);
      if (preg_match($regex, $path, $matches)) {
        $params = [];
        foreach ($matches as $key => $value) {
          if (!is_int($key)) {
            $params[$key] = $value;
          }
        }

        return [
          'handler' => $route->handler,
          'middleware' => $route->middleware,
          'params' => $params,
          'meta' => $route->meta,
        ];
      }
    }

    return null;
  }

  private function compilePattern(string $pattern): string
  {
    $regex = preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#', '(?P<$1>[^/]+)', $pattern);

    return '#^' . $regex . '$#';
  }
}
