<?php

declare(strict_types=1);

namespace LaundryPro\Api\Docs;

use LaundryPro\Api\Core\RouteRegistry;
use LaundryPro\Api\Docs\Schemas\ApiSchemas;

final class OpenApiGenerator
{
  public function __construct(
    private readonly string $title,
    private readonly string $version,
    private readonly string $serverUrl,
  ) {
  }

  /** @return array<string, mixed> */
  public function generate(): array
  {
    $paths = [];
    $tags = [];

    foreach (RouteRegistry::all() as $route) {
      $openApiPath = $this->toOpenApiPath((string) $route['path']);
      $method = strtolower((string) $route['method']);
      $tag = (string) ($route['tag'] ?? 'Platform');
      $tags[$tag] = ['name' => $tag, 'description' => $tag . ' module endpoints'];

      $operation = [
        'tags' => [$tag],
        'summary' => (string) ($route['summary'] ?? ''),
        'operationId' => $this->operationId($route),
        'responses' => $this->buildResponses($route),
      ];

      if (($route['requestBody'] ?? null) !== null) {
        $operation['requestBody'] = [
          'required' => true,
          'content' => [
            'application/json' => [
              'schema' => ['$ref' => '#/components/schemas/' . $route['requestBody']],
            ],
          ],
        ];
      }

      if (($route['security'] ?? true) === true) {
        $scheme = (string) ($route['securityScheme'] ?? 'bearerAuth');
        $operation['security'] = [[$scheme => []]];
      } elseif (!empty($route['securityScheme'])) {
        $operation['security'] = [[(string) $route['securityScheme'] => []]];
      }

      if (!isset($paths[$openApiPath])) {
        $paths[$openApiPath] = [];
      }
      $paths[$openApiPath][$method] = $operation;
    }

    return [
      'openapi' => '3.0.3',
      'info' => [
        'title' => $this->title,
        'version' => $this->version,
        'description' => 'Live-generated OpenAPI specification for LaundryPro UAE API.',
      ],
      'servers' => [
        ['url' => rtrim($this->serverUrl, '/')],
      ],
      'tags' => array_values($tags),
      'paths' => $paths,
      'components' => ApiSchemas::components(),
    ];
  }

  /** @param array<string, mixed> $route */
  private function buildResponses(array $route): array
  {
    $responses = [];
    $map = $route['responses'] ?? ['200' => 'OK'];
    if (!is_array($map)) {
      $map = ['200' => 'OK'];
    }

    foreach ($map as $status => $code) {
      $responses[(string) $status] = [
        'description' => (string) $code,
        'content' => [
          'application/json' => [
            'schema' => ['$ref' => '#/components/schemas/ApiEnvelope'],
          ],
        ],
      ];
    }

    return $responses;
  }

  /** @param array<string, mixed> $route */
  private function operationId(array $route): string
  {
    $handler = $route['handler'];
    $action = is_array($handler) ? ($handler[1] ?? 'action') : 'action';
    $path = str_replace(['/api/v1/', '/', '{', '}'], ['', '_', '', ''], (string) $route['path']);

    return strtolower((string) $route['method'] . '_' . trim($path, '_') . '_' . $action);
  }

  private function toOpenApiPath(string $path): string
  {
    $path = preg_replace('#^/api/v1#', '', $path) ?? $path;

    return $path === '' ? '/' : $path;
  }
}
