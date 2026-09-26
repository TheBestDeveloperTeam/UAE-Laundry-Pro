<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Core\Money;
use LaundryPro\Api\Core\Uuid;
use PDO;
use RuntimeException;
use InvalidArgumentException;

class InvoiceRepository
{
    public function __construct(
        private readonly PDO $db,
        private readonly EventBus $eventBus
    ) {
    }

    /**
     * Generate an invoice for a customer
     */
    public function createInvoice(int $adminId, array $invoiceData, array $lines, int $userId = null): array
    {
        try {
            $this->db->beginTransaction();

            $invoiceUuid = Uuid::v4();
            $rowUuid = Uuid::v4();
            $invoiceNumber = $this->generateInvoiceNumber($adminId);

            $customerId = (int)$invoiceData['customer_id'];
            $branchId = $invoiceData['branch_id'] ?? null;
            $status = $invoiceData['status'] ?? 'draft';

            $subtotal = new Money('0.00');
            $taxTotal = new Money('0.00');
            $processedLines = [];

            foreach ($lines as $line) {
                $amount = new Money((string)$line['amount']);
                $taxAmt = new Money((string)($line['tax_amount'] ?? '0.00'));
                $lineTotal = $amount->add($taxAmt);
                
                $subtotal = $subtotal->add($amount);
                $taxTotal = $taxTotal->add($taxAmt);
                
                $processedLines[] = [
                    'uuid' => Uuid::v4(),
                    'row_uuid' => Uuid::v4(),
                    'delivery_task_id' => $line['delivery_task_id'] ?? null,
                    'order_id' => $line['order_id'] ?? null,
                    'description' => $line['description'],
                    'amount' => $amount->getAmount(),
                    'tax_amount' => $taxAmt->getAmount(),
                    'line_total' => $lineTotal->getAmount(),
                ];
            }

            $grandTotal = $subtotal->add($taxTotal);

            $sql = "INSERT INTO invoices (uuid, admin_id, row_uuid, invoice_number, customer_id, branch_id, status, subtotal, tax_total, grand_total, due_date, notes, created_by_user_id)
                    VALUES (:uuid, :admin_id, :row_uuid, :invoice_number, :customer_id, :branch_id, :status, :subtotal, :tax_total, :grand_total, :due_date, :notes, :user_id)";
            
            $stmt = $this->db->prepare($sql);
            $stmt->execute([
                'uuid' => $invoiceUuid,
                'admin_id' => $adminId,
                'row_uuid' => $rowUuid,
                'invoice_number' => $invoiceNumber,
                'customer_id' => $customerId,
                'branch_id' => $branchId,
                'status' => $status,
                'subtotal' => $subtotal->getAmount(),
                'tax_total' => $taxTotal->getAmount(),
                'grand_total' => $grandTotal->getAmount(),
                'due_date' => $invoiceData['due_date'] ?? null,
                'notes' => $invoiceData['notes'] ?? null,
                'user_id' => $userId,
            ]);

            $invoiceId = (int) $this->db->lastInsertId();

            $lineSql = "INSERT INTO invoice_lines (uuid, admin_id, row_uuid, invoice_id, delivery_task_id, order_id, description, amount, tax_amount, line_total)
                        VALUES (:uuid, :admin_id, :row_uuid, :invoice_id, :delivery_task_id, :order_id, :description, :amount, :tax_amount, :line_total)";
            $lineStmt = $this->db->prepare($lineSql);
            
            foreach ($processedLines as $pl) {
                $pl['invoice_id'] = $invoiceId;
                $pl['admin_id'] = $adminId;
                $lineStmt->execute($pl);
            }

            // Update ledger
            if ($status !== 'draft') {
                $this->updateLedger($adminId, $customerId, 'invoice', $invoiceId, $grandTotal->getAmount(), '0.00', "Invoice #{$invoiceNumber}");
            }

            $this->eventBus->publish('invoices.created', [
                'admin_id' => $adminId,
                'invoice_id' => $invoiceId,
                'row_uuid' => $rowUuid
            ]);

            $this->db->commit();

            return [
                'id' => $invoiceId,
                'invoice_number' => $invoiceNumber,
                'grand_total' => $grandTotal->getAmount()
            ];

        } catch (\Exception $e) {
            $this->db->rollBack();
            throw new RuntimeException("Invoice creation failed: " . $e->getMessage(), 0, $e);
        }
    }

    /**
     * Update customer ledger
     */
    private function updateLedger(int $adminId, int $customerId, string $type, int $refId, string $debitAmt, string $creditAmt, string $desc): void
    {
        $stmt = $this->db->prepare("SELECT running_balance FROM customer_ledger WHERE customer_id = ? AND admin_id = ? ORDER BY id DESC LIMIT 1 FOR UPDATE");
        $stmt->execute([$customerId, $adminId]);
        $currentBalance = $stmt->fetchColumn();
        
        $currentBalanceMoney = new Money((string)($currentBalance ?: '0.00'));
        $debitMoney = new Money($debitAmt);
        $creditMoney = new Money($creditAmt);

        // balance = current + debit - credit
        $newBalance = $currentBalanceMoney->add($debitMoney)->subtract($creditMoney);

        $sql = "INSERT INTO customer_ledger (uuid, admin_id, row_uuid, customer_id, transaction_type, reference_id, debit_amount, credit_amount, running_balance, description)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $ins = $this->db->prepare($sql);
        $ins->execute([
            Uuid::v4(), $adminId, Uuid::v4(), $customerId, $type, $refId, 
            $debitMoney->getAmount(), $creditMoney->getAmount(), $newBalance->getAmount(), $desc
        ]);
        
        // Also update consumer table outstanding_balance
        $updCons = $this->db->prepare("UPDATE consumers SET outstanding_balance = ? WHERE id = ?");
        $updCons->execute([$newBalance->getAmount(), $customerId]);
    }

    private function generateInvoiceNumber(int $adminId): string
    {
        return 'INV-' . date('ymd') . '-' . mt_rand(1000, 9999);
    }
}
