<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

final class Response
{
  /** @param array<string, mixed> $data */
  public static function json(
    array $data,
    int $status = 200,
    array $headers = []
  ): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');

    foreach ($headers as $name => $value) {
      header($name . ': ' . $value);
    }

    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
  }
}
