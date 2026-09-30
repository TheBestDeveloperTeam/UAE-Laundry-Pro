<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Database;
use LaundryPro\Cloud\Core\Request;
use LaundryPro\Cloud\Core\Response;
use LaundryPro\Cloud\Middleware\TenantScopeMiddleware;
use PDO;

abstract class BaseController
{
    protected function getAuthenticatedTenant(Request $request): ?array
    {
        return TenantScopeMiddleware::authenticate($request);
    }

    protected function db(): ?PDO
    {
        return Database::connect();
    }

    protected function generateUuid(): string
    {
        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );
    }

    /**
     * Compute UAE 5% VAT using bcmath string math.
     * @return array{subtotal: string, vat: string, total: string}
     */
    protected function calculateVat5(string $subtotal): array
    {
        $sub = bcadd($subtotal, '0.00', 2);
        $vat = bcmul($sub, '0.05', 2);
        $total = bcadd($sub, $vat, 2);
        return [
            'subtotal' => $sub,
            'vat' => $vat,
            'total' => $total,
        ];
    }

    protected function json(mixed $data, int $status = 200): void
    {
        Response::json($data, $status);
    }

    protected function success(mixed $data, string $code = 'SUCCESS', int $status = 200): void
    {
        Response::json([
            'success' => true,
            'code' => $code,
            'data' => $data,
        ], $status);
    }

    protected function error(string $message, string $code = 'ERROR', int $status = 400, ?array $errors = null): void
    {
        $payload = [
            'success' => false,
            'code' => $code,
            'message' => $message,
        ];
        if ($errors !== null) {
            $payload['errors'] = $errors;
        }
        Response::json($payload, $status);
    }
}
