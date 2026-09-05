<?php

declare(strict_types=1);

namespace LaundryPro\Api\Security;

use RuntimeException;

final class JwtService
{
  public function __construct(
    private readonly string $secret,
    private readonly int $accessTtl,
    private readonly int $refreshTtl,
  ) {
    if ($this->secret === '') {
      throw new RuntimeException('JWT_SECRET is not configured.');
    }
  }

  /** @param array<string, mixed> $claims */
  public function createAccessToken(int $userId, array $claims = []): string
  {
    return $this->encode(array_merge($claims, [
      'sub' => (string) $userId,
      'type' => 'access',
      'iat' => time(),
      'exp' => time() + $this->accessTtl,
    ]));
  }

  /** @param array<string, mixed> $claims */
  public function createRefreshToken(int $userId, array $claims = []): string
  {
    return $this->encode(array_merge($claims, [
      'sub' => (string) $userId,
      'type' => 'refresh',
      'jti' => bin2hex(random_bytes(16)),
      'iat' => time(),
      'exp' => time() + $this->refreshTtl,
    ]));
  }

  /** @return array<string, mixed> */
  public function decode(string $token): array
  {
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
      throw new RuntimeException('Invalid token format.');
    }

    [$headerB64, $payloadB64, $signatureB64] = $parts;
    $expected = $this->sign("{$headerB64}.{$payloadB64}");

    if (!hash_equals($expected, $signatureB64)) {
      throw new RuntimeException('Invalid token signature.');
    }

    $payloadJson = $this->base64UrlDecode($payloadB64);
    $payload = json_decode($payloadJson, true);
    if (!is_array($payload)) {
      throw new RuntimeException('Invalid token payload.');
    }

    if (isset($payload['exp']) && time() >= (int) $payload['exp']) {
      throw new RuntimeException('Token expired.');
    }

    return $payload;
  }

  public function hashToken(string $token): string
  {
    return hash('sha256', $token);
  }

  /** @param array<string, mixed> $payload */
  private function encode(array $payload): string
  {
    $header = $this->base64UrlEncode(json_encode(['alg' => 'HS256', 'typ' => 'JWT'], JSON_THROW_ON_ERROR));
    $body = $this->base64UrlEncode(json_encode($payload, JSON_THROW_ON_ERROR));
    $signature = $this->sign("{$header}.{$body}");

    return "{$header}.{$body}.{$signature}";
  }

  private function sign(string $data): string
  {
    return $this->base64UrlEncode(hash_hmac('sha256', $data, $this->secret, true));
  }

  private function base64UrlEncode(string $data): string
  {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
  }

  private function base64UrlDecode(string $data): string
  {
    $remainder = strlen($data) % 4;
    if ($remainder > 0) {
      $data .= str_repeat('=', 4 - $remainder);
    }

    $decoded = base64_decode(strtr($data, '-_', '+/'), true);
    if ($decoded === false) {
      throw new RuntimeException('Invalid base64 encoding.');
    }

    return $decoded;
  }
}
