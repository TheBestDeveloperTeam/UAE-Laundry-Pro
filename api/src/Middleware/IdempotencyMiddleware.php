<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use PDO;

final class IdempotencyMiddleware implements MiddlewareInterface
{
  public function handle(Request $request, Container $container, callable $next): void
  {
    $key = $request->header('X-Idempotency-Key');
    if ($key === null || $key === '') {
      $next($request);
      return;
    }

    try {
      $pdo = $container->pdo();
      $stmt = $pdo->prepare('SELECT response_code, response_body FROM idempotency_keys WHERE id_key = ?');
      $stmt->execute([$key]);
      $existing = $stmt->fetch(PDO::FETCH_ASSOC);

      if ($existing !== false && !empty($existing['response_body'])) {
        http_response_code((int) $existing['response_code']);
        header('Content-Type: application/json; charset=utf-8');
        header('X-Idempotent-Replay: true');
        echo (string) $existing['response_body'];
        return;
      }
    } catch (\Throwable) {
      // Continue normal execution if cache lookup encounters an error
    }

    $next($request);
  }
}
