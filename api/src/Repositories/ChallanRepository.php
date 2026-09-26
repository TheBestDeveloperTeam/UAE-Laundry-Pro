<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class ChallanRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly EventBus $eventBus
    ) {
    }

    /**
     * Create a Challan Draft
     */
    public function createDraft(int $adminId, array $challanData, array $orderIds, int $userId = null): array
    {
        try {
            $this->db->beginTransaction();

            $challanUuid = Uuid::v4();
            $rowUuid = Uuid::v4();
            $challanNumber = $this->generateChallanNumber($adminId);

            $sourceBranchId = (int)$challanData['source_branch_id'];
            $destBranchId = (int)$challanData['destination_branch_id'];

            // Validate all orders belong to admin and are in 'processing' status
            $placeholders = str_repeat('?,', count($orderIds) - 1) . '?';
            $stmt = $this->db->prepare("SELECT id, status FROM sales_orders WHERE admin_id = ? AND id IN ($placeholders)");
            $params = array_merge([$adminId], $orderIds);
            $stmt->execute($params);
            $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

            if (count($orders) !== count($orderIds)) {
                throw new InvalidArgumentException("Some orders are invalid or belong to another tenant.");
            }

            foreach ($orders as $o) {
                if ($o['status'] !== 'processing') {
                    throw new InvalidArgumentException("Order {$o['id']} is not in 'processing' status.");
                }
            }

            $sql = "INSERT INTO challans (uuid, admin_id, row_uuid, challan_number, source_branch_id, destination_branch_id, status, notes)
                    VALUES (:uuid, :admin_id, :row_uuid, :challan_number, :source_branch_id, :destination_branch_id, :status, :notes)";
            
            $insertStmt = $this->db->prepare($sql);
            $insertStmt->execute([
                'uuid' => $challanUuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'challan_number' => $challanNumber,
                'source_branch_id' => $sourceBranchId,
                'destination_branch_id' => $destBranchId,
                'status' => 'draft',
                'notes' => $challanData['notes'] ?? null,
            ]);

            $challanId = (int) $this->db->lastInsertId();

            $lineSql = "INSERT INTO challan_lines (uuid, admin_id, row_uuid, challan_id, order_id, item_count)
                        VALUES (:uuid, :admin_id, :row_uuid, :challan_id, :order_id, :item_count)";
            $lineStmt = $this->db->prepare($lineSql);

            foreach ($orderIds as $oid) {
                $lineStmt->execute([
                    'uuid' => Uuid::v4(),
                    'admin_id' => $adminId,
                    'row_uuid' => Uuid::v4(),
                    'challan_id' => $challanId,
                    'order_id' => (int)$oid,
                    'item_count' => 1 // Simplified item count abstraction
                ]);
            }

            $this->eventBus->publish('challans.draft.created', [
                'admin_id' => $adminId,
                'challan_id' => $challanId,
                'row_uuid' => $rowUuid
            ]);

            $this->db->commit();

            return [
                'id' => $challanId,
                'challan_number' => $challanNumber
            ];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Challan creation failed: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Dispatch Challan
     */
    public function dispatch(int $adminId, int $challanId, int $userId = null): void
    {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT status FROM challans WHERE id = ? AND admin_id = ? FOR UPDATE");
            $stmt->execute([$challanId, $adminId]);
            $status = $stmt->fetchColumn();

            if (!$status) throw new InvalidArgumentException("Challan not found");
            if ($status !== 'draft') throw new InvalidArgumentException("Only draft challans can be dispatched");

            $updStmt = $this->db->prepare("UPDATE challans SET status = 'dispatched', dispatched_by_user_id = ?, dispatched_at = CURRENT_TIMESTAMP WHERE id = ?");
            $updStmt->execute([$userId, $challanId]);

            $this->eventBus->publish('challans.dispatched', [
                'admin_id' => $adminId,
                'challan_id' => $challanId
            ]);

            $this->db->commit();
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Dispatch failed: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Receive Challan
     */
    public function receive(int $adminId, int $challanId, int $userId = null): void
    {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT status FROM challans WHERE id = ? AND admin_id = ? FOR UPDATE");
            $stmt->execute([$challanId, $adminId]);
            $status = $stmt->fetchColumn();

            if (!$status) throw new InvalidArgumentException("Challan not found");
            if ($status !== 'dispatched') throw new InvalidArgumentException("Only dispatched challans can be received");

            $updStmt = $this->db->prepare("UPDATE challans SET status = 'received', received_by_user_id = ?, received_at = CURRENT_TIMESTAMP WHERE id = ?");
            $updStmt->execute([$userId, $challanId]);

            // Automatically move associated orders to 'ready'
            $ordersStmt = $this->db->prepare("SELECT order_id FROM challan_lines WHERE challan_id = ?");
            $ordersStmt->execute([$challanId]);
            $orderIds = $ordersStmt->fetchAll(PDO::FETCH_COLUMN);

            if (!empty($orderIds)) {
                $placeholders = str_repeat('?,', count($orderIds) - 1) . '?';
                $statusUpdate = $this->db->prepare("UPDATE sales_orders SET status = 'ready' WHERE id IN ($placeholders)");
                $statusUpdate->execute($orderIds);
            }

            $this->eventBus->publish('challans.received', [
                'admin_id' => $adminId,
                'challan_id' => $challanId
            ]);

            $this->db->commit();
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Receive failed: " . $e->getMessage(), 0, $e);
        }
    }

    private function generateChallanNumber(int $adminId): string
    {
        return 'CHL-' . date('ymd') . '-' . mt_rand(1000, 9999);
    }
}
