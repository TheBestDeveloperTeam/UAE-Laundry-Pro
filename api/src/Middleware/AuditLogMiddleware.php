<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;

final class AuditLogMiddleware implements MiddlewareInterface
{
  public function handle(Request $request, Container $container, callable $next): void
  {
    $next($request);

    if (!in_array($request->getMethod(), ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
      return;
    }

    try {
      $audit = $container->get(\LaundryPro\Api\Repositories\AuditLogRepository::class);
      $userId = $container->has('auth.user_id') ? $container->get('auth.user_id') : null;
      $body = $request->all();
      // Sanitize sensitive credentials
      unset($body['password'], $body['token'], $body['secret']);
      $payload = [
        'request_id' => $request->getRequestId(),
        'body' => $body,
      ];
      $audit->log(
        $userId,
        $request->getMethod() . ' ' . $request->getPath(),
        'api_request',
        null,
        json_encode($payload, JSON_THROW_ON_ERROR)
      );
    } catch (\Throwable) {
      // Audit failures must not break API responses.
    }
  }
}
