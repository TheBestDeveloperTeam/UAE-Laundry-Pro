<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Middleware;

use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;

final class CsrfMiddleware
{
    private const SESSION_KEY = '_cloud_csrf_token';

    public static function getToken(): string
    {
        if (session_status() === PHP_SESSION_NONE && !headers_sent()) {
            session_start();
        }

        if (empty($_SESSION[self::SESSION_KEY])) {
            $_SESSION[self::SESSION_KEY] = bin2hex(random_bytes(32));
        }

        return (string) $_SESSION[self::SESSION_KEY];
    }

    public static function field(): string
    {
        $token = htmlspecialchars(self::getToken(), ENT_QUOTES, 'UTF-8');
        return '<input type="hidden" name="_csrf_token" value="' . $token . '">';
    }

    public static function validate(Request $request): bool
    {
        if (session_status() === PHP_SESSION_NONE && !headers_sent()) {
            session_start();
        }

        $sessionToken = (string) ($_SESSION[self::SESSION_KEY] ?? '');
        if ($sessionToken === '') {
            return false;
        }

        $submittedToken = (string) ($request->body('_csrf_token') ?? $request->header('X-CSRF-Token') ?? '');
        if ($submittedToken === '') {
            return false;
        }

        return hash_equals($sessionToken, $submittedToken);
    }

    public static function handle(Request $request): void
    {
        $method = $request->method();
        if (in_array($method, ['POST', 'PUT', 'DELETE', 'PATCH'], true)) {
            // Apply only to portal requests, not to API requests authenticated via Bearer tokens
            if (str_starts_with($request->path(), '/admin')) {
                if (!self::validate($request)) {
                    $_SESSION['flash_error'] = 'Invalid or expired CSRF security token. Please try again.';
                    Response::redirect('/admin/login');
                }
            }
        }
    }
}
