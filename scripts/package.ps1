param(
  [switch]$SkipBuild,
  [string]$FlutterPath = "E:\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path $FlutterPath)) {
  if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $FlutterPath = (Get-Command flutter).Source
  } else {
    throw "Flutter not found."
  }
}

Push-Location $RepoRoot
try {
  & $FlutterPath pub get
  if (-not $SkipBuild) {
    & $FlutterPath build windows --release
  }
  $DartPath = Join-Path (Split-Path $FlutterPath -Parent) "dart.bat"
  & $DartPath run msix:create
  Write-Host "MSIX package created in build/windows/x64/runner/Release/"
} finally {
  Pop-Location
}