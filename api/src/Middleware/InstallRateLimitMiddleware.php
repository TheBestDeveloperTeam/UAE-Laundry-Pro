<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;

final class InstallRateLimitMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly string $storagePath,
    private readonly int $maxAttempts = 5,
    private readonly int $windowSeconds = 60,
  ) {
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $key = hash('sha256', $request->ip() . ':install:' . $request->getPath());
    $file = rtrim($this->storagePath, '/\\') . DIRECTORY_SEPARATOR . 'rate_' . $key . '.json';
    $now = time();
    $data = ['count' => 0, 'reset' => $now + $this->windowSeconds];

    if (is_file($file)) {
      $decoded = json_decode((string) file_get_contents($file), true);
      if (is_array($decoded)) {
        $data = $decoded;
      }
    }

    if ($now > ($data['reset'] ?? 0)) {
      $data = ['count' => 0, 'reset' => $now + $this->windowSeconds];
    }

    $data['count'] = ($data['count'] ?? 0) + 1;
    file_put_contents($file, json_encode($data));

    $next($request);
  }
}
