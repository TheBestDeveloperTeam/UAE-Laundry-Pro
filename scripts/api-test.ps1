param(
  [string]$PhpPath = "E:\xampp\php\php.exe",
  [string]$BaseUrl = "http://localhost/laundrypro-api/public/api/v1"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path $PhpPath)) {
  if (Get-Command php -ErrorAction SilentlyContinue) {
    $PhpPath = (Get-Command php).Source
  } else {
    throw "PHP not found."
  }
}

$env:API_TEST_BASE_URL = $BaseUrl
& $PhpPath (Join-Path $RepoRoot "api\tests\run_api_tests.php")
exit $LASTEXITCODE
