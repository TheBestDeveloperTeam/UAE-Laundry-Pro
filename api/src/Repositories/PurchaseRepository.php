<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Money;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class PurchaseRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly EventBus $eventBus,
        private readonly InventoryRepository $inventoryRepo
    ) {
    }

    /**
     * Create a Purchase Order
     */
    public function createPO(int $adminId, array $poData, array $lines, int $userId = null): array
    {
        try {
            $this->db->beginTransaction();

            $poUuid = Uuid::v4();
            $rowUuid = Uuid::v4();
            
            $vendorId = (int)$poData['vendor_id'];
            $branchId = $poData['branch_id'] ?? null;
            $status = $poData['status'] ?? 'draft';

            $subtotal = new Money('0.00');
            $taxTotal = new Money('0.00');
            $processedLines = [];

            foreach ($lines as $line) {
                $qty = new Money((string)$line['quantity_ordered']);
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
                    'product_id' => $line['product_id'],
                    'item_name' => $line['item_name'],
                    'quantity_ordered' => $qty->getAmount(),
                    'unit_price' => $unitPrice->getAmount(),
                    'tax_rate' => $taxRate->getAmount(),
                    'line_subtotal' => $lineSubtotal->getAmount(),
                    'line_tax' => $lineTax->getAmount(),
                    'line_total' => $lineTotal->getAmount(),
                ];
            }

            $grandTotal = $subtotal->add($taxTotal);
            $poNumber = $this->generatePONumber($adminId);

            $sql = "INSERT INTO purchase_orders (uuid, admin_id, row_uuid, po_number, vendor_id, branch_id, status, subtotal, tax_total, grand_total, notes, created_by_user_id)
                    VALUES (:uuid, :admin_id, :row_uuid, :po_number, :vendor_id, :branch_id, :status, :subtotal, :tax_total, :grand_total, :notes, :user_id)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => $poUuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'po_number' => $poNumber,
                'vendor_id' => $vendorId,
                'branch_id' => $branchId,
                'status' => $status,
                'subtotal' => $subtotal->getAmount(),
                'tax_total' => $taxTotal->getAmount(),
                'grand_total' => $grandTotal->getAmount(),
                'notes' => $poData['notes'] ?? null,
                'user_id' => $userId,
            ]);

            $poId = (int) $this->db->lastInsertId();

            $lineSql = "INSERT INTO purchase_order_lines (uuid, admin_id, row_uuid, po_id, product_id, item_name, quantity_ordered, unit_price, tax_rate, line_subtotal, line_tax, line_total)
                        VALUES (:uuid, :admin_id, :row_uuid, :po_id, :product_id, :item_name, :quantity_ordered, :unit_price, :tax_rate, :line_subtotal, :line_tax, :line_total)";
            $lineStmt = $this->db->prepare($lineSql);
            
            foreach ($processedLines as $pl) {
                $pl['po_id'] = $poId;
                $pl['admin_id'] = $adminId;
                $lineStmt->execute($pl);
            }

            $this->eventBus->publish('purchasing.po.created', [
                'admin_id' => $adminId,
                'po_id' => $poId,
                'row_uuid' => $rowUuid
            ]);

            $this->db->commit();

            return [
                'id' => $poId,
                'po_number' => $poNumber,
                'grand_total' => $grandTotal->getAmount()
            ];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("PO creation failed: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Receive PO (Updates stock)
     */
    public function receivePO(int $adminId, int $poId, array $receivedLines, int $userId = null): array
    {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("SELECT * FROM purchase_orders WHERE id = ? AND admin_id = ? FOR UPDATE");
            $stmt->execute([$poId, $adminId]);
            $po = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$po) throw new InvalidArgumentException("PO not found");
            if (in_array($po['status'], ['received', 'cancelled'])) {
                throw new InvalidArgumentException("PO already received or cancelled");
            }

            $branchId = $po['branch_id'];

            foreach ($receivedLines as $line) {
                $polId = (int)$line['pol_id'];
                $qtyReceived = (float)$line['quantity_received'];
                
                // Get PO line
                $lineStmt = $this->db->prepare("SELECT product_id FROM purchase_order_lines WHERE id = ? AND po_id = ?");
                $lineStmt->execute([$polId, $poId]);
                $productId = $lineStmt->fetchColumn();

                if (!$productId) throw new InvalidArgumentException("Invalid PO Line ID");

                // Update PO line received qty
                $updStmt = $this->db->prepare("UPDATE purchase_order_lines SET quantity_received = quantity_received + ? WHERE id = ?");
                $updStmt->execute([$qtyReceived, $polId]);

                // Adjust stock via Inventory Repo if we have a branch (otherwise corporate stock holding)
                if ($branchId) {
                    $this->inventoryRepo->adjustStock(
                        $adminId,
                        (int)$productId,
                        (int)$branchId,
                        $qtyReceived,
                        'receipt',
                        $userId,
                        'purchase_order',
                        $poId,
                        'PO Received'
                    );
                }
            }

            // Check if fully received
            $checkStmt = $this->db->prepare("SELECT COUNT(*) FROM purchase_order_lines WHERE po_id = ? AND quantity_received < quantity_ordered");
            $checkStmt->execute([$poId]);
            $unfulfilled = (int)$checkStmt->fetchColumn();

            $newStatus = $unfulfilled === 0 ? 'received' : 'partially_received';

            $statusStmt = $this->db->prepare("UPDATE purchase_orders SET status = ? WHERE id = ?");
            $statusStmt->execute([$newStatus, $poId]);

            $this->eventBus->publish('purchasing.po.received', [
                'admin_id' => $adminId,
                'po_id' => $poId,
                'status' => $newStatus
            ]);

            $this->db->commit();

            return ['status' => $newStatus];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("PO receipt failed: " . $e->getMessage(), 0, $e);
        }
    }

    private function generatePONumber(int $adminId): string
    {
        return 'PO-' . date('ymd') . '-' . mt_rand(1000, 9999);
    }
}
