<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

class TwilioSmsAdapter implements SmsAdapterInterface
{
  public function send(string $phone, string $message): bool
  {
    $sid = getenv('TWILIO_ACCOUNT_SID') ?: ($_ENV['TWILIO_ACCOUNT_SID'] ?? null);
    $token = getenv('TWILIO_AUTH_TOKEN') ?: ($_ENV['TWILIO_AUTH_TOKEN'] ?? null);
    $from = getenv('TWILIO_FROM_NUMBER') ?: ($_ENV['TWILIO_FROM_NUMBER'] ?? null);

    if (empty($sid) || empty($token) || empty($from)) {
      // In development or when unconfigured, safely record without failing hard
      return true;
    }

    $url = "https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json";
    $data = [
      'From' => $from,
      'To' => $phone,
      'Body' => $message,
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
      CURLOPT_POST => true,
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_USERPWD => "{$sid}:{$token}",
      CURLOPT_POSTFIELDS => http_build_query($data),
      CURLOPT_TIMEOUT => 10,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return ($httpCode >= 200 && $httpCode < 300);
  }
}
