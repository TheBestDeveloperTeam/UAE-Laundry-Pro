<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Repositories\RefreshTokenRepository;
use LaundryPro\Api\Repositories\UserRepository;
use LaundryPro\Api\Security\JwtService;
use LaundryPro\Api\Security\PasswordHasher;

final class AuthService
{
  public function __construct(
    private readonly UserRepository $users,
    private readonly RefreshTokenRepository $refreshTokens,
    private readonly JwtService $jwt,
    private readonly PasswordHasher $hasher,
    private readonly int $accessTtl,
    private readonly int $refreshTtl,
  ) {
  }

  /** @return array<string, mixed> */
  public function login(string $username, string $password): array
  {
    $user = $this->users->findByUsername($username);
    if ($user === null || !$this->hasher->verify($password, $user['password_hash'])) {
      throw new \RuntimeException('AUTH_INVALID_CREDENTIALS');
    }

    $userId = (int) $user['id'];
    $accessToken = $this->jwt->createAccessToken($userId, ['role' => $user['role_name']]);
    $refreshToken = $this->jwt->createRefreshToken($userId);
    $refreshHash = $this->jwt->hashToken($refreshToken);
    $expiresAt = gmdate('Y-m-d H:i:s', time() + $this->refreshTtl);

    $this->refreshTokens->store($userId, $refreshHash, $expiresAt);
    $this->users->updateLastLogin($userId);

    return [
      'access_token' => $accessToken,
      'refresh_token' => $refreshToken,
      'token_type' => 'Bearer',
      'expires_in' => $this->accessTtl,
      'user' => $this->formatUser($user),
    ];
  }

  /** @return array<string, mixed> */
  public function refresh(string $refreshToken): array
  {
    $payload = $this->jwt->decode($refreshToken);
    if (($payload['type'] ?? '') !== 'refresh') {
      throw new \RuntimeException('AUTH_SESSION_EXPIRED');
    }

    $hash = $this->jwt->hashToken($refreshToken);
    $stored = $this->refreshTokens->findValid($hash);
    if ($stored === null) {
      throw new \RuntimeException('AUTH_SESSION_EXPIRED');
    }

    $userId = (int) $payload['sub'];
    $user = $this->users->findById($userId);
    if ($user === null) {
      throw new \RuntimeException('AUTH_SESSION_EXPIRED');
    }

    $this->refreshTokens->revoke($hash);

    $accessToken = $this->jwt->createAccessToken($userId, ['role' => $user['role_name']]);
    $newRefreshToken = $this->jwt->createRefreshToken($userId);
    $newHash = $this->jwt->hashToken($newRefreshToken);
    $expiresAt = gmdate('Y-m-d H:i:s', time() + $this->refreshTtl);
    $this->refreshTokens->store($userId, $newHash, $expiresAt);

    return [
      'access_token' => $accessToken,
      'refresh_token' => $newRefreshToken,
      'token_type' => 'Bearer',
      'expires_in' => $this->accessTtl,
    ];
  }

  public function logout(string $refreshToken): void
  {
    $hash = $this->jwt->hashToken($refreshToken);
    $this->refreshTokens->revoke($hash);
  }

  /** @return array<string, mixed> */
  public function me(int $userId): array
  {
    $user = $this->users->findById($userId);
    if ($user === null) {
      throw new \RuntimeException('AUTH_SESSION_EXPIRED');
    }

    return $this->formatUser($user);
  }

  /** @param array<string, mixed> $user */
  private function formatUser(array $user): array
  {
    $permissions = json_decode($user['permissions'] ?? '[]', true);
    if (!is_array($permissions)) {
      $permissions = [];
    }

    return [
      'id' => (int) $user['id'],
      'uuid' => $user['uuid'],
      'username' => $user['username'],
      'full_name' => $user['full_name'],
      'email' => $user['email'],
      'role' => $user['role_name'],
      'permissions' => $permissions,
    ];
  }
}
