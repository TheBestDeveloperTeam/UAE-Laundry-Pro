<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\SettingsRepository;

final class SettingsController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly SettingsRepository $settings,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function index(Request $request, Container $container): void
  {
    $this->response->success($request, [
      'settings' => $this->settings->all(),
    ], 'SETTINGS_LIST', 'settings.list_success');
  }

  public function update(Request $request, Container $container): void
  {
    $settings = $request->input('settings');
    if (!is_array($settings)) {
      $this->response->error($request, 'VALIDATION_ERROR', 'settings.validation_failed', 422);
      return;
    }

    $userId = (int) $container->get('auth.user_id');

    foreach ($settings as $key => $value) {
      if (!is_string($key)) {
        continue;
      }

      $scope = 'business';
      $settingValue = $value;
      if (is_array($value) && array_key_exists('value', $value)) {
        $settingValue = $value['value'];
        $scope = is_string($value['scope'] ?? null) ? $value['scope'] : 'business';
      }

      $this->settings->upsert($key, $settingValue, $scope);
    }

    $this->audit->log($userId, 'settings.update', 'settings', null, json_encode(array_keys($settings)));
    $this->response->success($request, [
      'settings' => $this->settings->all(),
    ], 'SETTINGS_UPDATED', 'settings.update_success');
  }
}
