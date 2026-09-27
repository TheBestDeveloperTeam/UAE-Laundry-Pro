<?php

require_once __DIR__ . '/../vendor/autoload.php';

use LaundryPro\Api\Core\EventBus;
use LaundryPro\Api\Repositories\SalesRepository;

$db = new PDO('sqlite::memory:');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Setup Schema
$db->exec(file_get_contents(__DIR__ . '/../migrations/004_sales_schema.sql'));

$eventBus = new EventBus();
$repo = new SalesRepository($db, $eventBus);

$adminId = 1;

// 1. Test Split Payment Validation (422)
try {
    $repo->createOrder($adminId, ['status' => 'paid'], [
        ['item_name' => 'Wash', 'quantity' => '1', 'unit_price' => '10.00']
    ], [
        ['tender_type' => 'cash', 'amount' => '5.00'] // Mismatch (grand total is 10.00)
    ]);
    echo "FAIL: Expected InvalidArgumentException for split payment mismatch\n";
    exit(1);
} catch (InvalidArgumentException $e) {
    echo "PASS: Split payment mismatch correctly rejected.\n";
}

// 2. Test Successful Exact Split Payment
try {
    $order = $repo->createOrder($adminId, ['status' => 'paid'], [
        ['item_name' => 'Wash', 'quantity' => '1', 'unit_price' => '10.00'],
        ['item_name' => 'Iron', 'quantity' => '2', 'unit_price' => '5.00']
    ], [
        ['tender_type' => 'cash', 'amount' => '10.00'],
        ['tender_type' => 'card', 'amount' => '10.00']
    ]);

    if ($order['grand_total'] === '20.00') {
        echo "PASS: Order created successfully with exact split payment.\n";
    } else {
        echo "FAIL: Incorrect grand total. Expected 20.00, got {$order['grand_total']}\n";
        exit(1);
    }
} catch (Exception $e) {
    echo "FAIL: Unexpected exception: " . $e->getMessage() . "\n";
    exit(1);
}

// 3. Test Retrieve Order
$fetched = $repo->getOrder($adminId, $order['id']);
if ($fetched && count($fetched['lines']) === 2 && count($fetched['payments']) === 2) {
    echo "PASS: Order retrieved with lines and payments successfully.\n";
} else {
    echo "FAIL: Failed to fetch complete order.\n";
    exit(1);
}
