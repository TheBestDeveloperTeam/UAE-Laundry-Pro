<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Security\JwtService;

interface MiddlewareInterface
{
  public function handle(Request $request, Container $container, callable $next): void;
}

final class CorsMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly array $allowedOrigins,
  ) {
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $origin = $request->header('Origin');
    if ($origin !== null && in_array($origin, $this->allowedOrigins, true)) {
      header('Access-Control-Allow-Origin: ' . $origin);
      header('Access-Control-Allow-Credentials: true');
      header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Install-Token');
      header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    }

    if ($request->getMethod() === 'OPTIONS') {
      http_response_code(204);
      return;
    }

    $next($request);
  }
}

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

final class RateLimitMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly string $storagePath,
    private readonly int $maxAttempts,
    private readonly int $windowSeconds,
  ) {
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $key = hash('sha256', $request->ip() . ':' . $request->getPath());
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

    if ($data['count'] > $this->maxAttempts) {
      $container->get(ApiResponse::class)->error(
        $request,
        'RATE_LIMIT_EXCEEDED',
        'auth.rate_limit_exceeded',
        429
      );
      return;
    }

    $next($request);
  }
}

final class AuditMiddleware implements MiddlewareInterface
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
      $audit->log(
        $userId,
        $request->getMethod() . ' ' . $request->getPath(),
        'api_request',
        null,
        json_encode(['request_id' => $request->getRequestId()], JSON_THROW_ON_ERROR)
      );
    } catch (\Throwable) {
      // Audit failures must not break API responses.
    }
  }
}

final class InstallTokenMiddleware implements MiddlewareInterface
{
  public function handle(Request $request, Container $container, callable $next): void
  {
    $install = $container->get(\LaundryPro\Api\Services\InstallService::class);

    if ($install->isLocked()) {
      $container->get(ApiResponse::class)->error($request, 'INSTALL_LOCKED', 'install.locked', 403);
      return;
    }

    $token = $request->header('X-Install-Token');
    if (!$install->validateToken($token)) {
      $container->get(ApiResponse::class)->error($request, 'INSTALL_UNAUTHORIZED', 'install.unauthorized', 401);
      return;
    }

    $next($request);
  }
}

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

final class PermissionMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly \LaundryPro\Api\Security\PermissionChecker $checker,
  ) {
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $meta = $container->has('route.meta') ? $container->get('route.meta') : [];
    $required = is_array($meta) ? ($meta['permission'] ?? null) : null;

    if ($required === null || $required === '') {
      $next($request);
      return;
    }

    $permissions = $container->has('auth.permissions') ? $container->get('auth.permissions') : [];
    if (!is_array($permissions) || !$this->checker->has($permissions, (string) $required)) {
      $container->get(ApiResponse::class)->error($request, 'FORBIDDEN', 'auth.forbidden', 403);
      return;
    }

    $next($request);
  }
}
