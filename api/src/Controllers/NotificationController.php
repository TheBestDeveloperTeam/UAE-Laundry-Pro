<?php

declare(strict_types=1);

namespace LaundryPro\Api\Controllers;

use LaundryPro\Api\Core\Request;
use LaundryPro\Api\Core\Response;
use LaundryPro\Api\Core\Validator;
use LaundryPro\Api\Repositories\NotificationRepository;
use PDO;

class NotificationController
{
    public function __construct(
        private readonly NotificationRepository $repository,
        private readonly PDO $db
    ) {
    }

    public function registerFcmToken(Request $request, Response $response): void
    {
        $adminId = $request->getAttribute('admin_id');
        $userId = $request->getAttribute('user_id');

        if (!$adminId || !$userId) {
            $response->error(401, 'Unauthorized');
            return;
        }

        $data = $request->getBody();
        $validator = new Validator($data, $this->db);

        $rules = [
            'device_id' => 'required|string',
            'fcm_token' => 'required|string'
        ];

        if (!$validator->validate($rules)) {
            $response->error(400, 'Validation failed', $validator->getErrors());
            return;
        }

        try {
            $this->repository->registerFcmToken(
                (int)$adminId,
                (int)$userId,
                $data['device_id'],
                $data['fcm_token']
            );
            $response->success(null, 'FCM token registered successfully');
        } catch (\Exception $e) {
            $response->error(500, 'Internal Server Error', [$e->getMessage()]);
        }
    }
}
