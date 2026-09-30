<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Core;

final class Response
{
    public static bool $shouldExit = true;

    public static function json(array $data, int $status = 200): void
    {
        http_response_code($status);
        if (!headers_sent()) {
            header('Content-Type: application/json; charset=utf-8');
            header('X-Content-Type-Options: nosniff');
            header('X-Frame-Options: DENY');
        }

        if (!isset($data['meta'])) {
            $data['meta'] = [
                'request_id' => bin2hex(random_bytes(16)),
                'server_time' => gmdate('c'),
                'version' => '2.0.0',
            ];
        }

        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if (self::$shouldExit) {
            exit;
        }
    }

    public static function view(string $viewPath, array $data = [], string $layout = 'main'): void
    {
        extract($data);
        $viewsDir = dirname(__DIR__) . '/Views/';
        $viewFile = $viewsDir . $viewPath . '.php';

        if (!file_exists($viewFile)) {
            http_response_code(500);
            echo 'View not found: ' . htmlspecialchars($viewPath);
            exit;
        }

        ob_start();
        require $viewFile;
        $content = ob_get_clean();

        if ($layout === '') {
            echo $content;
            exit;
        }

        $layoutFile = $viewsDir . 'layouts/' . $layout . '.php';
        if (file_exists($layoutFile)) {
            require $layoutFile;
        } else {
            echo $content;
        }
        exit;
    }

    public static function redirect(string $url): void
    {
        header('Location: ' . $url);
        exit;
    }
}
