<?php
declare(strict_types=1);

require __DIR__ . '/src/Core/Env.php';
use LaundryPro\Api\Core\Env;

Env::load(__DIR__ . '/.env');

$host = Env::get('DB_HOST', '127.0.0.1');
$port = Env::get('DB_PORT', '3306');
$db   = Env::get('DB_DATABASE', 'laundrypro');
$user = Env::get('DB_USERNAME', 'root');
$pass = Env::get('DB_PASSWORD', '');

$dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $db);
try {
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (\Exception $e) {
    die("DB Connection failed: " . $e->getMessage() . "\n");
}

echo "Generating 500 Customers...\n";
$pdo->beginTransaction();
$stmt = $pdo->prepare('INSERT INTO customers (uuid, business_owner_id, full_name, mobile_number, address) VALUES (UUID(), 1, ?, ?, ?)');
for ($i=1; $i<=500; $i++) {
    $name = "Customer " . substr(md5((string)rand()), 0, 6);
    $mobile = "+97150" . rand(1000000, 9999999);
    $address = "Villa " . rand(1, 100) . " Street " . rand(1, 20);
    $stmt->execute([$name, $mobile, $address]);
}
$pdo->commit();

echo "Generating 40 Catalog Services...\n";
$pdo->beginTransaction();
$stmt = $pdo->prepare('INSERT INTO catalog_services (uuid, business_owner_id, category, name, base_rate) VALUES (UUID(), 1, ?, ?, ?)');
$services = [
    'Dry Clean Kandora', 'Wash & Fold Bag', 'Press Suit', 'Steam Curtain', 
    'Leather Jacket Spa', 'Carpet Wash', 'Sneaker Care', 'Wedding Dress Clean',
    'Iron Shirt', 'Wash Blanket', 'Dry Clean Tie', 'Press Trousers'
];
for ($i=0; $i<40; $i++) {
    $s = $services[$i % count($services)] . " " . $i;
    $rate = rand(15, 100) . ".00";
    $stmt->execute(['Dry Clean', $s, $rate]);
}
$pdo->commit();

echo "Generating 250 Sales Orders...\n";
$pdo->beginTransaction();
$stmtOrd = $pdo->prepare('INSERT INTO sales_orders (uuid, business_owner_id, customer_id, branch_id, status, payment_status, grand_total, balance_due, amount_paid) VALUES (UUID(), 1, ?, 1, ?, ?, ?, ?, ?)');
for ($i=1; $i<=250; $i++) {
    $cid = rand(1, 500);
    $statuses = ['received', 'processing', 'ready_for_collection', 'delivered'];
    $status = $statuses[array_rand($statuses)];
    $total = rand(50, 500) . ".00";
    $stmtOrd->execute([$cid, $status, 'paid', $total, '0.00', $total]);
}
$pdo->commit();

echo "Mass seed completed successfully!\n";
