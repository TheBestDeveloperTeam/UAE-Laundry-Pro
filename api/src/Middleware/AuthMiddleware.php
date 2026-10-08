<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Security\JwtService;

final class AuthMiddleware implements MiddlewareInterface
{
  public function handle(Request $request, Container $container, callable $next): void
  {
    $token = $request->bearerToken();
    if ($token === null) {
      $container->get(ApiResponse::class)->error(
        $request,
        'AUTH_SESSION_EXPIRED',
        'auth.session_expired',
        401
      );
      return;
    }

    try {
      $jwt = $container->get(JwtService::class);
      $payload = $jwt->decode($token);
      if (($payload['type'] ?? '') !== 'access') {
        throw new \RuntimeException('Invalid token type.');
      }

      $container->set('auth.user_id', (int) $payload['sub']);
      $user = $container->get(\LaundryPro\Api\Repositories\UserRepository::class)->findById((int) $payload['sub']);
      if ($user !== null) {
        $perms = json_decode((string) ($user['permissions'] ?? '[]'), true);
        $container->set('auth.permissions', is_array($perms) ? $perms : []);
        $container->set('auth.role', (string) ($user['role_name'] ?? ''));
      }
    } catch (\Throwable) {
      $container->get(ApiResponse::class)->error(
        $request,
        'AUTH_SESSION_EXPIRED',
        'auth.session_expired',
        401
      );
      return;
    }

    $next($request);
  }
}
