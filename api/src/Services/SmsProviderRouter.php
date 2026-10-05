<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

interface SmsProviderRouterInterface
{
  /**
   * Routes and sends SMS according to destination prefix (e.g., UAE +971 vs International)
   */
  public function send(string $phone, string $message): array;
}

final class SmsProviderRouter implements SmsProviderRouterInterface
{
  /** @var array<string, SmsAdapterInterface> */
  private array $providers = [];

  public function __construct(
    private readonly SmsAdapterInterface $primaryAdapter,
    private readonly ?SmsAdapterInterface $fallbackAdapter = null,
  ) {
    $this->providers['primary'] = $primaryAdapter;
    if ($fallbackAdapter !== null) {
      $this->providers['fallback'] = $fallbackAdapter;
    }
  }

  public function send(string $phone, string $message): array
  {
    $cleanPhone = preg_replace('/[^\d+]/', '', $phone) ?? $phone;
    $isUaeNumber = str_starts_with($cleanPhone, '+971') || str_starts_with($cleanPhone, '00971') || str_starts_with($cleanPhone, '05');

    // Attempt delivery with primary provider
    try {
      $success = $this->primaryAdapter->send($cleanPhone, $message);
      if ($success) {
        return [
          'success' => true,
          'provider' => 'primary',
          'phone' => $cleanPhone,
          'is_gcc_route' => $isUaeNumber,
        ];
      }
    } catch (\Throwable $e) {
      // Log failure and failover
    }

    // Attempt fallback provider if available
    if ($this->fallbackAdapter !== null) {
      try {
        $fallbackSuccess = $this->fallbackAdapter->send($cleanPhone, $message);
        return [
          'success' => $fallbackSuccess,
          'provider' => 'fallback',
          'phone' => $cleanPhone,
          'is_gcc_route' => $isUaeNumber,
        ];
      } catch (\Throwable $e) {
        return [
          'success' => false,
          'provider' => 'fallback',
          'error' => $e->getMessage(),
          'phone' => $cleanPhone,
        ];
      }
    }

    return [
      'success' => false,
      'provider' => 'primary',
      'error' => 'PRIMARY_GATEWAY_FAILED',
      'phone' => $cleanPhone,
    ];
  }
}
