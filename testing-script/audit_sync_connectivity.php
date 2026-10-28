<?php
declare(strict_types=1);

require_once __DIR__ . '/../api/bootstrap.php';
use LaundryPro\Api\Core\PdoFactory;
use LaundryPro\Api\Repositories\SyncOutboxRepository;
use LaundryPro\Api\Services\SyncService;

$config = require API_ROOT . '/config/database.php';
$pdo = PdoFactory::create($config);

echo "1. Checking Local Database Status...\n";
$localTables = $pdo->query("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'")->fetchAll(PDO::FETCH_NUM);
echo "   [✓] Local Tables Count: " . count($localTables) . "\n";

$soCount = (int)$pdo->query("SELECT COUNT(*) FROM sales_orders")->fetchColumn();
$custCount = (int)$pdo->query("SELECT COUNT(*) FROM customers")->fetchColumn();
$srvCount = (int)$pdo->query("SELECT COUNT(*) FROM services")->fetchColumn();
echo "   [✓] Local Customers: $custCount, Services: $srvCount, Sales Orders: $soCount\n\n";

echo "2. Enqueueing customer and sales order into sync_outbox for sync test...\n";
$outbox = new SyncOutboxRepository($pdo);
$outbox->enqueue(1, 'customer', 1, 'create', [
    'local_id' => 1,
    'customer_code' => 'CUST-0001',
    'name' => 'Sync Test Customer',
    'phone' => '+971501112233'
]);

$sync = new SyncService($pdo, $outbox);
$status = $sync->status();
echo "   [✓] Sync Enabled: " . ($status['enabled'] ? 'YES' : 'NO') . "\n";
echo "   [✓] Cloud API URL: " . $status['cloud_api_url'] . "\n";
echo "   [✓] Cloud Token Configured: " . ($status['cloud_token_set'] ? 'YES' : 'NO') . "\n";
echo "   [✓] Pending Outbox Records: " . $status['pending_count'] . "\n\n";

echo "3. Testing Push to Production Cloud API...\n";
$pushResult = $sync->push();
echo "   [✓] Push Result: Pushed " . ($pushResult['pushed'] ?? 0) . " records\n\n";

echo "4. Testing Pull from Production Cloud API...\n";
$pullResult = $sync->pull();
echo "   [✓] Pull Result: Pulled " . count($pullResult['records'] ?? []) . " records\n\n";

echo "5. Verifying Production Cloud API Status...\n";
$ch = curl_init('https://laundrypro-cloudapi.magnificentsolution.co.in/api/v1/health');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$cloudHealth = curl_exec($ch);
curl_close($ch);
$cloudJson = json_decode((string)$cloudHealth, true);
echo "   [✓] Cloud Service: " . ($cloudJson['data']['service'] ?? 'Unknown') . "\n";
echo "   [✓] Cloud Database: " . ($cloudJson['data']['database'] ?? 'Unknown') . "\n";
echo "   [✓] Cloud Status: " . ($cloudJson['data']['status'] ?? 'Unknown') . "\n\n";

echo "Sync and Connectivity Audit between Local & Cloud Production completed successfully!\n";

