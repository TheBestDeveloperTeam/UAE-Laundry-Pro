<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Middleware;

use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;

final class RateLimitMiddleware
{
    private const DEFAULT_LIMIT = 120; // 120 requests
    private const WINDOW_SECONDS = 60; // per 60 seconds

    public static function handle(Request $request, int $limit = self::DEFAULT_LIMIT): bool
    {
        $ip = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
        $storageDir = dirname(__DIR__, 2) . '/storage/rate_limits';
        if (!is_dir($storageDir)) {
            mkdir($storageDir, 0777, true);
        }

        $key = md5($ip . '_' . ($request->path()));
        $filePath = $storageDir . '/' . $key . '.json';

        $now = time();
        $records = [];

        if (file_exists($filePath)) {
            $data = json_decode(file_get_contents($filePath) ?: '[]', true);
            if (is_array($data)) {
                // Filter out timestamps older than sliding window
                $records = array_filter($data, fn(int $ts): bool => ($now - $ts) < self::WINDOW_SECONDS);
            }
        }

        if (count($records) >= $limit) {
            if (!headers_sent()) {
                header('Retry-After: ' . self::WINDOW_SECONDS);
                header('X-RateLimit-Limit: ' . $limit);
                header('X-RateLimit-Remaining: 0');
                header('X-RateLimit-Reset: ' . ($now + self::WINDOW_SECONDS));
            }

            Response::json([
                'success' => false,
                'code' => 'RATE_LIMIT_EXCEEDED',
                'message' => 'Too many requests. Please retry in ' . self::WINDOW_SECONDS . ' seconds.',
                'data' => null,
                'errors' => ['Rate limit exceeded']
            ], 429);
            return false;
        }

        $records[] = $now;
        file_put_contents($filePath, json_encode(array_values($records)), LOCK_EX);

        if (!headers_sent()) {
            header('X-RateLimit-Limit: ' . $limit);
            header('X-RateLimit-Remaining: ' . max(0, $limit - count($records)));
            header('X-RateLimit-Reset: ' . ($now + self::WINDOW_SECONDS));
        }

        return true;
    }
}
