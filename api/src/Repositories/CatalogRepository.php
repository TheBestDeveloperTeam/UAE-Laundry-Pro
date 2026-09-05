<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;

final class CatalogRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  /** @return array<int, array<string, mixed>> */
  public function listServices(?int $parentId = null): array
  {
    $sql = 'SELECT * FROM services WHERE business_owner_id = :owner AND is_active = 1';
    $params = ['owner' => $this->businessOwnerId];

    if ($parentId === null) {
      $sql .= ' AND parent_id IS NULL';
    } else {
      $sql .= ' AND parent_id = :parent';
      $params['parent'] = $parentId;
    }

    $sql .= ' ORDER BY name ASC';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  /** @return array<int, array<string, mixed>> */
  public function listProducts(?int $parentId = null, ?string $barcode = null): array
  {
    if ($barcode !== null && $barcode !== '') {
      $stmt = $this->pdo->prepare(
        'SELECT * FROM products WHERE business_owner_id = :owner AND barcode = :barcode AND is_active = 1 LIMIT 1'
      );
      $stmt->execute(['owner' => $this->businessOwnerId, 'barcode' => $barcode]);
      $row = $stmt->fetch();

      return $row ? [$row] : [];
    }

    $sql = 'SELECT * FROM products WHERE business_owner_id = :owner AND is_active = 1';
    $params = ['owner' => $this->businessOwnerId];

    if ($parentId === null) {
      $sql .= ' AND parent_id IS NULL';
    } else {
      $sql .= ' AND parent_id = :parent';
      $params['parent'] = $parentId;
    }

    $sql .= ' ORDER BY name ASC';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createService(array $data): array
  {
    $parentId = isset($data['parent_id']) ? (int) $data['parent_id'] : null;
    if ($parentId !== null && $this->wouldCreateCycle('services', null, $parentId)) {
      throw new RuntimeException('HIERARCHY_CYCLE');
    }

    $localId = $this->nextLocalId('services');
    $stmt = $this->pdo->prepare(
      'INSERT INTO services (uuid, business_owner_id, local_id, parent_id, category_id, code, name, description, base_rate, cost, is_group, created_at)
       VALUES (:uuid, :owner, :local_id, :parent, :cat, :code, :name, :desc, :rate, :cost, :grp, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'local_id' => $localId,
      'parent' => $parentId,
      'cat' => $data['category_id'] ?? null,
      'code' => $data['code'] ?? null,
      'name' => $data['name'],
      'desc' => $data['description'] ?? null,
      'rate' => $data['base_rate'] ?? 0,
      'cost' => $data['cost'] ?? 0,
      'grp' => !empty($data['is_group']) ? 1 : 0,
    ]);

    return $this->findService((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @param array<string, mixed> $data */
  public function updateService(int $id, array $data): ?array
  {
    $existing = $this->findService($id);
    if ($existing === null) {
      return null;
    }

    if (array_key_exists('parent_id', $data)) {
      $parentId = $data['parent_id'] !== null ? (int) $data['parent_id'] : null;
      if ($parentId === $id || ($parentId !== null && $this->wouldCreateCycle('services', $id, $parentId))) {
        throw new RuntimeException('HIERARCHY_CYCLE');
      }
    }

    $fields = [];
    $params = ['id' => $id, 'owner' => $this->businessOwnerId];
    foreach (['parent_id', 'category_id', 'code', 'name', 'description', 'base_rate', 'cost', 'is_group', 'is_active'] as $field) {
      if (array_key_exists($field, $data)) {
        $fields[] = "{$field} = :{$field}";
        $params[$field] = $field === 'is_group' || $field === 'is_active' ? (!empty($data[$field]) ? 1 : 0) : $data[$field];
      }
    }
    if ($fields === []) {
      return $existing;
    }
    $fields[] = 'updated_at = UTC_TIMESTAMP()';
    $sql = 'UPDATE services SET ' . implode(', ', $fields) . ' WHERE id = :id AND business_owner_id = :owner';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $this->findService($id);
  }

  /** @param array<string, mixed> $data */
  public function createProduct(array $data): array
  {
    $parentId = isset($data['parent_id']) ? (int) $data['parent_id'] : null;
    if ($parentId !== null && $this->wouldCreateCycle('products', null, $parentId)) {
      throw new RuntimeException('HIERARCHY_CYCLE');
    }

    $localId = $this->nextLocalId('products');
    $stmt = $this->pdo->prepare(
      'INSERT INTO products (uuid, business_owner_id, local_id, parent_id, category_id, code, name, description, barcode, base_rate, cost, stock_quantity, low_stock_threshold, is_group, created_at)
       VALUES (:uuid, :owner, :local_id, :parent, :cat, :code, :name, :desc, :barcode, :rate, :cost, :stock, :low, :grp, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'owner' => $this->businessOwnerId,
      'local_id' => $localId,
      'parent' => $parentId,
      'cat' => $data['category_id'] ?? null,
      'code' => $data['code'] ?? null,
      'name' => $data['name'],
      'desc' => $data['description'] ?? null,
      'barcode' => $data['barcode'] ?? null,
      'rate' => $data['base_rate'] ?? 0,
      'cost' => $data['cost'] ?? 0,
      'stock' => $data['stock_quantity'] ?? 0,
      'low' => $data['low_stock_threshold'] ?? 0,
      'grp' => !empty($data['is_group']) ? 1 : 0,
    ]);

    return $this->findProduct((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @param array<string, mixed> $data */
  public function updateProduct(int $id, array $data): ?array
  {
    $existing = $this->findProduct($id);
    if ($existing === null) {
      return null;
    }

    if (array_key_exists('parent_id', $data)) {
      $parentId = $data['parent_id'] !== null ? (int) $data['parent_id'] : null;
      if ($parentId === $id || ($parentId !== null && $this->wouldCreateCycle('products', $id, $parentId))) {
        throw new RuntimeException('HIERARCHY_CYCLE');
      }
    }

    $fields = [];
    $params = ['id' => $id, 'owner' => $this->businessOwnerId];
    foreach (['parent_id', 'category_id', 'code', 'name', 'description', 'barcode', 'base_rate', 'cost', 'stock_quantity', 'low_stock_threshold', 'is_group', 'is_active'] as $field) {
      if (array_key_exists($field, $data)) {
        $fields[] = "{$field} = :{$field}";
        $params[$field] = in_array($field, ['is_group', 'is_active'], true) ? (!empty($data[$field]) ? 1 : 0) : $data[$field];
      }
    }
    if ($fields === []) {
      return $existing;
    }
    $fields[] = 'updated_at = UTC_TIMESTAMP()';
    $sql = 'UPDATE products SET ' . implode(', ', $fields) . ' WHERE id = :id AND business_owner_id = :owner';
    $stmt = $this->pdo->prepare($sql);
    $stmt->execute($params);

    return $this->findProduct($id);
  }

  /** @return array<int, array<string, mixed>> */
  public function listServiceProducts(int $serviceId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT spm.*, p.name AS product_name, p.code AS product_code
       FROM service_product_map spm
       JOIN services s ON s.id = spm.service_id
       JOIN products p ON p.id = spm.product_id
       WHERE spm.service_id = :service AND s.business_owner_id = :owner AND spm.is_active = 1'
    );
    $stmt->execute(['service' => $serviceId, 'owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function attachProduct(int $serviceId, array $data): array
  {
    if ($this->findService($serviceId) === null) {
      throw new RuntimeException('NOT_FOUND');
    }
    $productId = (int) ($data['product_id'] ?? 0);
    if ($productId <= 0 || $this->findProduct($productId) === null) {
      throw new RuntimeException('VALIDATION_ERROR');
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO service_product_map (service_id, product_id, default_qty, is_default, is_active)
       VALUES (:service, :product, :qty, :def, 1)
       ON DUPLICATE KEY UPDATE default_qty = VALUES(default_qty), is_default = VALUES(is_default), is_active = 1'
    );
    $stmt->execute([
      'service' => $serviceId,
      'product' => $productId,
      'qty' => $data['default_qty'] ?? 1,
      'def' => !empty($data['is_default']) ? 1 : 0,
    ]);

    return ['service_id' => $serviceId, 'product_id' => $productId];
  }

  public function detachProduct(int $serviceId, int $productId): bool
  {
    $stmt = $this->pdo->prepare(
      'UPDATE service_product_map SET is_active = 0 WHERE service_id = :service AND product_id = :product'
    );
    $stmt->execute(['service' => $serviceId, 'product' => $productId]);

    return $stmt->rowCount() > 0;
  }

  /** @return array<int, array<string, mixed>> */
  public function listServiceModifiers(int $serviceId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT sm.* FROM service_modifiers sm
       JOIN services s ON s.id = sm.service_id
       WHERE sm.service_id = :service AND s.business_owner_id = :owner AND sm.is_active = 1'
    );
    $stmt->execute(['service' => $serviceId, 'owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createServiceModifier(int $serviceId, array $data): array
  {
    if ($this->findService($serviceId) === null) {
      throw new RuntimeException('NOT_FOUND');
    }
    $name = (string) ($data['name'] ?? '');
    if (trim($name) === '') {
      throw new RuntimeException('VALIDATION_ERROR');
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO service_modifiers (uuid, service_id, name, extra_rate, created_at)
       VALUES (:uuid, :service, :name, :rate, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'service' => $serviceId,
      'name' => $name,
      'rate' => $data['extra_rate'] ?? 0,
    ]);

    return $this->findServiceModifier((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @return array<int, array<string, mixed>> */
  public function listProductModifiers(int $productId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT pm.* FROM product_modifiers pm
       JOIN products p ON p.id = pm.product_id
       WHERE pm.product_id = :product AND p.business_owner_id = :owner AND pm.is_active = 1'
    );
    $stmt->execute(['product' => $productId, 'owner' => $this->businessOwnerId]);

    return $stmt->fetchAll() ?: [];
  }

  /** @param array<string, mixed> $data */
  public function createProductModifier(int $productId, array $data): array
  {
    if ($this->findProduct($productId) === null) {
      throw new RuntimeException('NOT_FOUND');
    }
    $name = (string) ($data['name'] ?? '');
    if (trim($name) === '') {
      throw new RuntimeException('VALIDATION_ERROR');
    }

    $stmt = $this->pdo->prepare(
      'INSERT INTO product_modifiers (uuid, product_id, name, extra_rate, created_at)
       VALUES (:uuid, :product, :name, :rate, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'uuid' => $this->uuid(),
      'product' => $productId,
      'name' => $name,
      'rate' => $data['extra_rate'] ?? 0,
    ]);

    return $this->findProductModifier((int) $this->pdo->lastInsertId()) ?? [];
  }

  /** @return array<int, array<string, mixed>> */
  public function getServiceProductMap(int $serviceId): array
  {
    $stmt = $this->pdo->prepare(
      'SELECT spm.*, p.name, p.stock_quantity FROM service_product_map spm
       JOIN products p ON p.id = spm.product_id
       WHERE spm.service_id = :service AND spm.is_active = 1'
    );
    $stmt->execute(['service' => $serviceId]);

    return $stmt->fetchAll() ?: [];
  }

  public function findService(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM services WHERE id = :id AND business_owner_id = :owner LIMIT 1');
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  public function findProduct(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM products WHERE id = :id AND business_owner_id = :owner LIMIT 1');
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);

    return $stmt->fetch() ?: null;
  }

  public function findServiceModifier(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM service_modifiers WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $id]);

    return $stmt->fetch() ?: null;
  }

  public function findProductModifier(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM product_modifiers WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $id]);

    return $stmt->fetch() ?: null;
  }

  public function wouldCreateCycle(string $table, ?int $nodeId, int $parentId): bool
  {
    if ($nodeId !== null && $parentId === $nodeId) {
      return true;
    }

    $visited = [];
    $current = $parentId;
    while ($current !== null) {
      if ($nodeId !== null && $current === $nodeId) {
        return true;
      }
      if (isset($visited[$current])) {
        return true;
      }
      $visited[$current] = true;
      $stmt = $this->pdo->prepare("SELECT parent_id FROM {$table} WHERE id = :id AND business_owner_id = :owner LIMIT 1");
      $stmt->execute(['id' => $current, 'owner' => $this->businessOwnerId]);
      $row = $stmt->fetch();
      $current = $row && $row['parent_id'] !== null ? (int) $row['parent_id'] : null;
    }

    return false;
  }

  private function nextLocalId(string $table): int
  {
    $stmt = $this->pdo->prepare("SELECT COALESCE(MAX(local_id), 0) + 1 FROM {$table} WHERE business_owner_id = :owner");
    $stmt->execute(['owner' => $this->businessOwnerId]);

    return (int) $stmt->fetchColumn();
  }

  private function uuid(): string
  {
    $data = random_bytes(16);
    $data[6] = chr((ord($data[6]) & 0x0f) | 0x40);
    $data[8] = chr((ord($data[8]) & 0x3f) | 0x80);

    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($data), 4));
  }
}
