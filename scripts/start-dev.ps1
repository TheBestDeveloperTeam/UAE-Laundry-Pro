param(
  [string]$FlutterPath = "E:\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "Ensure XAMPP Apache and MySQL are running."
Write-Host "API health: http://localhost/laundrypro-api/public/api/v1/health"

if (-not (Test-Path $FlutterPath)) {
  throw "Flutter not found at $FlutterPath"
}

$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = 'E:/flutter'

Push-Location $RepoRoot
& $FlutterPath run -d windows
Pop-Location
