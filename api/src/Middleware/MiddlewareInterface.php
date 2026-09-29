<?php

declare(strict_types=1);

namespace LaundryPro\Api\Middleware;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;

interface MiddlewareInterface
{
  public function handle(Request $request, Container $container, callable $next): void;
}
