param(
  [Parameter(Position = 0)]
  [string]$Command = "help",
  [string]$PhpPath = "E:\xampp\php\php.exe",
  [string]$FlutterPath = "E:\flutter\bin\flutter.bat",
  [string]$ApiBaseUrl = "http://localhost/laundrypro-api/public/api/v1"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Show-Help {
  Write-Host @"
LaundryPro UAE developer CLI

Usage: powershell scripts/dev.ps1 <command>

Commands:
  setup      First-run setup (dirs, migrate, seeds, flutter pub get)
  migrate    Run DB migrations + dev seeds
  lint       PHP syntax lint
  test-api   Full API JSON test suite
  smoke      API health + auth smoke
  test       Flutter unit/widget tests
  analyze    Flutter analyzer
  gate       Full quality gate (lint + API + Flutter)
  package    Build MSIX package
  help       Show this help
"@
}

switch ($Command.ToLower()) {
  "setup" {
    & (Join-Path $PSScriptRoot "setup-dev.ps1") -PhpPath $PhpPath -FlutterPath $FlutterPath
  }
  "migrate" {
    & (Join-Path $PSScriptRoot "migrate.ps1") -PhpPath $PhpPath
  }
  "lint" {
    & (Join-Path $PSScriptRoot "php-lint.ps1") -PhpPath $PhpPath
  }
  "test-api" {
    & (Join-Path $PSScriptRoot "api-test.ps1") -PhpPath $PhpPath -BaseUrl $ApiBaseUrl
  }
  "smoke" {
    & (Join-Path $PSScriptRoot "api-smoke.ps1") -BaseUrl $ApiBaseUrl
  }
  "test" {
    if (-not (Test-Path $FlutterPath)) { throw "Flutter not found at $FlutterPath" }
    $env:GIT_CONFIG_COUNT = '1'
    $env:GIT_CONFIG_KEY_0 = 'safe.directory'
    $env:GIT_CONFIG_VALUE_0 = 'E:/flutter'
    Push-Location $RepoRoot
    & $FlutterPath test
    Pop-Location
  }
  "analyze" {
    if (-not (Test-Path $FlutterPath)) { throw "Flutter not found at $FlutterPath" }
    $env:GIT_CONFIG_COUNT = '1'
    $env:GIT_CONFIG_KEY_0 = 'safe.directory'
    $env:GIT_CONFIG_VALUE_0 = 'E:/flutter'
    Push-Location $RepoRoot
    & $FlutterPath analyze
    Pop-Location
  }
  "gate" {
    & (Join-Path $PSScriptRoot "quality-gate.ps1") -PhpPath $PhpPath -FlutterPath $FlutterPath -ApiBaseUrl $ApiBaseUrl
  }
  "package" {
    & (Join-Path $PSScriptRoot "package.ps1") -FlutterPath $FlutterPath
  }
  default {
    Show-Help
    if ($Command -ne "help") { exit 1 }
  }
}
