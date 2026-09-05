<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Repositories\BusinessRepository;

final class BusinessController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly BusinessRepository $business,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function show(Request $request, Container $container): void
  {
    $profile = $this->business->getProfile();
    if ($profile === null) {
      $this->response->error($request, 'NOT_FOUND', 'business.not_found', 404);
      return;
    }

    $this->response->success($request, ['business' => $profile], 'BUSINESS_PROFILE', 'business.profile_success');
  }

  public function update(Request $request, Container $container): void
  {
    $profile = $this->business->updateProfile($request->all());
    if ($profile === null) {
      $this->response->error($request, 'NOT_FOUND', 'business.not_found', 404);
      return;
    }

    $userId = (int) $container->get('auth.user_id');
    $this->audit->log($userId, 'business.update', 'business', (int) $profile['id'], null);
    $this->response->success($request, ['business' => $profile], 'BUSINESS_UPDATED', 'business.update_success');
  }
}
