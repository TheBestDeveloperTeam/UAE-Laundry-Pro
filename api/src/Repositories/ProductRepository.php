<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;

class ProductRepository
{
    public function __construct(
        private readonly PDO $db
    ) {
    }

    /**
     * Get all products for a given admin_id, including their dynamic details.
     */
    public function getAll(int $adminId, bool $activeOnly = true): array
    {
        $sql = "SELECT p.* FROM products p WHERE p.admin_id = :admin_id AND p.deleted_at IS NULL";
        if ($activeOnly) {
            $sql .= " AND p.is_active = 1";
        }
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute(['admin_id' => $adminId]);
        $products = $stmt->fetchAll(PDO::FETCH_ASSOC);

        if (empty($products)) {
            return [];
        }

        // Fetch details (EAV)
        $productIds = array_column($products, 'id');
        $placeholders = str_repeat('?,', count($productIds) - 1) . '?';
        
        $detailSql = "SELECT product_id, field_key, field_value 
                      FROM product_details 
                      WHERE admin_id = ? AND product_id IN ($placeholders)";
                      
        $detailStmt = $this->db->prepare($detailSql);
        $params = array_merge([$adminId], $productIds);
        $detailStmt->execute($params);
        $details = $detailStmt->fetchAll(PDO::FETCH_ASSOC);

        // Group details by product_id
        $detailsByProduct = [];
        foreach ($details as $row) {
            $detailsByProduct[$row['product_id']][$row['field_key']] = $row['field_value'];
        }

        // Merge details into products
        foreach ($products as &$product) {
            $product['details'] = $detailsByProduct[$product['id']] ?? [];
            // Cast numeric strings where appropriate
            $product['default_rate'] = (float) $product['default_rate'];
            $product['is_active'] = (bool) $product['is_active'];
        }

        return $products;
    }

    /**
     * Create a new product along with its dynamic details.
     */
    public function create(int $adminId, array $data, array $details): array
    {
        try {
            $this->db->beginTransaction();

            $uuid = Uuid::v4();
            $rowUuid = Uuid::v4();

            $sql = "INSERT INTO products (uuid, admin_id, row_uuid, category_id, name, default_rate, stock_class, is_active)
                    VALUES (:uuid, :admin_id, :row_uuid, :category_id, :name, :default_rate, :stock_class, :is_active)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => $uuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'category_id' => $data['category_id'] ?? null,
                'name' => $data['name'],
                'default_rate' => $data['default_rate'] ?? '0.00',
                'stock_class' => $data['stock_class'] ?? 'retail',
                'is_active' => $data['is_active'] ?? 1,
            ]);

            $productId = (int) $this->db->lastInsertId();

            if (!empty($details)) {
                $detailSql = "INSERT INTO product_details (uuid, admin_id, row_uuid, product_id, field_key, field_value)
                              VALUES (:uuid, :admin_id, :row_uuid, :product_id, :field_key, :field_value)";
                $detailStmt = $this->db->prepare($detailSql);

                foreach ($details as $key => $value) {
                    $detailStmt->execute([
                        'uuid' => Uuid::v4(),
                        'admin_id' => $adminId,
                        'row_uuid' => Uuid::v4(),
                        'product_id' => $productId,
                        'field_key' => $key,
                        'field_value' => (string) $value,
                    ]);
                }
            }

            // Sync outbox insertion logic would be triggered via EventBus in Controller/Service
            $this->db->commit();

            return ['id' => $productId, 'uuid' => $uuid];
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Failed to create product: " . $e->getMessage(), 0, $e);
        }
    }
}
