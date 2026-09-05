<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Services\InstallService;

final class InstallController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly InstallService $install,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function status(Request $request, Container $container): void
  {
    $this->response->success($request, $this->install->status(), 'INSTALL_STATUS', 'install.status_success');
  }

  public function migrate(Request $request, Container $container): void
  {
    try {
      $result = $this->install->migrate();
      $this->audit->log(null, 'install.migrate', 'install', null, json_encode($result));
      $this->response->success($request, $result, 'INSTALL_MIGRATED', 'install.migrate_success');
    } catch (\RuntimeException $e) {
      $this->handleInstallError($request, $e);
    }
  }

  public function seed(Request $request, Container $container): void
  {
    try {
      $password = $request->input('admin_password');
      $result = $this->install->seed(is_string($password) ? $password : null);
      $this->audit->log(null, 'install.seed', 'install', null, json_encode(['admin_updated' => true]));
      $this->response->success($request, $result, 'INSTALL_SEEDED', 'install.seed_success');
    } catch (\RuntimeException $e) {
      $this->handleInstallError($request, $e);
    }
  }

  public function complete(Request $request, Container $container): void
  {
    try {
      $result = $this->install->complete();
      $this->audit->log(null, 'install.complete', 'install', null, json_encode($result));
      $this->response->success($request, $result, 'INSTALL_COMPLETE', 'install.complete_success');
    } catch (\RuntimeException $e) {
      $this->handleInstallError($request, $e);
    }
  }

  private function handleInstallError(Request $request, \RuntimeException $e): void
  {
    $code = $e->getMessage();
    if ($code === 'INSTALL_LOCKED') {
      $this->response->error($request, $code, 'install.locked', 403);
      return;
    }
    if ($code === 'MIGRATIONS_PENDING') {
      $this->response->error($request, $code, 'install.migrations_pending', 409);
      return;
    }

    $this->response->error($request, 'INSTALL_FAILED', 'install.failed', 500);
  }
}
