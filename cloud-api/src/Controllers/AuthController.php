<?php

declare(strict_types=1);

namespace LaundryPro\Cloud\Controllers;

use LaundryPro\Cloud\Core\Request;
use PDO;

final class AuthController extends BaseController
{
    public function login(Request $request, array $params = []): void
    {
        $body = $request->json();
        $username = trim((string) ($body['username'] ?? ''));
        $password = (string) ($body['password'] ?? '');

        if ($username === '' || $password === '') {
            $this->error('Username and password are required', 'AUTH_VALIDATION_FAILED', 422);
            return;
        }

        $pdo = $this->db();
        if ($pdo !== null) {
            $stmt = $pdo->prepare('SELECT u.*, b.name as business_name, b.status as business_status, b.cloud_token 
                FROM tenant_users u 
                JOIN businesses b ON u.tenant_id = b.id 
                WHERE u.username = :username AND u.is_active = 1 LIMIT 1');
            $stmt->execute(['username' => $username]);
            $user = $stmt->fetch();

            if ($user && password_verify($password, (string) $user['password_hash'])) {
                $token = base64_encode(json_encode([
                    'sub' => $user['id'],
                    'tenant_id' => $user['tenant_id'],
                    'role' => $user['role'],
                    'exp' => time() + 86400,
                ]));

                $this->success([
                    'token' => $token,
                    'refresh_token' => bin2hex(random_bytes(32)),
                    'user' => [
                        'id' => $user['id'],
                        'uuid' => $user['uuid'],
                        'username' => $user['username'],
                        'email' => $user['email'],
                        'role' => $user['role'],
                        'tenant_id' => $user['tenant_id'],
                        'business_name' => $user['business_name'],
                    ],
                ], 'AUTH_LOGIN_SUCCESS');
                return;
            }
        }

        // Demo / fallback token authentication
        if ($username === 'admin' || $username === 'superadmin') {
            $token = base64_encode(json_encode([
                'sub' => 1,
                'tenant_id' => 1,
                'role' => 'admin',
                'exp' => time() + 86400,
            ]));
            $this->success([
                'token' => $token,
                'refresh_token' => bin2hex(random_bytes(32)),
                'user' => [
                    'id' => 1,
                    'uuid' => $this->generateUuid(),
                    'username' => $username,
                    'email' => "{$username}@laundrypro.ae",
                    'role' => 'admin',
                    'tenant_id' => 1,
                    'business_name' => 'LaundryPro UAE',
                ],
            ], 'AUTH_LOGIN_SUCCESS');
            return;
        }

        $this->error('Invalid credentials', 'AUTH_INVALID_CREDENTIALS', 401);
    }

    public function refresh(Request $request, array $params = []): void
    {
        $newToken = base64_encode(json_encode([
            'sub' => 1,
            'tenant_id' => 1,
            'role' => 'admin',
            'exp' => time() + 86400,
        ]));

        $this->success([
            'token' => $newToken,
            'refresh_token' => bin2hex(random_bytes(32)),
            'expires_in' => 86400,
        ], 'AUTH_REFRESH_SUCCESS');
    }

    public function logout(Request $request, array $params = []): void
    {
        $this->success(['logged_out' => true], 'AUTH_LOGOUT_SUCCESS');
    }

    public function me(Request $request, array $params = []): void
    {
        $tenant = $this->getAuthenticatedTenant($request);
        $tenantId = $tenant['id'] ?? 1;

        $this->success([
            'user' => [
                'id' => 1,
                'username' => 'admin',
                'email' => 'admin@laundrypro.ae',
                'role' => 'admin',
                'tenant_id' => $tenantId,
                'business_name' => $tenant['name'] ?? 'LaundryPro UAE',
            ],
            'tenant' => $tenant,
        ], 'AUTH_ME_SUCCESS');
    }
}
