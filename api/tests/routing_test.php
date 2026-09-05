<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Core\RequestPathResolver;

function assertPath(string $input, string $expected, array $server = [], string $appBasePath = ''): void
{
  $resolved = RequestPathResolver::resolve($input, $appBasePath, $server);
  if ($resolved !== $expected) {
    fwrite(
      STDERR,
      "Expected '{$expected}' but got '{$resolved}' for input '{$input}'\n"
    );
    exit(1);
  }
}

assertPath(
  '/laundrypro-api/public/api/v1/health',
  '/api/v1/health',
  ['SCRIPT_NAME' => '/laundrypro-api/public/index.php']
);

assertPath(
  '/laundrypro-api/api/v1/health',
  '/api/v1/health',
  ['SCRIPT_NAME' => '/laundrypro-api/index.php'],
  '/laundrypro-api'
);

assertPath(
  '/api/v1/health',
  '/api/v1/health',
  ['SCRIPT_NAME' => '/index.php']
);

assertPath(
  '/laundrypro-api/public/index.php/api/v1/health',
  '/api/v1/health',
  ['SCRIPT_NAME' => '/laundrypro-api/public/index.php']
);

assertPath(
  '/api/v1/auth/login',
  '/api/v1/auth/login',
  [],
  '/laundrypro-api/public'
);

assertPath(
  '/laundrypro-api/public/api/v1/health',
  '/api/v1/health',
  ['PATH_INFO' => '/api/v1/health']
);

echo "Routing test passed.\n";
