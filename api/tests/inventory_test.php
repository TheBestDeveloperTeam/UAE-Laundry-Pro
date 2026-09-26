<?php

require_once __DIR__ . '/../vendor/autoload.php';

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Repositories\InventoryRepository;

$db = new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Setup Schema
$db->exec(file_get_contents(__DIR__ . '/../migrations/005_inventory_schema.sql'));

$eventBus = new EventBus();
$repo = new InventoryRepository($db, $eventBus);

$adminId = 1;
$productId = 100;
$branchId = 10;

// 1. Initial balance should be 0
$balance = $repo->getBalance($adminId, $productId, $branchId);
if ($balance === 0.0) {
    echo "PASS: Initial stock balance is 0.\n";
} else {
    echo "FAIL: Expected initial balance 0, got $balance\n";
    exit(1);
}

// 2. Adjust stock positively (receipt)
$res = $repo->adjustStock($adminId, $productId, $branchId, 50.5, 'receipt');
if ($res['new_stock'] === 50.5) {
    echo "PASS: Stock adjusted successfully to 50.5.\n";
} else {
    echo "FAIL: Expected stock 50.5, got {$res['new_stock']}\n";
    exit(1);
}

// 3. Test Negative Stock Exception (Sale)
try {
    $repo->adjustStock($adminId, $productId, $branchId, -60.0, 'sale');
    echo "FAIL: Expected RuntimeException for insufficient stock\n";
    exit(1);
} catch (RuntimeException $e) {
    if ($e->getMessage() === 'INSUFFICIENT_STOCK') {
        echo "PASS: Insufficient stock correctly prevented.\n";
    } else {
        echo "FAIL: Wrong exception message: " . $e->getMessage() . "\n";
        exit(1);
    }
}

// 4. Valid negative stock (Sale)
$res = $repo->adjustStock($adminId, $productId, $branchId, -10.5, 'sale');
if ($res['new_stock'] === 40.0) {
    echo "PASS: Valid stock decrement applied, new stock is 40.0.\n";
} else {
    echo "FAIL: Expected stock 40.0, got {$res['new_stock']}\n";
    exit(1);
}
