<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;

final class CorsMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly array $allowedOrigins,
  ) {
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $origin = $request->header('Origin');
    $allowed = false;

    if ($origin !== null) {
      if (in_array($origin, $this->allowedOrigins, true) ||
          in_array('*', $this->allowedOrigins, true) ||
          preg_match('#^https?://(localhost|127\.0\.0\.1|192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?$#', $origin)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Access-Control-Allow-Credentials: true');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Install-Token, X-Business-Owner-Id, X-License-Key, X-Device-UMAC');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $allowed = true;
      }
    } else {
      header('Access-Control-Allow-Origin: *');
      header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Install-Token, X-Business-Owner-Id, X-License-Key, X-Device-UMAC');
      header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    }

    if ($request->getMethod() === 'OPTIONS') {
      http_response_code(204);
      return;
    }

    $next($request);
  }
}
