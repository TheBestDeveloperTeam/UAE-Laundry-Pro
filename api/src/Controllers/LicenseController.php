<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Services\BackupService;
use LaundryPro\Api\Services\LicenseService;

final class LicenseController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly LicenseService $license,
  ) {
  }

  public function status(Request $request, Container $container): void
  {
    $this->response->success($request, $this->license->status(), 'LICENSE_STATUS', 'license.status_success');
  }

  public function activate(Request $request, Container $container): void
  {
    $key = $request->input('license_key');
    if (!is_string($key) || trim($key) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'license.validation_failed', 422);
      return;
    }

    $result = $this->license->activate(trim($key));
    $this->response->success($request, $result, 'LICENSE_ACTIVATED', 'license.activated');
  }
}

final class BackupController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly BackupService $backup,
  ) {
  }

  public function run(Request $request, Container $container): void
  {
    try {
      $result = $this->backup->run();
      $this->response->success($request, $result, 'BACKUP_CREATED', 'backup.created');
    } catch (\RuntimeException) {
      $this->response->error($request, 'BACKUP_FAILED', 'backup.failed', 500);
    }
  }

  public function history(Request $request, Container $container): void
  {
    $this->response->success($request, ['backups' => $this->backup->history()], 'BACKUP_HISTORY', 'backup.history_success');
  }

  public function verify(Request $request, Container $container): void
  {
    try {
      $file = $request->input('file');
      $result = $this->backup->verify(is_string($file) ? $file : null);
      $this->response->success($request, $result, 'BACKUP_VERIFIED', 'backup.verified');
    } catch (\RuntimeException $e) {
      $code = $e->getMessage();
      $this->response->error($request, $code, 'backup.' . strtolower($code), $code === 'BACKUP_NOT_FOUND' ? 404 : 422);
    }
  }

  public function restoreValidate(Request $request, Container $container): void
  {
    try {
      $file = $request->input('file');
      $result = $this->backup->restoreValidate(is_string($file) ? $file : null);
      $this->response->success($request, $result, 'BACKUP_RESTORE_VALIDATED', 'backup.restore_validated');
    } catch (\RuntimeException $e) {
      $this->response->error($request, $e->getMessage(), 'backup.invalid', 422);
    }
  }

  public function restore(Request $request, Container $container): void
  {
    try {
      $file = $request->input('file');
      $confirm = (bool) $request->input('confirm');
      $result = $this->backup->restore(is_string($file) ? $file : null, $confirm);
      $this->response->success($request, $result, 'BACKUP_RESTORED', 'backup.restored');
    } catch (\RuntimeException $e) {
      $msg = $e->getMessage();
      if ($msg === 'CONFIRM_REQUIRED') {
        $this->response->error($request, 'CONFIRM_REQUIRED', 'backup.confirm_required', 422);
        return;
      }
      $this->response->error($request, 'RESTORE_FAILED', 'backup.restore_failed', 500);
    }
  }
}
