<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

use LaundryPro\Api\Core\Env;

final class ApiTestRunner
{
  /** @var array<string, string> */
  private array $vars = [];

  private string $baseUrl;

  private bool $installLocked = false;

  private int $passed = 0;

  private int $failed = 0;

  private int $skipped = 0;

  public function __construct(string $baseUrl)
  {
    $this->baseUrl = rtrim($baseUrl, '/');
    $this->vars['install_token'] = (string) (Env::get('INSTALL_SECRET') ?? '');
  }

  public function run(): int
  {
    $this->detectInstallLock();
    $files = glob(dirname(__DIR__) . '/tests/cases/*.json');
    if ($files === false) {
      fwrite(STDERR, "No test case files found.\n");
      return 1;
    }

    sort($files);
    foreach ($files as $file) {
      $cases = json_decode((string) file_get_contents($file), true);
      if (!is_array($cases)) {
        $this->fail(basename($file), 'Invalid JSON');
        continue;
      }

      foreach ($cases as $case) {
        $this->runCase($case);
      }
    }

    echo PHP_EOL . "Passed: {$this->passed}, Failed: {$this->failed}, Skipped: {$this->skipped}" . PHP_EOL;

    return $this->failed > 0 ? 1 : 0;
  }

  /** @param array<string, mixed> $case */
  private function runCase(array $case): void
  {
    $name = (string) ($case['name'] ?? 'unnamed');

    if (!empty($case['skip_if_locked']) && $this->installLocked) {
      $this->skipped++;
      echo "SKIP  {$name} (install locked)\n";
      return;
    }

    if (!empty($case['only_if_locked']) && !$this->installLocked) {
      $this->skipped++;
      echo "SKIP  {$name} (install not locked)\n";
      return;
    }

    if (!empty($case['requires']) && is_array($case['requires'])) {
      foreach ($case['requires'] as $required) {
        if (!isset($this->vars[(string) $required])) {
          $this->skipped++;
          echo "SKIP  {$name} (missing {$required})\n";
          return;
        }
      }
    }

    if (!empty($case['reset_admin'])) {
      unset($this->vars['admin_token']);
    }

    if (($case['setup'] ?? '') === 'login_as_admin') {
      $this->loginAsAdmin();
    }

    if (($case['setup'] ?? '') === 'login_as_cashier') {
      $this->loginAsCashier();
    }

    $request = $case['request'] ?? [];
    $method = strtoupper((string) ($request['method'] ?? 'GET'));
    $path = $this->replace((string) ($request['path'] ?? '/'));
    $url = str_starts_with($path, 'http://') || str_starts_with($path, 'https://')
      ? $path
      : $this->baseUrl . $path;
    $body = $request['body'] ?? null;
    if ($body !== null) {
      $body = $this->replaceInValue($body);
    }
    $headers = [];
    foreach (($request['headers'] ?? []) as $key => $value) {
      $headers[] = $key . ': ' . $this->replace((string) $value);
    }
    if ($body !== null) {
      $headers[] = 'Content-Type: application/json';
    }

    $ch = curl_init($url);
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_CUSTOMREQUEST => $method,
      CURLOPT_HTTPHEADER => $headers,
      CURLOPT_HEADER => true,
    ]);
    if ($body !== null) {
      curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }

    $raw = curl_exec($ch);
    if (!empty($case['optional']) && $raw === false) {
      $this->skipped++;
      echo "SKIP  {$name} (optional — endpoint unavailable)\n";
      curl_close($ch);
      return;
    }

    if ($raw === false) {
      $this->fail($name, 'curl error: ' . curl_error($ch));
      curl_close($ch);
      return;
    }

    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $headerSize = (int) curl_getinfo($ch, CURLINFO_HEADER_SIZE);
    curl_close($ch);

    $responseBody = substr($raw, $headerSize);
    $decoded = json_decode($responseBody, true);
    if (!is_array($decoded)) {
      $this->fail($name, 'Invalid JSON response');
      return;
    }

    $expected = $case['expected'] ?? [];
    if (isset($expected['status']) && $status !== (int) $expected['status']) {
      if (!empty($case['optional'])) {
        $this->skipped++;
        echo "SKIP  {$name} (optional — status {$status})\n";
        return;
      }
      $this->fail($name, "Expected status {$expected['status']} got {$status}");
      return;
    }
    if (isset($expected['success']) && ($decoded['success'] ?? null) !== $expected['success']) {
      $this->fail($name, 'success mismatch');
      return;
    }
    if (isset($expected['code']) && ($decoded['code'] ?? '') !== $expected['code']) {
      $this->fail($name, "Expected code {$expected['code']} got " . ($decoded['code'] ?? ''));
      return;
    }
    if (isset($expected['message_key']) && ($decoded['message_key'] ?? '') !== $expected['message_key']) {
      $this->fail($name, 'message_key mismatch');
      return;
    }

    if (!empty($case['assert']) && is_array($case['assert'])) {
      foreach ($case['assert'] as $path => $expectedValue) {
        $resolvedExpected = is_string($expectedValue) ? $this->replace($expectedValue) : $expectedValue;
        $actual = $this->arrayGet($decoded, (string) $path);
        if ($this->valuesMatch($actual, $resolvedExpected)) {
          continue;
        }
        $this->fail($name, "Assert {$path}: expected {$resolvedExpected} got " . ($actual ?? 'null'));
        return;
      }
    }

    if (!empty($case['capture']) && is_array($case['capture'])) {
      foreach ($case['capture'] as $var => $path) {
        $value = $this->arrayGet($decoded, (string) $path);
        if ($value !== null) {
          $this->vars[(string) $var] = (string) $value;
        }
      }
    }

    $this->passed++;
    echo "PASS  {$name}\n";

    if ($name === 'logout_success') {
      unset($this->vars['admin_token']);
    }
  }

  private function loginAsCashier(): void
  {
    if (isset($this->vars['cashier_token']) && $this->vars['cashier_token'] !== '') {
      $this->vars['access_token'] = $this->vars['cashier_token'];
      return;
    }

    $ch = curl_init($this->baseUrl . '/auth/login');
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_POST => true,
      CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
      CURLOPT_POSTFIELDS => json_encode(['username' => 'cashier', 'password' => 'cashier123']),
    ]);
    $response = curl_exec($ch);
    curl_close($ch);
    $decoded = is_string($response) ? json_decode($response, true) : null;
    if (is_array($decoded)) {
      $this->vars['cashier_token'] = (string) ($decoded['data']['access_token'] ?? '');
      $this->vars['access_token'] = $this->vars['cashier_token'];
    }
  }

  private function loginAsAdmin(): void
  {
    if (isset($this->vars['admin_token']) && $this->vars['admin_token'] !== '') {
      $this->vars['access_token'] = $this->vars['admin_token'];
      return;
    }

    $ch = curl_init($this->baseUrl . '/auth/login');
    curl_setopt_array($ch, [
      CURLOPT_RETURNTRANSFER => true,
      CURLOPT_POST => true,
      CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
      CURLOPT_POSTFIELDS => json_encode(['username' => 'admin', 'password' => 'admin123']),
    ]);
    $response = curl_exec($ch);
    curl_close($ch);
    $decoded = is_string($response) ? json_decode($response, true) : null;
    if (is_array($decoded)) {
      $this->vars['admin_token'] = (string) ($decoded['data']['access_token'] ?? '');
      $this->vars['access_token'] = $this->vars['admin_token'];
      $this->vars['refresh_token'] = (string) ($decoded['data']['refresh_token'] ?? '');
    }
  }

  private function detectInstallLock(): void
  {
    $ch = curl_init($this->baseUrl . '/install/status');
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true]);
    $response = curl_exec($ch);
    curl_close($ch);
    $decoded = is_string($response) ? json_decode($response, true) : null;
    $this->installLocked = (bool) ($decoded['data']['locked'] ?? false);
  }

  private function replace(string $value): string
  {
    return preg_replace_callback('/\{\{([a-zA-Z0-9_]+)\}\}/', function (array $matches): string {
      return $this->vars[$matches[1]] ?? '';
    }, $value) ?? $value;
  }

  private function replaceInValue(mixed $value): mixed
  {
    if (is_array($value)) {
      $replaced = [];
      foreach ($value as $key => $item) {
        $replaced[$key] = $this->replaceInValue($item);
      }

      return $replaced;
    }

    if (is_string($value)) {
      $resolved = $this->replace($value);
      if (is_numeric($resolved) && !str_contains($value, '.')) {
        return (int) $resolved;
      }
      if (is_numeric($resolved)) {
        return (float) $resolved;
      }

      return $resolved;
    }

    return $value;
  }

  /** @param array<string, mixed> $data */
  private function arrayGet(array $data, string $path): mixed
  {
    $current = $data;
    foreach (explode('.', $path) as $segment) {
      if (!is_array($current) || !array_key_exists($segment, $current)) {
        return null;
      }
      $current = $current[$segment];
    }

    return $current;
  }

  private function valuesMatch(mixed $actual, mixed $expected): bool
  {
    if ($actual === null && $expected === null) {
      return true;
    }
    if ($actual === null || $expected === null) {
      return false;
    }

    if (is_numeric($actual) && is_numeric($expected)) {
      return abs((float) $actual - (float) $expected) < 0.0001;
    }

    if (is_bool($actual)) {
      return filter_var($expected, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE) === $actual;
    }

    return (string) $actual === (string) $expected;
  }

  private function fail(string $name, string $reason): void
  {
    $this->failed++;
    echo "FAIL  {$name} - {$reason}\n";
  }
}

$baseUrl = getenv('API_TEST_BASE_URL') ?: 'http://localhost/laundrypro-api/public/api/v1';
$runner = new ApiTestRunner($baseUrl);
exit($runner->run());
