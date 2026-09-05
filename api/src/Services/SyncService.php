<?php

declare(strict_types=1);

namespace LaundryPro\Api\Services;

use LaundryPro\Api\Repositories\SyncOutboxRepository;
use PDO;

final class SyncService
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly SyncOutboxRepository $outbox,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<string, mixed> */
  public function status(): array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM sync_state WHERE business_owner_id = :id LIMIT 1');
    $stmt->execute(['id' => $this->businessOwnerId]);
    $state = $stmt->fetch() ?: [];

    return [
      'enabled' => (bool) ($state['is_enabled'] ?? false),
      'last_push_at' => $state['last_push_at'] ?? null,
      'last_pull_at' => $state['last_pull_at'] ?? null,
      'pending_count' => $this->outbox->pendingCount($this->businessOwnerId),
      'cloud_api_url' => $state['cloud_api_url'] ?? null,
      'cloud_token_set' => !empty($state['cloud_token']),
      'entity_types' => $this->listEntityTypes(),
    ];
  }

  /** @return list<string> */
  public function listEntityTypes(): array
  {
    $stmt = $this->pdo->query('SELECT entity_type FROM sync_entity_types WHERE is_enabled = 1 ORDER BY entity_type');
    $rows = $stmt->fetchAll() ?: [];

    return array_map(fn ($r) => (string) $r['entity_type'], $rows);
  }

  /** @return array<string, mixed> */
  public function push(int $limit = 100): array
  {
    $pending = $this->outbox->pending($this->businessOwnerId, $limit);
    $cloudUrl = $this->getCloudUrl();
    $cloudToken = $this->getCloudToken();
    $pushed = [];

    $records = [];
    foreach ($pending as $row) {
      $records[] = [
        'entity_type' => $row['entity_type'],
        'entity_local_id' => (int) $row['entity_local_id'],
        'operation' => $row['operation'],
        'payload' => json_decode((string) ($row['payload'] ?? '{}'), true),
      ];
    }

    if ($cloudUrl !== null && $cloudToken !== null && $records !== []) {
      $this->httpPost($cloudUrl . '/sync/push', $records, $cloudToken);
    }

    foreach ($pending as $row) {
      $this->outbox->markSynced((int) $row['id']);
      $pushed[] = [
        'id' => (int) $row['id'],
        'entity_type' => $row['entity_type'],
        'entity_local_id' => (int) $row['entity_local_id'],
        'operation' => $row['operation'],
      ];
    }

    $stmt = $this->pdo->prepare(
      'UPDATE sync_state SET last_push_at = UTC_TIMESTAMP() WHERE business_owner_id = :id'
    );
    $stmt->execute(['id' => $this->businessOwnerId]);

    return ['pushed' => count($pushed), 'records' => $pushed];
  }

  /** @return array<string, mixed> */
  public function pull(?string $since = null): array
  {
    $cloudUrl = $this->getCloudUrl();
    $cloudToken = $this->getCloudToken();
    $records = [];

    if ($cloudUrl !== null && $cloudToken !== null) {
      $url = $cloudUrl . '/sync/pull' . ($since !== null ? '?since=' . urlencode($since) : '');
      $response = $this->httpGet($url, $cloudToken);
      $records = $response['data']['records'] ?? [];
    }

    $stmt = $this->pdo->prepare(
      'UPDATE sync_state SET last_pull_at = UTC_TIMESTAMP() WHERE business_owner_id = :id'
    );
    $stmt->execute(['id' => $this->businessOwnerId]);

    return ['since' => $since, 'records' => $records];
  }

  public function registerWithCloud(string $licenseKey): void
  {
    $cloudUrl = $this->getCloudUrl();
    if ($cloudUrl === null) {
      return;
    }

    $stmt = $this->pdo->prepare('SELECT name FROM business WHERE id = 1 LIMIT 1');
    $stmt->execute();
    $business = $stmt->fetch();
    $name = $business['name'] ?? 'LaundryPro Business';

    $response = $this->httpPost($cloudUrl . '/businesses/register', [
      'name' => $name,
      'license_key' => $licenseKey,
    ], null);

    if (!empty($response['data']['cloud_token'])) {
      $upd = $this->pdo->prepare(
        'UPDATE sync_state SET cloud_token = :token, is_enabled = 1 WHERE business_owner_id = :id'
      );
      $upd->execute([
        'token' => $response['data']['cloud_token'],
        'id' => $this->businessOwnerId,
      ]);
    }
  }

  public function enqueue(string $entityType, int $localId, string $operation, array $payload): void
  {
    $this->outbox->enqueue($this->businessOwnerId, $entityType, $localId, $operation, $payload);
  }

  /** @param array<string, mixed> $config */
  public function updateConfig(array $config): void
  {
    $stmt = $this->pdo->prepare(
      'UPDATE sync_state SET is_enabled = :enabled, cloud_api_url = :url WHERE business_owner_id = :id'
    );
    $stmt->execute([
      'enabled' => !empty($config['enabled']) ? 1 : 0,
      'url' => $config['cloud_api_url'] ?? null,
      'id' => $this->businessOwnerId,
    ]);
  }

  private function getCloudUrl(): ?string
  {
    $stmt = $this->pdo->prepare('SELECT cloud_api_url FROM sync_state WHERE business_owner_id = :id LIMIT 1');
    $stmt->execute(['id' => $this->businessOwnerId]);
    $row = $stmt->fetch();
    $url = $row['cloud_api_url'] ?? null;

    return is_string($url) && $url !== '' ? rtrim($url, '/') : null;
  }

  private function getCloudToken(): ?string
  {
    $stmt = $this->pdo->prepare('SELECT cloud_token FROM sync_state WHERE business_owner_id = :id LIMIT 1');
    $stmt->execute(['id' => $this->businessOwnerId]);
    $row = $stmt->fetch();
    $token = $row['cloud_token'] ?? null;

    return is_string($token) && $token !== '' ? $token : null;
  }

  /** @param array<string, mixed> $body */
  /** @return array<string, mixed> */
  private function httpPost(string $url, array $body, ?string $token): array
  {
    $headers = [
      'Content-Type: application/json',
      'X-Business-Owner-Id: ' . $this->businessOwnerId,
    ];
    if ($token !== null) {
      $headers[] = 'Authorization: Bearer ' . $token;
    }

    $ch = curl_init($url);
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_POST => true,
      CURLOPT_HTTPHEADER => $headers,
      CURLOPT_POSTFIELDS => json_encode($body),
      CURLOPT_TIMEOUT => 10,
    ]);
    $response = curl_exec($ch);
    curl_close($ch);

    return is_string($response) ? (json_decode($response, true) ?: []) : [];
  }

  /** @return array<string, mixed> */
  private function httpGet(string $url, string $token): array
  {
    $ch = curl_init($url);
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_HTTPHEADER => [
        'Authorization: Bearer ' . $token,
        'X-Business-Owner-Id: ' . $this->businessOwnerId,
      ],
      CURLOPT_TIMEOUT => 10,
    ]);
    $response = curl_exec($ch);
    curl_close($ch);

    return is_string($response) ? (json_decode($response, true) ?: []) : [];
  }
}
