param(
  [string]$PhpPath = "",
  [string]$FlutterPath = "E:\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "LaundryPro UAE - Developer Setup"
Write-Host "Repository: $RepoRoot"

# Runtime directories
$dirs = @(
  "E:\LaundryPro\invoices",
  "E:\LaundryPro\images",
  "E:\LaundryPro\backups",
  "E:\LaundryPro\logs",
  "E:\LaundryPro\exports"
)
foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
Write-Host "Runtime directories ready under E:\LaundryPro"

# API env + migrations
& (Join-Path $RepoRoot "scripts\migrate.ps1") -PhpPath $PhpPath

$envFile = Join-Path $RepoRoot "api\.env"
if (Test-Path $envFile) {
  $envContent = Get-Content $envFile -Raw
  if ($envContent -notmatch 'APP_BASE_PATH=') {
    Add-Content $envFile "`nAPP_BASE_PATH=/laundrypro-api/public"
    Write-Host "Added APP_BASE_PATH=/laundrypro-api/public to api/.env"
  }
}

# Optional Apache junction (requires admin)
$junctionTarget = "E:\xampp\htdocs\laundrypro-api"
$apiSource = Join-Path $RepoRoot "api"
if ((Test-Path "E:\xampp\htdocs") -and -not (Test-Path $junctionTarget)) {
  Write-Host "Create junction manually (Admin PowerShell):"
  Write-Host "mklink /J `"$junctionTarget`" `"$apiSource`""
}

# Flutter deps
if (Test-Path $FlutterPath) {
  $env:GIT_CONFIG_COUNT = '1'
  $env:GIT_CONFIG_KEY_0 = 'safe.directory'
  $env:GIT_CONFIG_VALUE_0 = 'E:/flutter'
  Push-Location $RepoRoot
  & $FlutterPath pub get
  Pop-Location
  Write-Host "Flutter dependencies installed."
} else {
  Write-Host "Flutter not found at $FlutterPath. Install Flutter and run: flutter pub get"
}

Write-Host "Setup complete."
Write-Host "1. Start XAMPP Apache + MySQL"
Write-Host "2. Enable PHP zip extension in php.ini (extension=zip) and restart Apache"
Write-Host "3. Open http://localhost/laundrypro-api/public/api/v1/health"
Write-Host "4. Run scripts/start-dev.ps1"
