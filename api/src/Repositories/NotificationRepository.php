<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\Uuid;
use PDO;

class NotificationRepository
{
    public function __construct(private readonly PDO $db)
    {
    }

    public function createNotification(int $adminId, array $data): int
    {
        $sql = "INSERT INTO notifications (uuid, admin_id, row_uuid, user_id, title, body, type, related_entity_type, related_entity_id)
                VALUES (:uuid, :admin_id, :row_uuid, :user_id, :title, :body, :type, :related_entity_type, :related_entity_id)";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            'uuid' => Uuid::v4(),
            'admin_id' => $adminId,
            'row_uuid' => Uuid::v4(),
            'user_id' => $data['user_id'],
            'title' => $data['title'],
            'body' => $data['body'],
            'type' => $data['type'] ?? 'system',
            'related_entity_type' => $data['related_entity_type'] ?? null,
            'related_entity_id' => $data['related_entity_id'] ?? null,
        ]);

        return (int) $this->db->lastInsertId();
    }

    public function registerFcmToken(int $adminId, int $userId, string $deviceId, string $fcmToken): void
    {
        $sql = "INSERT INTO fcm_tokens (admin_id, user_id, device_id, fcm_token)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE fcm_token = VALUES(fcm_token), updated_at = NOW()";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([$adminId, $userId, $deviceId, $fcmToken]);
    }

    public function getTokensForUser(int $adminId, int $userId): array
    {
        $stmt = $this->db->prepare("SELECT fcm_token FROM fcm_tokens WHERE admin_id = ? AND user_id = ?");
        $stmt->execute([$adminId, $userId]);
        return $stmt->fetchAll(PDO::FETCH_COLUMN);
    }
}
