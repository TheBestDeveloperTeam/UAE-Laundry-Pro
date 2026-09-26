<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Money;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class SalesRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly CatalogRepository $catalog,
        private readonly InventoryRepository $inventory,
        private readonly SyncOutboxRepository $outbox
    ) {
    }

    /**
     * Create a new sales order (draft or confirmed).
     */
    public function createOrder(int $adminId, array $orderData, array $lines, array $payments = [], int $userId = null): array
    {
        try {
            $this->db->beginTransaction();

            $orderUuid = Uuid::v4();
            $rowUuid = Uuid::v4();
            
            // Resolve Consumer (1 = Walk-In if null)
            $consumerId = $orderData['consumer_id'] ?? 1;

            $status = $orderData['status'] ?? 'draft';
            if (!in_array($status, ['draft', 'confirmed', 'paid'])) {
                throw new InvalidArgumentException("Invalid initial status: {$status}");
            }

            // Calculate Totals using strict Money class
            $subtotal = new Money('0.00');
            $taxTotal = new Money('0.00');
            $processedLines = [];

            foreach ($lines as $line) {
                $qty = new Money((string)$line['quantity']);
                $unitPrice = new Money((string)$line['unit_price']);
                $taxRate = new Money((string)($line['tax_rate'] ?? '0.00'));
                
                $lineSubtotal = $unitPrice->multiply($qty->getAmount());
                
                $taxFraction = $taxRate->divide('100');
                $lineTax = $lineSubtotal->multiply($taxFraction->getAmount());
                
                $lineTotal = $lineSubtotal->add($lineTax);
                
                $subtotal = $subtotal->add($lineSubtotal);
                $taxTotal = $taxTotal->add($lineTax);
                
                $processedLines[] = [
                    'uuid' => Uuid::v4(),
                    'row_uuid' => Uuid::v4(),
                    'service_id' => $line['service_id'] ?? null,
                    'product_id' => $line['product_id'] ?? null,
                    'item_name' => $line['item_name'],
                    'quantity' => $qty->getAmount(),
                    'unit_price' => $unitPrice->getAmount(),
                    'tax_rate' => $taxRate->getAmount(),
                    'line_subtotal' => $lineSubtotal->getAmount(),
                    'line_tax' => $lineTax->getAmount(),
                    'line_total' => $lineTotal->getAmount(),
                ];
            }

            $discountTotal = new Money((string)($orderData['discount_amount'] ?? '0.00'));
            
            // if there's a percentage discount, apply it to the subtotal before taxes
            if (!empty($orderData['discount_percentage'])) {
                $discountPercent = new Money((string)$orderData['discount_percentage']);
                $pctFraction = $discountPercent->divide('100');
                $pctDiscountValue = $subtotal->multiply($pctFraction->getAmount());
                $discountTotal = $discountTotal->add($pctDiscountValue);
            }
            
            // Compute grand total: (Subtotal - Discount) + Tax
            // But wait, tax was calculated on line Subtotals!
            // If discount is applied at the order level, tax should technically be recalculated,
            // or we just apply discount to the subtotal+tax (Grand Total).
            // Let's stick to standard formula: Subtotal + Tax - Discount.
            // But ensure discount doesn't exceed Subtotal + Tax.
            $grossTotal = $subtotal->add($taxTotal);
            if ($discountTotal->greaterThan($grossTotal)) {
                $discountTotal = clone $grossTotal;
            }
            
            $grandTotal = $grossTotal->subtract($discountTotal);
            
            $paidAmount = new Money('0.00');
            $processedPayments = [];
            
            foreach ($payments as $payment) {
                $payAmount = new Money((string)$payment['amount']);
                $paidAmount = $paidAmount->add($payAmount);
                $processedPayments[] = [
                    'uuid' => Uuid::v4(),
                    'row_uuid' => Uuid::v4(),
                    'tender_type' => $payment['tender_type'],
                    'amount' => $payAmount->getAmount(),
                    'reference_code' => $payment['reference_code'] ?? null,
                ];
            }

            // Enforce Split Payment rule exactly
            if ($status === 'paid' && !$paidAmount->equals($grandTotal)) {
                throw new InvalidArgumentException(
                    "Split payment mismatch: Sum of tenders ({$paidAmount}) must equal Grand Total ({$grandTotal})"
                );
            }

            $orderNumber = $this->generateOrderNumber($adminId);

            $sql = "INSERT INTO sales_orders (uuid, admin_id, row_uuid, order_number, consumer_id, branch_id, status, subtotal, tax_total, discount_total, grand_total, paid_amount, hold_note, created_by_user_id)
                    VALUES (:uuid, :admin_id, :row_uuid, :order_number, :consumer_id, :branch_id, :status, :subtotal, :tax_total, :discount_total, :grand_total, :paid_amount, :hold_note, :user_id)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => $orderUuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'order_number' => $orderNumber,
                'consumer_id' => $consumerId,
                'branch_id' => $orderData['branch_id'] ?? null,
                'status' => $status,
                'subtotal' => $subtotal->getAmount(),
                'tax_total' => $taxTotal->getAmount(),
                'discount_total' => $discountTotal->getAmount(),
                'grand_total' => $grandTotal->getAmount(),
                'paid_amount' => $paidAmount->getAmount(),
                'hold_note' => $orderData['hold_note'] ?? null,
                'user_id' => $userId,
            ]);

            $orderId = (int) $this->db->lastInsertId();

            $lineSql = "INSERT INTO sales_order_lines (uuid, admin_id, row_uuid, order_id, service_id, product_id, item_name, quantity, unit_price, tax_rate, line_subtotal, line_tax, line_total)
                        VALUES (:uuid, :admin_id, :row_uuid, :order_id, :service_id, :product_id, :item_name, :quantity, :unit_price, :tax_rate, :line_subtotal, :line_tax, :line_total)";
            $lineStmt = $this->db->prepare($lineSql);
            
            foreach ($processedLines as $pl) {
                $pl['order_id'] = $orderId;
                $pl['admin_id'] = $adminId;
                $lineStmt->execute($pl);
            }

            if (!empty($processedPayments)) {
                $paySql = "INSERT INTO payment_transactions (uuid, admin_id, row_uuid, order_id, tender_type, amount, reference_code)
                           VALUES (:uuid, :admin_id, :row_uuid, :order_id, :tender_type, :amount, :reference_code)";
                $payStmt = $this->db->prepare($paySql);
                
                foreach ($processedPayments as $pp) {
                    $pp['order_id'] = $orderId;
                    $pp['admin_id'] = $adminId;
                    $payStmt->execute($pp);
                }
            }

            $this->outbox->enqueue($adminId, 'sales_order', $orderId, 'create', [
                'uuid' => $orderUuid,
                'status' => $status
            ]);

            $this->db->commit();

            return [
                'id' => $orderId,
                'uuid' => $orderUuid,
                'order_number' => $orderNumber,
                'grand_total' => $grandTotal->getAmount()
            ];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Order creation failed: " . $e->getMessage(), 0, $e);
        }
    }

    public function getOrder(int $adminId, int $orderId): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM sales_orders WHERE id = ? AND admin_id = ?");
        $stmt->execute([$orderId, $adminId]);
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$order) return null;

        $lineStmt = $this->db->prepare("SELECT * FROM sales_order_lines WHERE order_id = ? AND admin_id = ?");
        $lineStmt->execute([$orderId, $adminId]);
        $order['lines'] = $lineStmt->fetchAll(PDO::FETCH_ASSOC);

        $payStmt = $this->db->prepare("SELECT * FROM payment_transactions WHERE order_id = ? AND admin_id = ?");
        $payStmt->execute([$orderId, $adminId]);
        $order['payments'] = $payStmt->fetchAll(PDO::FETCH_ASSOC);

        return $order;
    }

    public function updateStatus(int $adminId, int $orderId, string $newStatus, int $userId = null): void
    {
        $allowedTransitions = [
            'draft' => ['confirmed', 'void'],
            'confirmed' => ['in_production', 'void'],
            'in_production' => ['ready', 'void'],
            'ready' => ['delivered', 'void'],
            'delivered' => ['paid', 'refunded'],
            'paid' => ['refunded'],
            'void' => [],
            'refunded' => []
        ];

        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT status FROM sales_orders WHERE id = ? AND admin_id = ? FOR UPDATE");
            $stmt->execute([$orderId, $adminId]);
            $currentStatus = $stmt->fetchColumn();

            if (!$currentStatus) throw new InvalidArgumentException("Order not found");
            if (!in_array($newStatus, $allowedTransitions[$currentStatus] ?? [])) {
                throw new InvalidArgumentException("Invalid status transition from $currentStatus to $newStatus");
            }

            $upd = $this->db->prepare("UPDATE sales_orders SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?");
            $upd->execute([$newStatus, $orderId]);

            $hist = $this->db->prepare("INSERT INTO order_status_history (uuid, admin_id, row_uuid, order_id, from_status, to_status, changed_by_user_id) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $hist->execute([Uuid::v4(), $adminId, Uuid::v4(), $orderId, $currentStatus, $newStatus, $userId]);

            $this->outbox->enqueue($adminId, 'sales_order', $orderId, 'update_status', [
                'status' => $newStatus
            ]);

            $this->db->commit();
        } catch (\Exception $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    private function generateOrderNumber(int $adminId): string
    {
        return 'ORD-' . date('ymd') . '-' . mt_rand(1000, 9999);
    }
}
