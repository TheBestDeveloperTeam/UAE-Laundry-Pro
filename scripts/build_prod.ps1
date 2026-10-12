<#
.SYNOPSIS
  Production pack builder: Windows app, optional signed MSIX, local API zip, cloud API zip, manifest.
#>
param(
  [string]$FlutterPath = "",
  [string]$ApiBaseUrl = "https://laundrypro-api/api/v1",
  [string]$CloudApiBaseUrl = "https://your-cloud-domain.example.com/api/v1",
  [switch]$BuildMsix,
  [string]$CertificatePath = "",
  [string]$CertificatePassword = "",
  [switch]$BuildAndroid
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-Flutter {
  param([string]$Hint)
  if ($Hint -and (Test-Path $Hint)) { return $Hint }
  if (Get-Command flutter -ErrorAction SilentlyContinue) {
    return (Get-Command flutter).Source
  }
  $fallback = "E:\flutter\bin\flutter.bat"
  if (Test-Path $fallback) { return $fallback }
  throw "Flutter not found. Pass -FlutterPath or add flutter to PATH."
}

function Get-FileSha256 {
  param([string]$Path)
  return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function New-ZipFromDirectory {
  param([string]$SourceDir, [string]$ZipPath, [string[]]$ExcludeNames = @())
  if (Test-Path $ZipPath) { Remove-Item -Force $ZipPath }
  $temp = Join-Path $env:TEMP ("lp-pack-" + [guid]::NewGuid().ToString())
  Copy-Item -Recurse -Force $SourceDir $temp
  foreach ($name in $ExcludeNames) {
    Get-ChildItem -Path $temp -Recurse -Force -Filter $name -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  }
  Compress-Archive -Path (Join-Path $temp '*') -DestinationPath $ZipPath -Force
  Remove-Item -Recurse -Force $temp
}

$FlutterPath = Resolve-Flutter -Hint $FlutterPath
$pubspec = Get-Content (Join-Path $RepoRoot "pubspec.yaml") -Raw
if ($pubspec -match 'version:\s*([0-9.]+)\+([0-9]+)') {
  $AppVersion = $Matches[1]
  $BuildNumber = $Matches[2]
} else {
  $AppVersion = "1.0.0"
  $BuildNumber = "0"
}

$OutRoot = Join-Path $RepoRoot "build\prod_release\$AppVersion+$BuildNumber"
if (Test-Path $OutRoot) { Remove-Item -Recurse -Force $OutRoot }
New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " LaundryPro UAE - Production Pack $AppVersion+$BuildNumber"
Write-Host "=============================================" -ForegroundColor Cyan

$dartDefines = @(
  "--dart-define=API_BASE_URL=$ApiBaseUrl",
  "--dart-define=CLOUD_API_BASE_URL=$CloudApiBaseUrl"
)

Push-Location $RepoRoot
& $FlutterPath pub get
& $FlutterPath build windows --release @dartDefines
Pop-Location

$FlutterReleaseDir = Join-Path $RepoRoot "build\windows\x64\runner\Release"
if (Test-Path $FlutterReleaseDir) {
  Copy-Item -Recurse -Force $FlutterReleaseDir (Join-Path $OutRoot "LaundryProApp")
  Write-Host "[x] Windows release copied" -ForegroundColor Green
} else {
  throw "Flutter build output missing: $FlutterReleaseDir"
}

if ($BuildMsix) {
  & (Join-Path $PSScriptRoot "build_msix.ps1") `
    -FlutterPath $FlutterPath `
    -ApiBaseUrl $ApiBaseUrl `
    -CloudApiBaseUrl $CloudApiBaseUrl `
    -CertificatePath $CertificatePath `
    -CertificatePassword $CertificatePassword `
    -SkipFlutterBuild
  $msixSource = Get-ChildItem -Path (Join-Path $RepoRoot "build\windows\x64\runner\Release") -Filter "*.msix" | Select-Object -First 1
  if ($msixSource) {
    $msixDest = Join-Path $OutRoot ("LaundryPro_{0}_x64.msix" -f $AppVersion)
    Copy-Item -Force $msixSource.FullName $msixDest
    Write-Host "[x] MSIX: $msixDest" -ForegroundColor Green
  }
}

if ($BuildAndroid) {
  Push-Location $RepoRoot
  & $FlutterPath build appbundle --release @dartDefines
  Pop-Location
}

# Local API zip
$ApiZip = Join-Path $OutRoot ("LaundryProApi_{0}.zip" -f $AppVersion)
New-ZipFromDirectory -SourceDir (Join-Path $RepoRoot "api") -ZipPath $ApiZip -ExcludeNames @(".env", "tests")
Copy-Item -Force (Join-Path $RepoRoot "api\.env.production.template") (Join-Path $OutRoot "api.env.template")
Write-Host "[x] API zip: $ApiZip" -ForegroundColor Green

# Cloud API zip
$CloudZip = Join-Path $OutRoot ("CloudApi_{0}.zip" -f $AppVersion)
New-ZipFromDirectory -SourceDir (Join-Path $RepoRoot "cloud-api") -ZipPath $CloudZip -ExcludeNames @(".env", ".env.production", "tests")
Copy-Item -Force (Join-Path $RepoRoot "cloud-api\.env.production.example") (Join-Path $OutRoot "cloud-api.env.template")
Write-Host "[x] Cloud zip: $CloudZip" -ForegroundColor Green

@(
  "# Local store checklist ($AppVersion)"
  ""
  "1. Install XAMPP Apache + MySQL"
  "2. Deploy api/ per docs/operations/LOCAL_WINDOWS_SETUP.md"
  "3. Copy api.env.template to api/.env"
  "4. Run migrate.ps1"
  "5. Register scripts/setup-task-scheduler.ps1"
  "6. Install MSIX from this folder"
  "7. Activate license from cloud admin"
) | Set-Content -Path (Join-Path $OutRoot "CHECKLIST_LOCAL.md") -Encoding UTF8

@(
  "# Cloud cPanel checklist ($AppVersion)"
  ""
  "1. Upload CloudApi zip; extract under subdomain root"
  "2. Copy cloud-api.env.template to cloud-api/.env"
  "3. php cloud-api/scripts/deploy.php"
  "4. Configure cron jobs (see deployment.md)"
  "5. Verify /api/v1/health and /admin/login"
  "6. Issue pilot store license"
) | Set-Content -Path (Join-Path $OutRoot "CHECKLIST_CLOUD.md") -Encoding UTF8

$manifest = @{
  app_version = $AppVersion
  build_number = $BuildNumber
  built_at_utc = (Get-Date).ToUniversalTime().ToString("o")
  api_base_url = $ApiBaseUrl
  cloud_api_base_url = $CloudApiBaseUrl
  artifacts = @()
}
foreach ($f in Get-ChildItem $OutRoot -File) {
  $manifest.artifacts += @{
    name = $f.Name
    sha256 = Get-FileSha256 $f.FullName
    bytes = $f.Length
  }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutRoot "MANIFEST.json") -Encoding UTF8

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Production pack: $OutRoot" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
