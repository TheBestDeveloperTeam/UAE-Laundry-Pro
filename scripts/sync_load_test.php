<?php

declare(strict_types=1);

/**
 * PHP-only sync stress helper (replaces Node/k6 script for production pack tooling).
 *
 * Usage:
 *   php scripts/sync_load_test.php --url=https://host/api/v1 --token=JWT --iterations=50 --concurrency=5
 */

$options = getopt('', ['url:', 'token:', 'iterations::', 'concurrency::']);
$baseUrl = rtrim((string) ($options['url'] ?? getenv('API_BASE_URL') ?: 'http://localhost/laundrypro-api/public/api/v1'), '/');
$token = (string) ($options['token'] ?? getenv('SYNC_TEST_TOKEN') ?: '');
$iterations = max(1, (int) ($options['iterations'] ?? 20));
$concurrency = max(1, min(20, (int) ($options['concurrency'] ?? 5)));

if ($token === '') {
  fwrite(STDERR, "Missing --token or SYNC_TEST_TOKEN\n");
  exit(1);
}

$payload = json_encode([
  'records' => [
    [
      'entity_type' => 'customer',
      'entity_local_id' => random_int(1000, 999999),
      'operation' => 'INSERT',
      'payload' => [
        'name' => 'LoadTest ' . bin2hex(random_bytes(4)),
        'phone' => '+97150' . random_int(1000000, 9999999),
      ],
    ],
  ],
], JSON_THROW_ON_ERROR);

$endpoint = $baseUrl . '/sync/push';
$ok = 0;
$fail = 0;
$latencies = [];

for ($i = 0; $i < $iterations; $i++) {
  $start = microtime(true);
  $ch = curl_init($endpoint);
  curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_HTTPHEADER => [
      'Content-Type: application/json',
      'Accept: application/json',
      'Authorization: Bearer ' . $token,
    ],
    CURLOPT_POSTFIELDS => $payload,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 30,
  ]);
  $body = curl_exec($ch);
  $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  $ms = (microtime(true) - $start) * 1000;
  $latencies[] = $ms;
  if ($code >= 200 && $code < 300) {
    $ok++;
  } else {
    $fail++;
    fwrite(STDERR, "HTTP $code: " . substr((string) $body, 0, 200) . "\n");
  }
  if ($i % $concurrency === 0) {
    usleep(100_000);
  }
}

sort($latencies);
$p95 = $latencies[(int) floor(0.95 * (count($latencies) - 1))] ?? 0;

echo "Iterations: $iterations\n";
echo "OK: $ok Fail: $fail\n";
echo "p95 latency ms: " . round($p95, 2) . "\n";
exit($fail > 0 ? 1 : 0);
