<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

interface SmsAdapterInterface
{
  public function send(string $phone, string $message): bool;
}
