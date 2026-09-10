$ErrorActionPreference = "Stop"

Write-Host "LaundryPro UAE - Production Build Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# 1. Clean previous builds
Write-Host "Cleaning workspace..."
flutter clean
flutter pub get

# 2. Build the Flutter Windows Executable
Write-Host "Building Flutter Windows App (Release)..."
flutter build windows --release

# 3. Scaffold Output Directory
$OutputDir = ".\build\laundrypro_release"
if (Test-Path $OutputDir) {
    Remove-Item -Recurse -Force $OutputDir
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

# 4. Copy Flutter App
Write-Host "Copying Flutter App..."
Copy-Item -Recurse -Force ".\build\windows\x64\runner\Release\*" $OutputDir\

# 5. Copy Backend Server (API)
Write-Host "Copying Local API Server..."
$ApiDir = "$OutputDir\api"
New-Item -ItemType Directory -Path $ApiDir | Out-Null
Copy-Item -Recurse -Force ".\api\src" $ApiDir\
Copy-Item -Recurse -Force ".\api\public" $ApiDir\
Copy-Item -Recurse -Force ".\api\vendor" $ApiDir\

# 6. Copy Scripts
Write-Host "Copying Deployment Scripts..."
Copy-Item -Force ".\start_server.ps1" $OutputDir\

Write-Host "=====================================" -ForegroundColor Green
Write-Host "Build Complete! Output is located at $OutputDir" -ForegroundColor Green
