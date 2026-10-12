<#
.SYNOPSIS
  Build Windows release and create a code-signed MSIX when certificate parameters are supplied.
#>
param(
  [string]$FlutterPath = "",
  [string]$ApiBaseUrl = "https://laundrypro-api/api/v1",
  [string]$CloudApiBaseUrl = "https://your-cloud-domain.example.com/api/v1",
  [string]$CertificatePath = "",
  [string]$CertificatePassword = "",
  [switch]$SkipFlutterBuild
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($FlutterPath)) {
  if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $FlutterPath = (Get-Command flutter).Source
  } elseif (Test-Path "E:\flutter\bin\flutter.bat") {
    $FlutterPath = "E:\flutter\bin\flutter.bat"
  } else {
    throw "Flutter not found."
  }
}

if ([string]::IsNullOrWhiteSpace($CertificatePath)) {
  $CertificatePath = $env:LAUNDRYPRO_MSIX_CERT_PATH
}
if ([string]::IsNullOrWhiteSpace($CertificatePassword)) {
  $CertificatePassword = $env:LAUNDRYPRO_MSIX_CERT_PASSWORD
}

$dartDefines = @(
  "--dart-define=API_BASE_URL=$ApiBaseUrl",
  "--dart-define=CLOUD_API_BASE_URL=$CloudApiBaseUrl"
)

Push-Location $RepoRoot
if (-not $SkipFlutterBuild) {
  Write-Host "Building Flutter Windows release..." -ForegroundColor Cyan
  & $FlutterPath build windows --release @dartDefines
}

$msixArgs = @("pub", "run", "msix:create")
if ($CertificatePath -and (Test-Path $CertificatePath)) {
  Write-Host "Signing MSIX with certificate: $CertificatePath" -ForegroundColor Cyan
  $msixArgs += @(
    "--certificate-path", $CertificatePath,
    "--certificate-password", $CertificatePassword
  )
} else {
  Write-Warning "No certificate path. MSIX will be unsigned. Set -CertificatePath or LAUNDRYPRO_MSIX_CERT_PATH."
}

Write-Host "Creating MSIX package..." -ForegroundColor Cyan
& $FlutterPath @msixArgs
Pop-Location

Write-Host "MSIX output: build\windows\x64\runner\Release\" -ForegroundColor Green
