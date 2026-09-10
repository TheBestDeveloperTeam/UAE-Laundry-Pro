<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

class TwilioSmsAdapter implements SmsAdapterInterface
{
  public function send(string $phone, string $message): bool
  {
    // Logic to call Twilio REST API
    return true;
  }
}
