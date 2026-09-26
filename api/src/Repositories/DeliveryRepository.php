<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class DeliveryRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly EventBus $eventBus
    ) {
    }

    /**
     * Schedule a new pickup or delivery task
     */
    public function scheduleTask(int $adminId, array $taskData, array $lines = []): array
    {
        try {
            $this->db->beginTransaction();

            $taskUuid = Uuid::v4();
            $rowUuid = Uuid::v4();

            $taskType = $taskData['task_type'];
            if (!in_array($taskType, ['pickup', 'delivery'])) {
                throw new InvalidArgumentException("Invalid task_type");
            }

            $sql = "INSERT INTO delivery_tasks (uuid, admin_id, row_uuid, task_type, order_id, customer_id, driver_id, scheduled_date, scheduled_time_slot, address, latitude, longitude, notes)
                    VALUES (:uuid, :admin_id, :row_uuid, :task_type, :order_id, :customer_id, :driver_id, :scheduled_date, :scheduled_time_slot, :address, :latitude, :longitude, :notes)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => $taskUuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'task_type' => $taskType,
                'order_id' => $taskData['order_id'] ?? null,
                'customer_id' => $taskData['customer_id'],
                'driver_id' => $taskData['driver_id'] ?? null,
                'scheduled_date' => $taskData['scheduled_date'],
                'scheduled_time_slot' => $taskData['scheduled_time_slot'] ?? null,
                'address' => $taskData['address'],
                'latitude' => $taskData['latitude'] ?? null,
                'longitude' => $taskData['longitude'] ?? null,
                'notes' => $taskData['notes'] ?? null,
            ]);

            $taskId = (int) $this->db->lastInsertId();

            if (!empty($lines)) {
                $lineSql = "INSERT INTO delivery_task_lines (uuid, admin_id, row_uuid, task_id, item_description, quantity)
                            VALUES (:uuid, :admin_id, :row_uuid, :task_id, :item_description, :quantity)";
                $lineStmt = $this->db->prepare($lineSql);
                
                foreach ($lines as $line) {
                    $lineStmt->execute([
                        'uuid' => Uuid::v4(),
                        'admin_id' => $adminId,
                        'row_uuid' => Uuid::v4(),
                        'task_id' => $taskId,
                        'item_description' => $line['item_description'],
                        'quantity' => (int)($line['quantity'] ?? 1)
                    ]);
                }
            }

            $this->eventBus->publish('delivery.task.scheduled', [
                'admin_id' => $adminId,
                'task_id' => $taskId,
                'row_uuid' => $rowUuid
            ]);

            $this->db->commit();

            return ['id' => $taskId, 'uuid' => $taskUuid];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Task scheduling failed: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Update Task Status
     */
    public function updateStatus(int $adminId, int $taskId, string $status, ?string $failureReason = null): void
    {
        $allowed = ['pending', 'assigned', 'in_transit', 'completed', 'failed', 'cancelled'];
        if (!in_array($status, $allowed)) {
            throw new InvalidArgumentException("Invalid status");
        }

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT status FROM delivery_tasks WHERE id = ? AND admin_id = ? FOR UPDATE");
            $stmt->execute([$taskId, $adminId]);
            $currentStatus = $stmt->fetchColumn();

            if (!$currentStatus) throw new InvalidArgumentException("Task not found");

            $completedAt = ($status === 'completed' || $status === 'failed') ? date('Y-m-d H:i:s') : null;

            $upd = $this->db->prepare("UPDATE delivery_tasks SET status = ?, failure_reason = ?, completed_at = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?");
            $upd->execute([$status, $failureReason, $completedAt, $taskId]);

            $this->eventBus->publish('delivery.task.status_updated', [
                'admin_id' => $adminId,
                'task_id' => $taskId,
                'status' => $status
            ]);

            $this->db->commit();
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }
}
