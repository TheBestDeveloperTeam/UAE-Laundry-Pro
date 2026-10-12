<#
.SYNOPSIS
One-Click Setup Script for LaundryPro UAE Developer and Production environments.

.DESCRIPTION
This script automatically discovers PHP and MySQL installations (via XAMPP),
creates necessary database and runtime directories, runs database migrations,
and installs Flutter dependencies.

.EXAMPLE
.\scripts\laundrypro-setup.ps1
#>
param(
  [string]$PhpPath = "",
  [string]$MysqlPath = "",
  [string]$FlutterPath = "",
  [string]$RuntimeRoot = "C:\LaundryPro"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " LaundryPro UAE - Easy Setup & Migration      " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Ensure runtime directories exist
$dirs = @(
  "$RuntimeRoot\invoices",
  "$RuntimeRoot\images",
  "$RuntimeRoot\backups",
  "$RuntimeRoot\logs",
  "$RuntimeRoot\exports",
  "$RuntimeRoot\temp",
  "$RuntimeRoot\templates"
)
foreach ($dir in $dirs) {
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
}
Write-Host "[x] Runtime directories verified under $RuntimeRoot" -ForegroundColor Green

# 2. Run Database Migrations
Write-Host "[*] Starting Database Migration Process..." -ForegroundColor Yellow
$migrateScript = Join-Path $RepoRoot "scripts\migrate.ps1"
if (Test-Path $migrateScript) {
    & $migrateScript -PhpPath $PhpPath -MysqlPath $MysqlPath
    Write-Host "[x] Migrations applied successfully." -ForegroundColor Green
} else {
    Write-Host "[!] Could not find scripts\migrate.ps1" -ForegroundColor Red
}

# 3. Setup API Environment
$envFile = Join-Path $RepoRoot "api\.env"
if (-not (Test-Path $envFile)) {
    $envExample = Join-Path $RepoRoot "api\.env.example"
    if (Test-Path $envExample) {
        Copy-Item $envExample $envFile
        Write-Host "[x] Created api/.env from template" -ForegroundColor Green
    }
}
if (Test-Path $envFile) {
  $envContent = Get-Content $envFile -Raw
  if ($envContent -notmatch 'APP_BASE_PATH=') {
    Add-Content $envFile "`nAPP_BASE_PATH=/laundrypro-api/public"
    Write-Host "[x] Appended APP_BASE_PATH to api/.env" -ForegroundColor Green
  }
}

# 4. Flutter Dependencies
if ([string]::IsNullOrWhiteSpace($FlutterPath)) {
  if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $FlutterPath = (Get-Command flutter).Source
  } elseif (Test-Path "E:\flutter\bin\flutter.bat") {
    $FlutterPath = "E:\flutter\bin\flutter.bat"
  }
}
if ($FlutterPath -and (Test-Path $FlutterPath)) {
  Write-Host "[*] Installing Flutter Dependencies..." -ForegroundColor Yellow
  $env:GIT_CONFIG_COUNT = '1'
  $env:GIT_CONFIG_KEY_0 = 'safe.directory'
  $env:GIT_CONFIG_VALUE_0 = 'E:/flutter'
  Push-Location $RepoRoot
  & $FlutterPath pub get
  Pop-Location
  Write-Host "[x] Flutter dependencies installed." -ForegroundColor Green
} else {
  Write-Host "[-] Flutter not found at $FlutterPath. Skipping Flutter pub get." -ForegroundColor Yellow
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Setup Complete!                              " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Next Steps:"
Write-Host "1. Ensure XAMPP Apache & MySQL are running."
Write-Host "2. Create Apache junction link (if needed):"
Write-Host "   mklink /J `"E:\xampp\htdocs\laundrypro-api`" `"$RepoRoot\api`""
Write-Host "3. Run Flutter app: flutter run"
