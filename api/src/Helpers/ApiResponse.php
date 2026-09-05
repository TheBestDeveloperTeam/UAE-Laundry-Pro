<?php

declare(strict_types=1);

namespace LaundryPro\Api\Helpers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;

final class ApiResponse
{
  public function __construct(
    private readonly string $version,
  ) {
  }

  /** @param array<string, mixed>|null $data */
  public function success(
    Request $request,
    ?array $data = null,
    string $code = 'OK',
    string $messageKey = 'common.success',
    int $status = 200,
  ): void {
    Response::json([
      'success' => true,
      'code' => $code,
      'message_key' => $messageKey,
      'data' => $data,
      'errors' => [],
      'meta' => $this->meta($request),
    ], $status);
  }

  /** @param array<int, array<string, mixed>> $errors */
  public function error(
    Request $request,
    string $code,
    string $messageKey,
    int $status = 400,
    array $errors = [],
    ?array $data = null,
    array $extraMeta = [],
  ): void {
    Response::json([
      'success' => false,
      'code' => $code,
      'message_key' => $messageKey,
      'data' => $data,
      'errors' => $errors,
      'meta' => array_merge($this->meta($request), $extraMeta),
    ], $status);
  }

  /** @return array<string, string> */
  private function meta(Request $request): array
  {
    return [
      'request_id' => $request->getRequestId(),
      'server_time' => gmdate('c'),
      'version' => $this->version,
    ];
  }
}
