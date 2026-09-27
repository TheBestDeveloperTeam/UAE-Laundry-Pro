<?php
declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;

class RfidRepository
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function processTags(array $tags): array
    {
        // Mock implementation of mapping EPC tags to sales orders and updating their status
        // In a real system, there would be a mapping table like rfid_tag_mappings(epc, order_id)

        $this->pdo->beginTransaction();
        try {
            // For MVP demonstration, any tags processed will transition all 'draft' or 'received' orders to 'processing'
            $stmt = $this->pdo->prepare("
                UPDATE sales_orders
                SET status = 'processing'
                WHERE status IN ('draft', 'received')
            ");
            $stmt->execute();
            $count = $stmt->rowCount();

            $this->pdo->commit();

            return [
                'tags_read' => count($tags),
                'orders_transitioned' => $count
            ];
        } catch (\Exception $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }
}
