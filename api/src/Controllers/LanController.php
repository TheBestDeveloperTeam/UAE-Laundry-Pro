<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Core\Env;

final class LanController
{
  public function __construct(private readonly ApiResponse $response)
  {
  }

  public function status(Request $request, Container $container): void
  {
    $host = $_SERVER['SERVER_ADDR'] ?? '127.0.0.1';
    $port = (int) ($_SERVER['SERVER_PORT'] ?? 80);
    $basePath = (string) (Env::get('APP_URL') ?? 'http://localhost/laundrypro-api/public');
    $this->response->success($request, [
      'lan_node' => [
        'enabled' => true,
        'host' => $host,
        'port' => $port,
        'api_base' => rtrim($basePath, '/') . '/api/v1',
        'discovery' => 'mDNS stub — configure secondary nodes manually',
      ],
    ], 'LAN_NODE_STATUS', 'lan.status');
  }

  public function bind(Request $request, Container $container): void
  {
    $bindHost = $request->input('bind_host');
    $this->response->success($request, [
      'bind_host' => is_string($bindHost) ? $bindHost : '0.0.0.0',
      'message' => 'LAN bind config accepted — restart Apache to apply',
    ], 'LAN_NODE_CONFIGURED', 'lan.configured');
  }
}
