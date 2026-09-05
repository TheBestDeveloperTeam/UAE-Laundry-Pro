param(
  [string]$PhpPath = "",
  [string]$MysqlPath = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ApiRoot = Join-Path $RepoRoot "api"

function Resolve-Php {
  param([string]$CustomPath)
  if ($CustomPath -and (Test-Path $CustomPath)) { return $CustomPath }
  $candidates = @(
    "E:\xampp\php\php.exe",
    "php"
  )
  foreach ($candidate in $candidates) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
      return (Get-Command $candidate).Source
    }
    if (Test-Path $candidate) { return $candidate }
  }
  throw "PHP not found. Install XAMPP or pass -PhpPath."
}

function Resolve-Mysql {
  param([string]$CustomPath)
  if ($CustomPath -and (Test-Path $CustomPath)) { return $CustomPath }
  $candidate = "E:\xampp\mysql\bin\mysql.exe"
  if (Test-Path $candidate) { return $candidate }
  if (Get-Command mysql -ErrorAction SilentlyContinue) {
    return (Get-Command mysql).Source
  }
  return $null
}

$php = Resolve-Php -CustomPath $PhpPath
$mysql = Resolve-Mysql -CustomPath $MysqlPath

Write-Host "Using PHP: $php"

if (-not (Test-Path (Join-Path $ApiRoot ".env"))) {
  Copy-Item (Join-Path $ApiRoot ".env.example") (Join-Path $ApiRoot ".env")
  Write-Host "Created api/.env from .env.example"
}

if ($mysql) {
  Write-Host "Creating database laundrypro if needed..."
  & $mysql -u root -e "CREATE DATABASE IF NOT EXISTS laundrypro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

& $php (Join-Path $ApiRoot "database\migrate.php")
& $php (Join-Path $ApiRoot "database\seeds\ensure_dev_admin.php") "admin123"
& $php (Join-Path $ApiRoot "database\seeds\ensure_dev_cashier.php")

Write-Host "Migration complete. Default admin: admin / admin123"
