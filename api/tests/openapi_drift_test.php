<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Core\RouteRegistry;
use LaundryPro\Api\Core\Router;

RouteRegistry::reset();
$router = new Router();
require API_ROOT . '/routes/api.php';
register_api_routes($router);

$registryCount = RouteRegistry::count();
$routerCount = $router->count();

if ($registryCount !== $routerCount) {
  fwrite(STDERR, "Route registry drift: registry={$registryCount} router={$routerCount}" . PHP_EOL);
  exit(1);
}

echo "Route registry OK ({$registryCount} routes)" . PHP_EOL;
exit(0);
