<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Container;
use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Helpers\ApiResponse;
use LaundryPro\Api\Repositories\AuditLogRepository;
use LaundryPro\Api\Services\AuthService;

final class AuthController
{
  public function __construct(
    private readonly ApiResponse $response,
    private readonly AuthService $auth,
    private readonly AuditLogRepository $audit,
  ) {
  }

  public function login(Request $request, Container $container): void
  {
    $username = trim((string) $request->input('username', ''));
    $password = (string) $request->input('password', '');

    if ($username === '' || $password === '') {
      $this->response->error(
        $request,
        'VALIDATION_ERROR',
        'auth.validation_failed',
        422,
        [
          ['field' => 'username', 'code' => 'REQUIRED', 'message_key' => 'auth.username_required'],
          ['field' => 'password', 'code' => 'REQUIRED', 'message_key' => 'auth.password_required'],
        ]
      );
      return;
    }

    try {
      $data = $this->auth->login($username, $password);
      $this->audit->log((int) $data['user']['id'], 'auth.login', 'user', (int) $data['user']['id']);
      $this->response->success($request, $data, 'AUTH_LOGIN_SUCCESS', 'auth.login_success');
    } catch (\RuntimeException $e) {
      $code = $e->getMessage();
      if ($code === 'AUTH_INVALID_CREDENTIALS') {
        $this->response->error($request, $code, 'auth.invalid_credentials', 401);
        return;
      }

      $this->response->error($request, 'AUTH_SESSION_EXPIRED', 'auth.session_expired', 401);
    }
  }

  public function refresh(Request $request, Container $container): void
  {
    $refreshToken = (string) $request->input('refresh_token', '');
    if ($refreshToken === '') {
      $this->response->error($request, 'VALIDATION_ERROR', 'auth.validation_failed', 422);
      return;
    }

    try {
      $data = $this->auth->refresh($refreshToken);
      $this->response->success($request, $data, 'AUTH_REFRESH_SUCCESS', 'auth.refresh_success');
    } catch (\Throwable) {
      $this->response->error($request, 'AUTH_SESSION_EXPIRED', 'auth.session_expired', 401);
    }
  }

  public function logout(Request $request, Container $container): void
  {
    $refreshToken = (string) $request->input('refresh_token', '');
    if ($refreshToken !== '') {
      $this->auth->logout($refreshToken);
    }

    $userId = $container->has('auth.user_id') ? (int) $container->get('auth.user_id') : null;
    $this->audit->log($userId, 'auth.logout', 'user', $userId);
    $this->response->success($request, null, 'AUTH_LOGOUT_SUCCESS', 'auth.logout_success');
  }

  public function me(Request $request, Container $container): void
  {
    $userId = (int) $container->get('auth.user_id');

    try {
      $user = $this->auth->me($userId);
      $this->response->success($request, ['user' => $user], 'AUTH_ME_SUCCESS', 'auth.me_success');
    } catch (\Throwable) {
      $this->response->error($request, 'AUTH_SESSION_EXPIRED', 'auth.session_expired', 401);
    }
  }
}
