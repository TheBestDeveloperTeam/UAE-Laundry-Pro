param(
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$PhpPath = ""
foreach ($c in @("E:\xampp\php\php.exe", "C:\xampp\php\php.exe", "php")) {
  if ($c -eq "php") {
    if (Get-Command php -ErrorAction SilentlyContinue) { $PhpPath = "php"; break }
  } elseif (Test-Path $c) {
    $PhpPath = $c
    break
  }
}
if (-not $PhpPath) { throw "PHP CLI not found" }

$json = & $PhpPath (Join-Path $PSScriptRoot "export_creds_json.php")
$creds = $json | ConvertFrom-Json
$paths = $creds.deploy_paths
$ftp = $creds.ftp
$ssh = $creds.ssh
$origin = ($creds.deploy.apply_url -replace '/api/v1/internal/deploy/apply$', '')

function Write-Line([string]$msg) {
  if (-not $Quiet) { Write-Host $msg }
}

Write-Line "=== Deploy path map (FTP vs HTTP docroot) ==="
Write-Line ("  deploy_layout     : {0}" -f $paths.deploy_layout)
Write-Line ("  deploy_root       : {0}" -f $paths.deploy_root)
Write-Line ("  http_docroot      : {0}" -f $paths.http_docroot)
Write-Line ("  public_web_root   : {0}" -f $paths.public_web_root)
Write-Line ("  ftp_remote_path   : {0}" -f $ftp.remote_path)
Write-Line ("  ssh remote_home   : {0}" -f $ssh.remote_home)

$mis = @()
if ($ftp.remote_path -and $paths.deploy_root -and ($ftp.remote_path -ne $paths.deploy_root)) {
  $mis += "ftp_remote_path != deploy_root"
}
if ($ssh.remote_home -and $paths.deploy_root -and ($ssh.remote_home -ne $paths.deploy_root)) {
  $mis += "remote_home != deploy_root"
}
if ($paths.deploy_layout -eq "option_a" -and $paths.http_docroot -ne $paths.public_web_root) {
  $mis += "Option A http_docroot should end with /cloud-api/public"
}

if ($mis.Count -gt 0) {
  Write-Line ""
  Write-Line "CONFIG MISALIGN:"
  foreach ($m in $mis) { Write-Line ("  - {0}" -f $m) }
}

Write-Line ""
Write-Line "=== HTTP probes ==="
$probes = $creds.http_probes
$fail = $false
foreach ($prop in $probes.PSObject.Properties) {
  $label = $prop.Name
  $url = [string]$prop.Value
  if (-not $url) { continue }
  try {
    $resp = Invoke-WebRequest -Uri $url -Method GET -TimeoutSec 45 -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
    $code = [int]$resp.StatusCode
    Write-Line ("  {0} -> HTTP {1}" -f $label, $code)
    if ($label -eq "health_canonical" -and $code -ge 400) { $fail = $true }
  } catch {
    $code = 0
    if ($_.Exception.Response) {
      $code = [int]$_.Exception.Response.StatusCode.value__
    }
    Write-Line ("  {0} -> HTTP {1} ({2})" -f $label, $code, $_.Exception.Message)
    if ($label -eq "health_canonical") { $fail = $true }
    if ($label -eq "health_legacy_prefix" -and $code -eq 301) {
      Write-Line "    (301 on legacy path is OK when Option A + redirect rule is live)"
    }
  }
}

if ($mis.Count -gt 0) { exit 2 }
if ($fail) { exit 1 }
exit 0
