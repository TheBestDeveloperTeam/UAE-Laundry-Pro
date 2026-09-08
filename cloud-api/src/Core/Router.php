<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Core;

final class Router
{
    private array $routes = [];

    public function get(string $path, callable|array $handler): void
    {
        $this->add('GET', $path, $handler);
    }

    public function post(string $path, callable|array $handler): void
    {
        $this->add('POST', $path, $handler);
    }

    public function put(string $path, callable|array $handler): void
    {
        $this->add('PUT', $path, $handler);
    }

    public function delete(string $path, callable|array $handler): void
    {
        $this->add('DELETE', $path, $handler);
    }

    public function add(string $method, string $path, callable|array $handler): void
    {
        $this->routes[] = [
            'method' => strtoupper($method),
            'pattern' => $path,
            'handler' => $handler,
        ];
    }

    public function dispatch(Request $request): void
    {
        $reqMethod = $request->method();
        $reqPath = $request->path();

        // Normalize subfolder paths if running in /cloud-api/public or similar
        if (str_contains($reqPath, '/public')) {
            $reqPath = substr($reqPath, strpos($reqPath, '/public') + strlen('/public')) ?: '/';
        }

        foreach ($this->routes as $route) {
            if ($route['method'] !== $reqMethod) {
                continue;
            }

            $pattern = preg_replace('/\{([a-zA-Z0-9_]+)\}/', '(?P<$1>[^/]+)', $route['pattern']);
            $pattern = '#^' . $pattern . '$#';

            if (preg_match($pattern, $reqPath, $matches)) {
                $params = [];
                foreach ($matches as $k => $v) {
                    if (!is_int($k)) {
                        $params[$k] = $v;
                    }
                }

                $handler = $route['handler'];
                if (is_array($handler)) {
                    [$class, $method] = $handler;
                    $controller = new $class();
                    $controller->$method($request, $params);
                    return;
                }

                $handler($request, $params);
                return;
            }
        }

        // Fallback or 404
        if (str_starts_with($reqPath, '/api/')) {
            Response::json(['success' => false, 'code' => 'NOT_FOUND', 'message' => 'Endpoint not found'], 404);
        } else {
            http_response_code(404);
            echo '<h1>404 Not Found</h1>';
            exit;
        }
    }
}
