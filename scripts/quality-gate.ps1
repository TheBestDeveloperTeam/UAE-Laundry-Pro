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

Write-Host "`n[3/5] Route parity..."
& $PhpPath scripts\verify_route_parity.php
if ($LASTEXITCODE -ne 0) { throw "Route parity failed" }
Write-Host "Route parity: PASS"

Write-Host "`n[4/5] Flutter analyze..."
& $FlutterPath analyze
if ($LASTEXITCODE -ne 0) { throw "Flutter analyze failed" }
Write-Host "Flutter analyze: PASS"

Write-Host "`n[5/5] Flutter tests + API tests..."
& $FlutterPath test
if ($LASTEXITCODE -ne 0) { throw "Flutter tests failed" }
& $PhpPath api\tests\run_api_tests.php
if ($LASTEXITCODE -ne 0) { throw "API tests failed" }
Write-Host "Tests: PASS"

Write-Host "`n========================================="
Write-Host " QUALITY GATE PASSED"
Write-Host "========================================="
exit 0
