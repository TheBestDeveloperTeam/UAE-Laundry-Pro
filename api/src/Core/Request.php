<?php

declare(strict_types=1);

namespace LaundryPro\Api\Core;

final class Request
{
  private string $requestId;

  /** @param array<string, mixed> $routeParams */
  public function __construct(
    private readonly string $method,
    private readonly string $path,
    private readonly array $query,
    private readonly array $body,
    private readonly array $headers,
    private readonly array $routeParams = [],
  ) {
    $this->requestId = bin2hex(random_bytes(8));
  }

  public static function capture(): self
  {
    $method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    $uri = $_SERVER['REQUEST_URI'] ?? '/';
    $path = parse_url($uri, PHP_URL_PATH) ?: '/';

    $headers = [];
    foreach ($_SERVER as $key => $value) {
      if (str_starts_with($key, 'HTTP_')) {
        $name = str_replace(' ', '-', ucwords(strtolower(str_replace('_', ' ', substr($key, 5)))));
        $headers[$name] = (string) $value;
      }
    }

    if (isset($_SERVER['CONTENT_TYPE'])) {
      $headers['Content-Type'] = (string) $_SERVER['CONTENT_TYPE'];
    }

    if (isset($_SERVER['CONTENT_LENGTH'])) {
      $headers['Content-Length'] = (string) $_SERVER['CONTENT_LENGTH'];
    }

    if (!isset($headers['Authorization']) && isset($_SERVER['HTTP_AUTHORIZATION'])) {
      $headers['Authorization'] = (string) $_SERVER['HTTP_AUTHORIZATION'];
    }

    if (!isset($headers['Authorization']) && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
      $headers['Authorization'] = (string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }

  $rawBody = file_get_contents('php://input') ?: '';
    $body = [];
    $contentType = $headers['Content-Type'] ?? '';

    if (str_contains($contentType, 'application/json') && $rawBody !== '') {
      $decoded = json_decode($rawBody, true);
      if (is_array($decoded)) {
        $body = $decoded;
      }
    } elseif ($method === 'POST' && empty($body)) {
      $body = $_POST;
    }

    return new self($method, $path, $_GET, $body, $headers);
  }

  public function withRouteParams(array $params): self
  {
    return new self(
      $this->method,
      $this->path,
      $this->query,
      $this->body,
      $this->headers,
      $params
    );
  }

  public function withPath(string $path): self
  {
    return new self(
      $this->method,
      $path,
      $this->query,
      $this->body,
      $this->headers,
      $this->routeParams
    );
  }

  public function getMethod(): string
  {
    return $this->method;
  }

  public function getPath(): string
  {
    return $this->path;
  }

  public function getRequestId(): string
  {
    return $this->requestId;
  }

  public function query(string $key, mixed $default = null): mixed
  {
    return $this->query[$key] ?? $default;
  }

  public function input(string $key, mixed $default = null): mixed
  {
    return $this->body[$key] ?? $default;
  }

  /** @return array<string, mixed> */
  public function all(): array
  {
    return $this->body;
  }

  public function header(string $name, ?string $default = null): ?string
  {
    return $this->headers[$name] ?? $default;
  }

  public function bearerToken(): ?string
  {
    $auth = $this->header('Authorization');
    if ($auth === null || !str_starts_with($auth, 'Bearer ')) {
      return null;
    }

    return trim(substr($auth, 7));
  }

  public function route(string $key, mixed $default = null): mixed
  {
    return $this->routeParams[$key] ?? $default;
  }

  public function ip(): string
  {
    return $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
  }
}
