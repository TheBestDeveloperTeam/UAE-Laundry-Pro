<#
.SYNOPSIS
Production Build & Packaging Script for LaundryPro UAE.

.DESCRIPTION
This script builds the Flutter Windows Executable, packages the PHP API into a portable zip,
and optionally compiles the MSIX package.
#>
param(
  [string]$FlutterPath = "E:\flutter\bin\flutter.bat",
  [switch]$BuildMsix
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $RepoRoot "build\prod_release"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " LaundryPro UAE - Production Build System     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Clean build directory
if (Test-Path $BuildDir) {
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# 2. Build Flutter Windows Executable
Write-Host "[*] Building Flutter Windows Release..." -ForegroundColor Yellow
Push-Location $RepoRoot
& $FlutterPath clean
& $FlutterPath build windows --release
Pop-Location

$FlutterReleaseDir = Join-Path $RepoRoot "build\windows\x64\runner\Release"
if (Test-Path $FlutterReleaseDir) {
    $TargetAppDir = Join-Path $BuildDir "LaundryProApp"
    Copy-Item -Recurse -Force $FlutterReleaseDir $TargetAppDir
    Write-Host "[x] Flutter Build Successful: $TargetAppDir" -ForegroundColor Green
} else {
    Write-Host "[!] Flutter build output not found." -ForegroundColor Red
}

# 3. Build Flutter Android APK/AppBundle
Write-Host "[*] Building Flutter Android AppBundle..." -ForegroundColor Yellow
Push-Location $RepoRoot
& $FlutterPath build appbundle --release
Pop-Location

$AndroidReleaseDir = Join-Path $RepoRoot "build\app\outputs\bundle\release"
if (Test-Path $AndroidReleaseDir) {
    $TargetAndroidDir = Join-Path $BuildDir "Android"
    New-Item -ItemType Directory -Force -Path $TargetAndroidDir | Out-Null
    Copy-Item -Force (Join-Path $AndroidReleaseDir "app-release.aab") (Join-Path $TargetAndroidDir "LaundryPro.aab") -ErrorAction SilentlyContinue
    Write-Host "[x] Android Build Successful: $TargetAndroidDir" -ForegroundColor Green
} else {
    Write-Host "[!] Android build output not found." -ForegroundColor Red
}

# 4. Package API
Write-Host "[*] Packaging PHP API..." -ForegroundColor Yellow
$ApiDir = Join-Path $RepoRoot "api"
$ApiDistDir = Join-Path $BuildDir "LaundryProApi"
Copy-Item -Recurse -Force $ApiDir $ApiDistDir
# Remove dev/temp files from API release
Remove-Item -Recurse -Force (Join-Path $ApiDistDir ".env") -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force (Join-Path $ApiDistDir "tests") -ErrorAction SilentlyContinue

Write-Host "[x] PHP API packaged at: $ApiDistDir" -ForegroundColor Green

# 4. MSIX Packaging (Optional)
if ($BuildMsix) {
    Write-Host "[*] Building MSIX Package..." -ForegroundColor Yellow
    Push-Location $RepoRoot
    & $FlutterPath pub run msix:create
    Pop-Location
    Write-Host "[x] MSIX Package created in build\windows\runner\Release\" -ForegroundColor Green
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Production Build Complete!                   " -ForegroundColor Cyan
Write-Host " Output Directory: $BuildDir "
Write-Host "=============================================" -ForegroundColor Cyan
