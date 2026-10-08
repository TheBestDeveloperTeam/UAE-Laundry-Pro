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
        'ErrorResponse' => [
          'type' => 'object',
          'required' => ['success', 'code', 'message_key'],
          'properties' => [
            'success' => ['type' => 'boolean', 'example' => false],
            'code' => ['type' => 'string', 'example' => 'BAD_REQUEST'],
            'message_key' => ['type' => 'string', 'example' => 'error.bad_request'],
            'errors' => [
              'type' => 'array',
              'items' => ['$ref' => '#/components/schemas/ValidationError'],
            ],
            'meta' => ['$ref' => '#/components/schemas/ApiMeta'],
          ],
        ],
        'UnprocessableEntityResponse' => [
          'type' => 'object',
          'required' => ['success', 'code', 'message_key', 'errors'],
          'properties' => [
            'success' => ['type' => 'boolean', 'example' => false],
            'code' => ['type' => 'string', 'example' => 'VALIDATION_FAILED'],
            'message_key' => ['type' => 'string', 'example' => 'error.validation_failed'],
            'errors' => [
              'type' => 'array',
              'items' => ['$ref' => '#/components/schemas/ValidationError'],
            ],
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
          'required' => ['field', 'code', 'message_key'],
          'properties' => [
            'field' => ['type' => 'string', 'example' => 'phone'],
            'code' => ['type' => 'string', 'example' => 'INVALID_FORMAT'],
            'message_key' => ['type' => 'string', 'example' => 'validation.phone_invalid'],
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
        'ServiceCreateRequest' => [
          'type' => 'object',
          'required' => ['name', 'price'],
          'properties' => [
            'name' => ['type' => 'string'],
            'price' => ['type' => 'number'],
            'chemical_dosage_map' => [
              'type' => 'object',
              'additionalProperties' => ['type' => 'number'],
              'example' => ['detergent_id_1' => 10.5, 'softener_id_2' => 5.0]
            ],
          ],
        ],
      ],
    ];
  }
}
