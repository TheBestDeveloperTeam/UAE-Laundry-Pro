<?php

declare(strict_types=1);

namespace LaundryPro\Api\Docs\Schemas;

final class ApiSchemas
{
  /** @return array<string, mixed> */
  public static function components(): array
  {
    return [
      'securitySchemes' => [
        'bearerAuth' => [
          'type' => 'http',
          'scheme' => 'bearer',
          'bearerFormat' => 'JWT',
        ],
        'installToken' => [
          'type' => 'apiKey',
          'in' => 'header',
          'name' => 'X-Install-Token',
        ],
      ],
      'schemas' => [
        'ApiEnvelope' => [
          'type' => 'object',
          'properties' => [
            'success' => ['type' => 'boolean'],
            'code' => ['type' => 'string'],
            'message_key' => ['type' => 'string'],
            'data' => ['nullable' => true],
            'errors' => ['type' => 'array', 'items' => ['$ref' => '#/components/schemas/ValidationError']],
            'meta' => ['$ref' => '#/components/schemas/ApiMeta'],
          ],
        ],
        'ApiMeta' => [
          'type' => 'object',
          'properties' => [
            'request_id' => ['type' => 'string'],
            'server_time' => ['type' => 'string', 'format' => 'date-time'],
            'version' => ['type' => 'string'],
          ],
        ],
        'ValidationError' => [
          'type' => 'object',
          'properties' => [
            'field' => ['type' => 'string'],
            'code' => ['type' => 'string'],
            'message_key' => ['type' => 'string'],
          ],
        ],
        'LoginRequest' => [
          'type' => 'object',
          'required' => ['username', 'password'],
          'properties' => [
            'username' => ['type' => 'string'],
            'password' => ['type' => 'string', 'format' => 'password'],
          ],
        ],
        'RefreshRequest' => [
          'type' => 'object',
          'required' => ['refresh_token'],
          'properties' => [
            'refresh_token' => ['type' => 'string'],
          ],
        ],
        'SettingsUpdateRequest' => [
          'type' => 'object',
          'required' => ['settings'],
          'properties' => [
            'settings' => ['type' => 'object', 'additionalProperties' => true],
          ],
        ],
        'SeedRequest' => [
          'type' => 'object',
          'properties' => [
            'admin_password' => ['type' => 'string', 'format' => 'password'],
          ],
        ],
      ],
    ];
  }
}
