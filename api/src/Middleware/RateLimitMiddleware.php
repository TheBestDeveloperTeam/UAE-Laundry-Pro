<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;

final class RateLimitMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly int $maxAttempts = 5,
    private readonly int $decayMinutes = 1
  ) {
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
    $path = $request->path();
    
    // Only rate limit login endpoints
    if (!str_starts_with($path, '/auth/login')) {
      $next($request, $container);
      return;
    }

    $pdo = $container->get(\PDO::class);
    $key = 'rate_limit:' . hash('sha256', $ip . '|' . $path);

    $stmt = $pdo->prepare('SELECT setting_value FROM settings WHERE setting_key = :key');
    $stmt->execute(['key' => $key]);
    $row = $stmt->fetch();

    $now = time();
    $data = ['attempts' => 0, 'expires_at' => $now + ($this->decayMinutes * 60)];
    
    if ($row) {
      $decoded = json_decode((string) $row['setting_value'], true);
      if (is_array($decoded) && ($decoded['expires_at'] ?? 0) > $now) {
        $data = $decoded;
      }
    }

    $data['attempts']++;

    if ($data['attempts'] > $this->maxAttempts) {
      $container->get(ApiResponse::class)->error($request, 'TOO_MANY_REQUESTS', 'auth.rate_limit_exceeded', 429);
      return;
    }

    // Save state
    $stmt = $pdo->prepare('
      INSERT INTO settings (setting_key, setting_value, scope)
      VALUES (:key, :val, "system")
      ON DUPLICATE KEY UPDATE setting_value = :val
    ');
    $stmt->execute(['key' => $key, 'val' => json_encode($data)]);

    $next($request, $container);
  }
}
