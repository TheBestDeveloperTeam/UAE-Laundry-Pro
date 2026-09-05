<?php

declare(strict_types=1);

header('Content-Type: application/json');

$storageDir = dirname(__DIR__) . '/storage';
if (!is_dir($storageDir)) {
  mkdir($storageDir, 0775, true);
}

$businessesFile = $storageDir . '/businesses.json';
$recordsFile = $storageDir . '/sync_records.json';

/** @return array<int, array<string, mixed>> */
function loadJson(string $file): array
{
  if (!is_file($file)) {
    return [];
  }
  $data = json_decode((string) file_get_contents($file), true);

  return is_array($data) ? $data : [];
}

/** @param array<int, array<string, mixed>> $data */
function saveJson(string $file, array $data): void
{
  file_put_contents($file, json_encode($data, JSON_PRETTY_PRINT));
}

function respond(int $status, array $body): void
{
  http_response_code($status);
  echo json_encode($body);
  exit;
}

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$businessOwnerId = (int) ($_SERVER['HTTP_X_BUSINESS_OWNER_ID'] ?? 0);
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
$bearer = '';
if (preg_match('/Bearer\s+(.+)/i', $authHeader, $m)) {
  $bearer = trim($m[1]);
}

if ($method === 'POST' && str_ends_with($path, '/businesses/register')) {
  $body = json_decode(file_get_contents('php://input') ?: '[]', true) ?: [];
  $name = (string) ($body['name'] ?? 'Business');
  $businesses = loadJson($businessesFile);
  $id = count($businesses) + 1;
  $token = bin2hex(random_bytes(32));
  $businesses[] = [
    'id' => $id,
    'name' => $name,
    'license_key' => $body['license_key'] ?? null,
    'cloud_token' => $token,
    'created_at' => gmdate('c'),
  ];
  saveJson($businessesFile, $businesses);
  respond(200, [
    'success' => true,
    'code' => 'BUSINESS_REGISTERED',
    'data' => [
      'business_owner_id' => $id,
      'cloud_token' => $token,
    ],
  ]);
}

if ($businessOwnerId <= 0) {
  respond(401, ['success' => false, 'code' => 'TENANT_REQUIRED']);
}

$businesses = loadJson($businessesFile);
$tenant = null;
foreach ($businesses as $b) {
  if ((int) $b['id'] === $businessOwnerId) {
    $tenant = $b;
    break;
  }
}

if ($tenant === null) {
  respond(401, ['success' => false, 'code' => 'TENANT_NOT_FOUND']);
}

if ($bearer === '' || !hash_equals((string) $tenant['cloud_token'], $bearer)) {
  respond(401, ['success' => false, 'code' => 'INVALID_TOKEN']);
}

if ($method === 'POST' && str_ends_with($path, '/sync/push')) {
  $body = json_decode(file_get_contents('php://input') ?: '[]', true);
  if (!is_array($body)) {
    $body = [];
  }
  $records = loadJson($recordsFile);
  foreach ($body as $record) {
    if (!is_array($record)) {
      continue;
    }
    $records[] = [
      'business_owner_id' => $businessOwnerId,
      'entity_type' => $record['entity_type'] ?? 'unknown',
      'entity_local_id' => (int) ($record['entity_local_id'] ?? 0),
      'operation' => $record['operation'] ?? 'create',
      'payload' => $record['payload'] ?? [],
      'created_at' => gmdate('c'),
    ];
  }
  saveJson($recordsFile, $records);
  respond(200, ['success' => true, 'code' => 'SYNC_RECEIVED', 'data' => ['count' => count($body)]]);
}

if ($method === 'GET' && str_contains($path, '/sync/pull')) {
  $since = $_GET['since'] ?? null;
  $records = loadJson($recordsFile);
  $filtered = array_values(array_filter($records, function (array $r) use ($businessOwnerId, $since): bool {
    if ((int) $r['business_owner_id'] !== $businessOwnerId) {
      return false;
    }
    if ($since !== null && $since !== '' && ($r['created_at'] ?? '') < $since) {
      return false;
    }

    return true;
  }));
  respond(200, ['success' => true, 'code' => 'SYNC_PULL', 'data' => ['records' => $filtered]]);
}

respond(404, ['success' => false, 'code' => 'NOT_FOUND']);
