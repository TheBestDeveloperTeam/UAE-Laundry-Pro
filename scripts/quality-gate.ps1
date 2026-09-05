param(
  [string]$PhpPath = "E:\xampp\php\php.exe",
  [string]$FlutterPath = "E:\flutter\bin\flutter.bat",
  [string]$ApiBaseUrl = "http://localhost/laundrypro-api/public/api/v1"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Invoke-Step {
  param([string]$Name, [scriptblock]$Action)
  Write-Host "`n==> $Name"
  & $Action
  if ($LASTEXITCODE -ne 0) {
    throw "Quality gate failed at: $Name"
  }
}

if (-not (Test-Path $PhpPath)) {
  if (Get-Command php -ErrorAction SilentlyContinue) {
    $PhpPath = (Get-Command php).Source
  } else {
    throw "PHP not found."
  }
}

Invoke-Step "PHP lint" { powershell -File (Join-Path $RepoRoot "scripts\php-lint.ps1") -PhpPath $PhpPath }
Invoke-Step "Autoload test" { & $PhpPath (Join-Path $RepoRoot "api\tests\autoload_test.php") }
Invoke-Step "Routing test" { & $PhpPath (Join-Path $RepoRoot "api\tests\routing_test.php") }
Invoke-Step "JWT test" { & $PhpPath (Join-Path $RepoRoot "api\tests\jwt_test.php") }
Invoke-Step "API test suite" { powershell -File (Join-Path $RepoRoot "scripts\api-test.ps1") -PhpPath $PhpPath -BaseUrl $ApiBaseUrl }
Invoke-Step "API smoke" { powershell -File (Join-Path $RepoRoot "scripts\api-smoke.ps1") -BaseUrl $ApiBaseUrl }

Invoke-Step "OpenAPI route drift check" { & $PhpPath (Join-Path $RepoRoot "api\tests\openapi_drift_test.php") }

if (Test-Path $FlutterPath) {
  $env:GIT_CONFIG_COUNT = '1'
  $env:GIT_CONFIG_KEY_0 = 'safe.directory'
  $env:GIT_CONFIG_VALUE_0 = 'E:/flutter'
  Push-Location $RepoRoot
  Invoke-Step "Flutter analyze" { & $FlutterPath analyze }
  Invoke-Step "Flutter test" { & $FlutterPath test }
  Pop-Location
} else {
  Write-Host "Skipping Flutter checks (flutter not found)."
}

Write-Host "`nQuality gate passed."
