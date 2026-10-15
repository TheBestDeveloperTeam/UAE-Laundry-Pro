<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;

/**
 * @deprecated Use AuditLogMiddleware. Kept for container/route compatibility.
 */
final class AuditMiddleware implements MiddlewareInterface
{
  private AuditLogMiddleware $delegate;

  public function __construct()
  {
    $this->delegate = new AuditLogMiddleware();
  }

  public function handle(Request $request, Container $container, callable $next): void
  {
    $this->delegate->handle($request, $container, $next);
  }
}
