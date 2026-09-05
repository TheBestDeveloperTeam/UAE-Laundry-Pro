<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use PDO;

final class HealthController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly PDO $pdo,
    private readonly string $version,
    private readonly float $startTime,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $dbStatus = 'ok';

    try {
      $this->pdo->query('SELECT 1');
    } catch (\Throwable) {
      $dbStatus = 'error';
    }

    $this->response->success($request, [
      'status' => $dbStatus === 'ok' ? 'healthy' : 'degraded',
      'database' => $dbStatus,
      'version' => $this->version,
      'uptime_seconds' => (int) (microtime(true) - $this->startTime),
    ], 'HEALTH_OK', 'health.ok');
  }
}
