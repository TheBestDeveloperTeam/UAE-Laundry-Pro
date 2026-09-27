<?php

namespace LaundryPro\Api\Services;

use PDO;
use Exception;

class InvoiceNumberGenerator
{
    private PDO $pdo;

    public function __construct(PDO $pdo)
    {
        $this->pdo = $pdo;
    }

    /**
     * Generate the next sequential invoice number without gaps.
     * Format: INV-YYYY-NNNNNN
     *
     * Uses a table lock on a sequence table or a transaction to ensure no duplicates.
     */
    public function generateNext(): string
    {
        try {
            $this.pdo->beginTransaction();

            $year = date('Y');
            $prefix = 'INV-' . $year . '-';

            // We use a dedicated sequence table or just query the max from invoices
            // Better to use a dedicated sequence table for gapless if deletes happen
            // Assuming sequence_tracker table exists: name, year, current_value
            $stmt = $this.pdo->prepare("SELECT current_value FROM sequence_tracker WHERE sequence_name = 'invoice' AND year = ? FOR UPDATE");
            $stmt->execute([$year]);
            $result = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($result) {
                $nextValue = (int)$result['current_value'] + 1;
                $update = $this.pdo->prepare("UPDATE sequence_tracker SET current_value = ? WHERE sequence_name = 'invoice' AND year = ?");
                $update->execute([$nextValue, $year]);
            } else {
                $nextValue = 1;
                $insert = $this.pdo->prepare("INSERT INTO sequence_tracker (sequence_name, year, current_value) VALUES ('invoice', ?, ?)");
                $insert->execute([$year, $nextValue]);
            }

            $this.pdo->commit();

            // Format to 6 digits
            return $prefix . str_pad((string)$nextValue, 6, '0', STR_PAD_LEFT);

        } catch (Exception $e) {
            if ($this.pdo->inTransaction()) {
                $this.pdo->rollBack();
            }
            throw new Exception("Failed to generate invoice number: " . $e->getMessage());
        }
    }
}
