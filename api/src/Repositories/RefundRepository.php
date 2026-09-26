<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Money;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class RefundRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly EventBus $eventBus,
        private readonly InventoryRepository $inventoryRepo
    ) {
    }

    /**
     * Create a new refund/credit memo for an order.
     */
    public function createRefund(int $adminId, array $memoData, array $lines, int $userId = null): array
    {
        try {
            $this->db->beginTransaction();

            $memoUuid = Uuid::v4();
            $rowUuid = Uuid::v4();
            
            $refOrderId = (int) $memoData['ref_order_id'];

            // Validate order exists and belongs to admin
            $orderStmt = $this->db->prepare("SELECT * FROM sales_orders WHERE id = ? AND admin_id = ? FOR UPDATE");
            $orderStmt->execute([$refOrderId, $adminId]);
            $order = $orderStmt->fetch(PDO::FETCH_ASSOC);

            if (!$order) {
                throw new InvalidArgumentException("Referenced sales order not found");
            }

            if ($order['status'] === 'void' || $order['status'] === 'refunded') {
                throw new InvalidArgumentException("Order is already voided or refunded");
            }

            $consumerId = $order['consumer_id'];
            $branchId = $order['branch_id'];

            $status = $memoData['status'] ?? 'approved';

            $subtotal = new Money('0.00');
            $taxTotal = new Money('0.00');
            $processedLines = [];

            foreach ($lines as $line) {
                $qty = new Money((string)$line['quantity_refunded']);
                $unitPrice = new Money((string)$line['unit_price']);
                $taxRate = new Money((string)($line['tax_rate'] ?? '0.00'));
                
                $lineSubtotal = $unitPrice->multiply($qty->getAmount());
                $taxFraction = $taxRate->divide('100');
                $lineTax = $lineSubtotal->multiply($taxFraction->getAmount());
                $lineTotal = $lineSubtotal->add($lineTax);
                
                $subtotal = $subtotal->add($lineSubtotal);
                $taxTotal = $taxTotal->add($lineTax);
                
                $returnToStock = isset($line['return_to_stock']) && $line['return_to_stock'] ? 1 : 0;
                
                $processedLines[] = [
                    'uuid' => Uuid::v4(),
                    'row_uuid' => Uuid::v4(),
                    'ref_order_line_id' => $line['ref_order_line_id'] ?? null,
                    'product_id' => $line['product_id'] ?? null,
                    'item_name' => $line['item_name'],
                    'quantity_refunded' => $qty->getAmount(),
                    'unit_price' => $unitPrice->getAmount(),
                    'tax_rate' => $taxRate->getAmount(),
                    'line_subtotal' => $lineSubtotal->getAmount(),
                    'line_tax' => $lineTax->getAmount(),
                    'line_total' => $lineTotal->getAmount(),
                    'return_to_stock' => $returnToStock,
                ];

                // If returning to stock, reverse the inventory movement (adjustStock positive)
                if ($returnToStock && isset($line['product_id']) && $branchId) {
                    $this->inventoryRepo->adjustStock(
                        $adminId,
                        (int)$line['product_id'],
                        (int)$branchId,
                        (float)$qty->getAmount(),
                        'adjustment',
                        $userId,
                        'credit_memo',
                        null,
                        'Returned to stock on refund'
                    );
                }
            }

            $grandTotal = $subtotal->add($taxTotal);

            $memoNumber = $this->generateMemoNumber($adminId);

            $sql = "INSERT INTO credit_memos (uuid, admin_id, row_uuid, memo_number, ref_order_id, consumer_id, branch_id, status, subtotal, tax_total, grand_total, reason, created_by_user_id)
                    VALUES (:uuid, :admin_id, :row_uuid, :memo_number, :ref_order_id, :consumer_id, :branch_id, :status, :subtotal, :tax_total, :grand_total, :reason, :user_id)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => $memoUuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'memo_number' => $memoNumber,
                'ref_order_id' => $refOrderId,
                'consumer_id' => $consumerId,
                'branch_id' => $branchId,
                'status' => $status,
                'subtotal' => $subtotal->getAmount(),
                'tax_total' => $taxTotal->getAmount(),
                'grand_total' => $grandTotal->getAmount(),
                'reason' => $memoData['reason'] ?? null,
                'user_id' => $userId,
            ]);

            $memoId = (int) $this->db->lastInsertId();

            $lineSql = "INSERT INTO credit_memo_lines (uuid, admin_id, row_uuid, memo_id, ref_order_line_id, product_id, item_name, quantity_refunded, unit_price, tax_rate, line_subtotal, line_tax, line_total, return_to_stock)
                        VALUES (:uuid, :admin_id, :row_uuid, :memo_id, :ref_order_line_id, :product_id, :item_name, :quantity_refunded, :unit_price, :tax_rate, :line_subtotal, :line_tax, :line_total, :return_to_stock)";
            $lineStmt = $this->db->prepare($lineSql);
            
            foreach ($processedLines as $pl) {
                $pl['memo_id'] = $memoId;
                $pl['admin_id'] = $adminId;
                $lineStmt->execute($pl);
            }

            // Update order status if full refund
            if (isset($memoData['is_full_refund']) && $memoData['is_full_refund']) {
                $updateOrderStmt = $this->db->prepare("UPDATE sales_orders SET status = 'refunded' WHERE id = ?");
                $updateOrderStmt->execute([$refOrderId]);
            }

            $this->eventBus->publish('sales.refund.created', [
                'admin_id' => $adminId,
                'memo_id' => $memoId,
                'row_uuid' => $rowUuid
            ]);

            $this->db->commit();

            return [
                'id' => $memoId,
                'uuid' => $memoUuid,
                'memo_number' => $memoNumber,
                'grand_total' => $grandTotal->getAmount()
            ];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Refund creation failed: " . $e->getMessage(), 0, $e);
        }
    }

    private function generateMemoNumber(int $adminId): string
    {
        return 'CM-' . date('ymd') . '-' . mt_rand(1000, 9999);
    }
}
