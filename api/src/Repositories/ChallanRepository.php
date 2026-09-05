<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

final class ChallanRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function list(?string $challanType = null, int $limit = 50): array
  {
    $sql = 'SELECT * FROM challans WHERE business_owner_id = :owner';
    $params = ['owner' => $this->businessOwnerId];

    if ($challanType !== null && $challanType !== '') {
      $sql .= ' AND challan_type = :type';
      $params['type'] = $challanType;
    }

    $sql .= ' ORDER BY id DESC LIMIT ' . (int) $limit;
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll() ?: [];

    foreach ($rows as &$row) {
      $row['lines'] = $this->lines((int) $row['id']);
    }

    return $rows;
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare(
      'SELECT * FROM challans WHERE id = :id AND business_owner_id = :owner LIMIT 1'
    );
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    $row = $stmt->fetch();
    if (!$row) {
      return null;
    }
    $row['lines'] = $this->lines($id);
    $row['sequence_no'] = $this->sequenceNoForChallan((string) $row['challan_type'], (string) $row['challan_no']);

    return $row;
  }

  /** @param array<string, mixed> $data */
  public function create(array $data, int $userId): array
  {
    $type = (string) ($data['challan_type'] ?? 'delivery');
    $numbering = $this->nextChallanNo($type);
    $challanNo = (string) ($data['challan_no'] ?? $numbering['challan_no']);

    $this->pdo->beginTransaction();
    try {
      $stmt = $this->pdo->prepare(
        'INSERT INTO challans (uuid, business_owner_id, challan_no, challan_type, reference_type, reference_id, status, notes, created_by, created_at)
         VALUES (:uuid, :owner, :no, :type, :ref_type, :ref_id, :status, :notes, :user, UTC_TIMESTAMP())'
      );
      $stmt->execute([
        'uuid' => $this->uuid(),
        'owner' => $this->businessOwnerId,
        'no' => $challanNo,
        'type' => $type,
        'ref_type' => $data['reference_type'] ?? null,
        'ref_id' => isset($data['reference_id']) ? (int) $data['reference_id'] : null,
        'status' => $data['status'] ?? 'issued',
        'notes' => $data['notes'] ?? null,
        'user' => $userId,
      ]);
      $challanId = (int) $this->pdo->lastInsertId();

      $lines = $data['lines'] ?? [];
      if (is_array($lines)) {
        $this->replaceLines($challanId, $lines);
      }

      $this->pdo->commit();
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      throw $e;
    }

    return $this->findById($challanId) ?? [];
  }

  private function enrichChallan(array $row): array
  {
    $row['sequence_no'] = $this->sequenceNoForChallan(
      (string) ($row['challan_type'] ?? ''),
      (string) ($row['challan_no'] ?? ''),
    );

    return $row;
  }

  /** @param array<string, mixed> $data */
  public function update(int $id, array $data): ?array
  {
    $existing = $this->findById($id);
    if ($existing === null) {
      return null;
    }

    $this->pdo->beginTransaction();
    try {
      $stmt = $this->pdo->prepare(
        'UPDATE challans SET status = :status, notes = :notes, reference_type = :ref_type, reference_id = :ref_id
         WHERE id = :id AND business_owner_id = :owner'
      );
      $stmt->execute([
        'id' => $id,
        'owner' => $this->businessOwnerId,
        'status' => $data['status'] ?? $existing['status'],
        'notes' => $data['notes'] ?? $existing['notes'],
        'ref_type' => $data['reference_type'] ?? $existing['reference_type'],
        'ref_id' => $data['reference_id'] ?? $existing['reference_id'],
      ]);

      if (isset($data['lines']) && is_array($data['lines'])) {
        $this->replaceLines($id, $data['lines']);
      }

      $this->pdo->commit();
    } catch (\Throwable $e) {
      $this->pdo->rollBack();
      throw $e;
    }

    return $this->findById($id);
  }

  public function cancel(int $id): ?array
  {
    return $this->update($id, ['status' => 'cancelled']);
  }

  private function nextChallanNo(string $type): array
  {
    $stmt = $this->pdo->prepare(
      'INSERT INTO challan_sequences (business_owner_id, challan_type, last_number)
       VALUES (:owner, :type, 1)
       ON DUPLICATE KEY UPDATE last_number = last_number + 1'
    );
    $stmt->execute(['owner' => $this->businessOwnerId, 'type' => $type]);

    $sel = $this->pdo->prepare(
      'SELECT last_number FROM challan_sequences WHERE business_owner_id = :owner AND challan_type = :type LIMIT 1'
    );
    $sel->execute(['owner' => $this->businessOwnerId, 'type' => $type]);
    $n = (int) $sel->fetchColumn();

    $prefix = strtoupper(substr($type, 0, 3));

    return [
      'challan_no' => $prefix . '-' . str_pad((string) $n, 6, '0', STR_PAD_LEFT),
      'sequence_no' => $n,
    ];
  }

  private function sequenceNoForChallan(string $type, string $challanNo): int
  {
    if (preg_match('/(\d+)$/', $challanNo, $m)) {
      return (int) $m[1];
    }

    return 0;
  }

  /** @param array<int, array<string, mixed>> $lines */
  private function replaceLines(int $challanId, array $lines): void
  {
    $del = $this->pdo->prepare('DELETE FROM challan_lines WHERE challan_id = :id');
    $del->execute(['id' => $challanId]);

    $ins = $this->pdo->prepare(
      'INSERT INTO challan_lines (challan_id, line_no, description, quantity, unit)
       VALUES (:challan, :line, :desc, :qty, :unit)'
    );
    $lineNo = 1;
    foreach ($lines as $line) {
      $ins->execute([
        'challan' => $challanId,
        'line' => $lineNo++,
        'desc' => (string) ($line['description'] ?? ''),
        'qty' => (float) ($line['quantity'] ?? 1),
        'unit' => $line['unit'] ?? null,
      ]);
    }
  }

  /** @return array<int, array<string, mixed>> */
  private function lines(int $challanId): array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM challan_lines WHERE challan_id = :id ORDER BY line_no');
    $stmt->execute(['id' => $challanId]);

    return $stmt->fetchAll() ?: [];
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
