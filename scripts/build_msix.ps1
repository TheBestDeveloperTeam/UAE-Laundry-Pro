# PowerShell script to build MSIX package for Windows Store
$ErrorActionPreference = "Stop"

Write-Host "Building Flutter Windows Desktop App..." -ForegroundColor Cyan
flutter build windows --release

Write-Host "Generating MSIX Package..." -ForegroundColor Cyan
flutter pub run msix:create

Write-Host "MSIX Packaging Complete. Output in build/windows/runner/Release/" -ForegroundColor Green

