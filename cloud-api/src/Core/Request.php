<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Core;

final class Request
{
    private string $method;
    private string $path;
    private array $headers;
    private array $queryParams;
    private array $parsedBody;
    private string $rawBody;

    public function __construct()
    {
        $this->method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
        $uri = $_SERVER['REQUEST_URI'] ?? '/';
        $this->path = parse_url($uri, PHP_URL_PATH) ?: '/';
        $this->queryParams = $_GET;
        $this->headers = $this->captureHeaders();
        $this->rawBody = file_get_contents('php://input') ?: '';

        $contentType = $this->header('Content-Type') ?? '';
        if (str_contains($contentType, 'application/json') && $this->rawBody !== '') {
            $decoded = json_decode($this->rawBody, true);
            $this->parsedBody = is_array($decoded) ? $decoded : [];
        } else {
            $this->parsedBody = $_POST;
        }
    }

    private function captureHeaders(): array
    {
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
        if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers['Authorization'] = (string) $_SERVER['HTTP_AUTHORIZATION'];
        }
        return $headers;
    }

    public function method(): string
    {
        return $this->method;
    }

    public function path(): string
    {
        return $this->path;
    }

    public function header(string $name, ?string $default = null): ?string
    {
        foreach ($this->headers as $k => $v) {
            if (strcasecmp($k, $name) === 0) {
                return $v;
            }
        }
        return $default;
    }

    public function query(string $key, mixed $default = null): mixed
    {
        return $this->queryParams[$key] ?? $default;
    }

    public function body(?string $key = null, mixed $default = null): mixed
    {
        if ($key === null) {
            return $this->parsedBody;
        }
        return $this->parsedBody[$key] ?? $default;
    }

    public function bearerToken(): ?string
    {
        $auth = $this->header('Authorization');
        if ($auth && preg_match('/Bearer\s+(.*)$/i', $auth, $matches)) {
            return trim($matches[1]);
        }
        return null;
    }

    public function businessOwnerId(): int
    {
        return (int) ($this->header('X-Business-Owner-Id') ?? 0);
    }
}
