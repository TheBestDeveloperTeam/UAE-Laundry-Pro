<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Security\PermissionChecker;

final class PermissionMiddleware implements MiddlewareInterface
{
  public function __construct(
    private readonly PermissionChecker $checker,
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
