<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\LocalizationRepository;

final class LocalizationController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly LocalizationRepository $localization,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function profiles(Request $request, Container $container): void
  {
    $items = $this->localization->listProfiles();
    $this->response->success($request, ['profiles' => $items], 'LOCALIZATION_PROFILES', 'localization.profiles');
  }

  public function setCountry(Request $request, Container $container): void
  {
    $code = $request->input('country_code');
    if (!is_string($code) || trim($code) === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'localization.code_required', 422);
      return;
    }
    $profile = $this->localization->setBusinessCountry($code);
    if ($profile === null) {
      $this->response->error($request, 'NOT_FOUND', 'localization.profile_not_found', 404);
      return;
    }
    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'localization.set_country', 'country_profile', (int) $profile['id'], null);
    $this->response->success($request, ['profile' => $profile], 'LOCALIZATION_UPDATED', 'localization.updated');
  }
}
