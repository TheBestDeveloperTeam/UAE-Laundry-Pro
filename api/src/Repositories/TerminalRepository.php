<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class TerminalRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return list<array<string, mixed>> */
  public function list(?int $branchId = null): array
  {
    $sql = 'SELECT t.*, br.code AS branch_code FROM terminals t
            INNER JOIN branches br ON br.id = t.branch_id
            INNER JOIN business b ON b.id = br.business_id AND b.business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];
    if ($branchId !== null) {
      $sql .= ' WHERE t.branch_id = :branch';
      $params['branch'] = $branchId;
    }
    $sql .= ' ORDER BY br.code, t.code';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT t.* FROM terminals t
       INNER JOIN branches br ON br.id = t.branch_id
       INNER JOIN business b ON b.id = br.business_id AND b.business_owner_id = :owner
       WHERE t.id = :id LIMIT 1'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'id' => $id]);
    $row = $stmt->fetch();

    return $row ?: null;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data): array
  {
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO terminals (uuid, branch_id, code, name, is_active) VALUES (:uuid, :branch, :code, :name, 1)'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'branch' => (int) $data['branch_id'],
      'code' => strtoupper((string) $data['code']),
      'name' => (string) $data['name'],
    ]);

    return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @param array<string, mixed> $data */
  public function registerSession(int $terminalId, array $data): array
  {
    $token = bin2hex(random_bytes(32));
    $uuid = $this->uuid();
    $stmt = $this->pdo->prepare(
      'INSERT INTO terminal_sessions (uuid, business_owner_id, terminal_id, session_token, device_fingerprint, last_seen_at)
       VALUES (:uuid, :owner, :terminal, :token, :fp, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $uuid,
      'owner' => $this->businessOwnerId,
      'terminal' => $terminalId,
      'token' => $token,
      'fp' => $data['device_fingerprint'] ?? null,
    ]);

    return [
      'session_token' => $token,
      'terminal_id' => $terminalId,
      'id' => (int) $this->pdo->lastInsertId(),
    ];
  }

  public function activeSessionCount(int $terminalId): int
  {
    $stmt = $this->pdo->prepare(
      'SELECT COUNT(*) FROM terminal_sessions WHERE terminal_id = :id AND is_active = 1'
    );
    $stmt->execute(['id' => $terminalId]);

    return (int) $stmt->fetchColumn();
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
