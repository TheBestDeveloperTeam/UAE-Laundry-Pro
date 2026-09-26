<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class InventoryRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly SyncOutboxRepository $outbox
    ) {
    }

    /**
     * View stock balance for a product at a specific branch
     */
    public function getBalance(int $adminId, int $productId, int $branchId): float
    {
        $stmt = $this->db->prepare(
            "SELECT current_stock FROM inventory_balances WHERE admin_id = ? AND product_id = ? AND branch_id = ?"
        );
        $stmt->execute([$adminId, $productId, $branchId]);
        $stock = $stmt->fetchColumn();
        return $stock !== false ? (float)$stock : 0.0;
    }

    /**
     * Adjust stock concurrency safely using SELECT ... FOR UPDATE
     */
    public function adjustStock(int $adminId, int $productId, int $branchId, float $quantityChange, string $type, ?int $userId = null, ?string $referenceType = null, ?int $referenceId = null, ?string $notes = null): array
    {
        $allowedTypes = ['receipt', 'sale', 'adjustment', 'transfer_in', 'transfer_out', 'spoilage'];
        if (!in_array($type, $allowedTypes)) {
            throw new InvalidArgumentException("Invalid movement type: {$type}");
        }

        try {
            $this->db->beginTransaction();

            // Lock row
            $stmt = $this->db->prepare(
                "SELECT current_stock FROM inventory_balances WHERE admin_id = ? AND product_id = ? AND branch_id = ? FOR UPDATE"
            );
            $stmt->execute([$adminId, $productId, $branchId]);
            $currentStock = $stmt->fetchColumn();

            $balanceUuid = Uuid::v4();
            if ($currentStock === false) {
                // Initialize balance if not exists
                $currentStock = 0.0;
                $initStmt = $this->db->prepare(
                    "INSERT INTO inventory_balances (product_id, branch_id, admin_id, uuid, row_uuid, current_stock) VALUES (?, ?, ?, ?, ?, ?)"
                );
                $initStmt->execute([$productId, $branchId, $adminId, $balanceUuid, Uuid::v4(), 0.0]);
            } else {
                $currentStock = (float)$currentStock;
            }

            $newBalance = $currentStock + $quantityChange;

            // Enforce Insufficient Stock Exception
            if ($newBalance < 0 && $type === 'sale') {
                throw new RuntimeException("INSUFFICIENT_STOCK");
            }

            // Update balance
            $updateStmt = $this->db->prepare(
                "UPDATE inventory_balances SET current_stock = ?, updated_at = CURRENT_TIMESTAMP WHERE admin_id = ? AND product_id = ? AND branch_id = ?"
            );
            $updateStmt->execute([$newBalance, $adminId, $productId, $branchId]);

            // Log movement
            $movementUuid = Uuid::v4();
            $rowUuid = Uuid::v4();
            $logStmt = $this->db->prepare(
                "INSERT INTO inventory_movements (uuid, admin_id, row_uuid, product_id, branch_id, movement_type, quantity_change, balance_after, reference_type, reference_id, notes, created_by_user_id) 
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
            );
            $logStmt->execute([
                $movementUuid, $adminId, $rowUuid, $productId, $branchId, $type, $quantityChange, $newBalance, $referenceType, $referenceId, $notes, $userId
            ]);

            $movementId = (int)$this->db->lastInsertId();

            // Trigger sync hook
            $this->outbox->enqueue($adminId, 'inventory_movement', $movementId, 'create', [
                'row_uuid' => $rowUuid
            ]);

            $this->db->commit();

            return [
                'movement_id' => $movementId,
                'uuid' => $movementUuid,
                'previous_stock' => $currentStock,
                'new_stock' => $newBalance
            ];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }
}
