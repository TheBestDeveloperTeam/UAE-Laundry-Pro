<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;

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
