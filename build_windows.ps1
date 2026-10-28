$ErrorActionPreference = "Stop"

Write-Host "LaundryPro UAE - Production Build Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1. Build the Flutter Windows Executable if not already built
if (-not (Test-Path ".\build\windows\x64\runner\Release\laundrypro_uae.exe")) {
    Write-Host "Building Flutter Windows App (Release)..."
    flutter build windows --release
} else {
    Write-Host "Found existing Windows Release binary, proceeding to packaging..." -ForegroundColor Green
}

# 2. Scaffold Output Directory
$OutputDir = ".\build\laundrypro_release"
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

# 3. Copy Flutter App
Write-Host "Copying Flutter App..."
Copy-Item -Recurse -Force ".\build\windows\x64\runner\Release\*" $OutputDir\

# 4. Copy Backend Server (API)
Write-Host "Copying Local API Server..."
$ApiDir = "$OutputDir\api"
New-Item -ItemType Directory -Path $ApiDir | Out-Null
Copy-Item -Recurse -Force ".\api\src" $ApiDir\
Copy-Item -Recurse -Force ".\api\public" $ApiDir\
Copy-Item -Recurse -Force ".\api\routes" $ApiDir\
Copy-Item -Recurse -Force ".\api\config" $ApiDir\
Copy-Item -Recurse -Force ".\api\database" $ApiDir\
if (Test-Path ".\api\vendor") {
    Copy-Item -Recurse -Force ".\api\vendor" $ApiDir\
}

# 5. Copy Deployment Scripts
Write-Host "Copying Deployment Scripts..."
if (Test-Path ".\scripts\start-dev.ps1") {
    Copy-Item -Force ".\scripts\start-dev.ps1" $OutputDir\start_server.ps1
}

# 6. Package MSIX
Write-Host "Packaging MSIX Installer..."
dart run msix:create

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Build Complete! Output is located at $OutputDir" -ForegroundColor Green