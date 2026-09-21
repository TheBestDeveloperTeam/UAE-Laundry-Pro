<?php

declare(strict_types=1);

namespace LaundryPro\Api\Repositories;

use PDO;
use RuntimeException;
use LaundryPro\Api\Services\InvoiceNumberGenerator;
use LaundryPro\Api\Services\VatCalculator;

final class InvoiceRepository
{
  public function __construct(
    private readonly PDO $pdo,
    private readonly InvoiceNumberGenerator $invoiceGenerator,
    private readonly int $businessOwnerId = 1,
  ) {
  }

  public function list(): array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM invoices WHERE business_owner_id = :owner ORDER BY id DESC LIMIT 50');
    $stmt->execute(['owner' => $this->businessOwnerId]);
    return $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];
  }

  public function findById(int $id): ?array
  {
    $stmt = $this->pdo->prepare('SELECT * FROM invoices WHERE id = :id AND business_owner_id = :owner LIMIT 1');
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
  }

  public function createFromOrder(int $orderId, array $order, int $userId): array
  {
    $invoiceNo = $this->invoiceGenerator->generateNext();
    
    // In a real scenario, we'd copy lines, calculate VAT, etc.
    $subtotal = $order['subtotal'] ?? 0;
    $tax = VatCalculator::calculateVat($subtotal);
    $grandTotal = $subtotal + $tax;

    $stmt = $this->pdo->prepare(
      'INSERT INTO invoices (business_owner_id, sales_order_id, invoice_no, status, subtotal, tax, grand_total, created_by, created_at)
       VALUES (:owner, :order_id, :inv_no, :status, :subtotal, :tax, :grand, :user, UTC_TIMESTAMP())'
    );
    $stmt->execute([
      'owner' => $this->businessOwnerId,
      'order_id' => $orderId,
      'inv_no' => $invoiceNo,
      'status' => 'draft',
      'subtotal' => $subtotal,
      'tax' => $tax,
      'grand' => $grandTotal,
      'user' => $userId,
    ]);

    $id = (int) $this->pdo->lastInsertId();
    return $this->findById($id);
  }

  public function post(int $id, int $userId): ?array
  {
    $stmt = $this->pdo->prepare('UPDATE invoices SET status = "posted", posted_at = UTC_TIMESTAMP() WHERE id = :id AND status = "draft" AND business_owner_id = :owner');
    $stmt->execute(['id' => $id, 'owner' => $this->businessOwnerId]);
    return $this->findById($id);
  }

  public function createCorrection(int $id, array $data, int $userId): ?array
  {
    $invoice = $this->findById($id);
    if (!$invoice || $invoice['status'] !== 'posted') {
      throw new RuntimeException("Cannot create correction for non-posted invoice");
    }

    $correctionNo = $invoice['invoice_no'] . '-CORR-' . time();

    $stmt = $this->pdo->prepare(
      'INSERT INTO invoices (business_owner_id, sales_order_id, invoice_no, status, subtotal, tax, grand_total, created_by, created_at, notes)
       VALUES (:owner, :order_id, :inv_no, :status, :subtotal, :tax, :grand, :user, UTC_TIMESTAMP(), :notes)'
    );
    $stmt->execute([
      'owner' => $this->businessOwnerId,
      'order_id' => $invoice['sales_order_id'],
      'inv_no' => $correctionNo,
      'status' => 'draft',
      'subtotal' => $data['amount'] ?? 0,
      'tax' => 0, // Simplified
      'grand' => $data['amount'] ?? 0,
      'user' => $userId,
      'notes' => 'Correction Memo for ' . $invoice['invoice_no'],
    ]);

    $newId = (int) $this->pdo->lastInsertId();
    return $this->findById($newId);
  }
}
