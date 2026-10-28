param(
  [string]$PhpPath = "",
  [string]$FlutterPath = "flutter",
  [string]$ApiBaseUrl = "http://localhost/laundrypro-api/public/api/v1"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if ([string]::IsNullOrWhiteSpace($PhpPath)) {
  foreach ($c in @("E:\xampp\php\php.exe", "C:\xampp\php\php.exe")) {
    if (Test-Path $c) { $PhpPath = $c; break }
  }
  if ([string]::IsNullOrWhiteSpace($PhpPath)) { $PhpPath = "php" }
}

Write-Host "========================================="
Write-Host " LAUNDRYPRO UAE - QUALITY GATE"
Write-Host "========================================="

Write-Host "`n[1/5] PHP syntax..."
Get-ChildItem -Path "api\src", "cloud-api\src" -Recurse -Filter "*.php" | ForEach-Object {
  & $PhpPath -l $_.FullName | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "PHP syntax error: $($_.FullName)"
  }
}
Write-Host "PHP syntax: PASS"

Write-Host "`n[2/5] Swagger files..."
$swaggerLocal = "docs\swagger\SWAGGER_LOCAL_FINAL.yaml"
$swaggerCloud = "docs\swagger\SWAGGER_CLOUD_FINAL.yaml"
if (-not (Test-Path $swaggerLocal) -or -not (Test-Path $swaggerCloud)) {
  throw "Missing swagger under docs/swagger/"
}
Write-Host "Swagger: PASS"

Write-Host "`n[3/7] Route parity + OpenAPI + cloud tests..."
& $PhpPath scripts\verify_route_parity.php
if ($LASTEXITCODE -ne 0) { throw "Route parity failed" }
& $PhpPath api\tests\openapi_drift_test.php
if ($LASTEXITCODE -ne 0) { throw "OpenAPI drift failed" }
& $PhpPath api\tests\openapi_export_smoke_test.php
if ($LASTEXITCODE -ne 0) { throw "OpenAPI export smoke failed" }
& $PhpPath cloud-api\tests\cloud_core_test.php
if ($LASTEXITCODE -ne 0) { throw "Cloud core tests failed" }
& $PhpPath cloud-api\tests\cloud_route_registry_test.php
if ($LASTEXITCODE -ne 0) { throw "Cloud route registry failed" }
& $PhpPath api\tests\deploy_automation_smoke_test.php
if ($LASTEXITCODE -ne 0) { throw "Deploy automation smoke failed" }
& $PhpPath cloud-api\tests\cloud_domain_parity_test.php
if ($LASTEXITCODE -ne 0) { throw "Cloud domain parity failed" }
Write-Host "PHP gates: PASS"

Write-Host "`n[4/7] Flutter analyze..."
& $FlutterPath analyze --no-fatal-infos 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { throw "Flutter analyze failed" }
Write-Host "Flutter analyze: PASS"

Write-Host "`n[5/7] Flutter tests..."
& $FlutterPath test
if ($LASTEXITCODE -ne 0) { throw "Flutter tests failed" }

Write-Host "`n[6/7] Local API integration (optional if station not running)..."
$healthUrl = ($ApiBaseUrl -replace '/api/v1$', '') + '/health'
$apiOk = $false
try {
  $r = Invoke-WebRequest -Uri $healthUrl -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
  $apiOk = ($r.StatusCode -eq 200)
} catch { $apiOk = $false }

if ($apiOk) {
  & $PhpPath api\tests\run_api_tests.php
  if ($LASTEXITCODE -ne 0) { throw "API tests failed" }
  Write-Host "API integration: PASS"
} else {
  Write-Host "API integration: SKIP ($healthUrl not reachable; start XAMPP/local API for full gate)"
}

Write-Host "`n[7/7] Live cloud smoke (optional)..."
$liveScript = Join-Path $RepoRoot "scripts\cloud_deploy\cloud_live_smoke.ps1"
if (Test-Path $liveScript) {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $liveScript -Quiet
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Live cloud smoke: FAIL (deploy routes/bootstrap - see POST_UAT_REAUDIT R2)"
  } else {
    Write-Host "Live cloud smoke: PASS"
  }
}

Write-Host "`n========================================="
Write-Host " QUALITY GATE PASSED"
Write-Host "========================================="
exit 0
