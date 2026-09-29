<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Services\SyncService;

final class SyncController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly SyncService $sync,
  ) {
  }

  public function status(Request $request, Container $container): void
  {
    $this->response->success($request, $this->sync->status(), 'SYNC_STATUS', 'sync.status_success');
  }

  public function push(Request $request, Container $container): void
  {
    $result = $this->sync->push();
    $this->response->success($request, $result, 'SYNC_PUSHED', 'sync.push_success');
  }

  public function pull(Request $request, Container $container): void
  {
    $since = $request->query('since');
    $result = $this->sync->pull(is_string($since) ? $since : null);
    $this->response->success($request, $result, 'SYNC_PULLED', 'sync.pull_success');
  }

  public function configure(Request $request, Container $container): void
  {
    $this->sync->updateConfig($request->all());
    $this->response->success($request, $this->sync->status(), 'SYNC_CONFIGURED', 'sync.configured');
  }

  public function entities(Request $request, Container $container): void
  {
    $this->response->success($request, ['entity_types' => $this->sync->listEntityTypes()], 'SYNC_ENTITIES', 'sync.entities');
  }
}
