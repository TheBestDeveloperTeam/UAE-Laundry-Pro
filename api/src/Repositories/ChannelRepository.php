<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class ChannelRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return list<array<string, mixed>> */
  public function list(): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT id, uuid, channel_type, provider, is_active, created_at FROM notification_channels
       WHERE business_owner_id = :owner ORDER BY channel_type'
    );
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO notification_channels (uuid, business_owner_id, channel_type, provider, config_json, is_active)
       VALUES (:uuid, :owner, :type, :provider, :config, 1)'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'owner' => $this->businessOwnerId,
      'type' => $data['channel_type'],
      'provider' => $data['provider'] ?? 'stub',
      'config' => json_encode($data['config'] ?? []),
    ]);
    $id = (int) $this->pdo->lastInsertId();

    return $this->findById($id) ?? [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM notification_channels WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  public function logMessage(int $channelId, string $recipient, string $templateKey, string $body, string $status = 'sent'): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO notification_messages (channel_id, recipient, template_key, body, status)
       VALUES (:channel, :recipient, :key, :body, :status)'
    );
    $stmt->execute([
      'channel' => $channelId,
      'recipient' => $recipient,
      'key' => $templateKey,
      'body' => $body,
      'status' => $status,
    ]);

    return [
      'id' => (int) $this->pdo->lastInsertId(),
      'channel_id' => $channelId,
      'recipient' => $recipient,
      'template_key' => $templateKey,
      'status' => $status,
    ];
  }

  private function uuid(): string
  {
    return sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
      random_int(0, 0xffff), random_int(0, 0xffff),
      random_int(0, 0xffff),
      random_int(0, 0x0fff) | 0x4000,
      random_int(0, 0x3fff) | 0x8000,
      random_int(0, 0xffff), random_int(0, 0xffff), random_int(0, 0xffff)
    );
  }
}
