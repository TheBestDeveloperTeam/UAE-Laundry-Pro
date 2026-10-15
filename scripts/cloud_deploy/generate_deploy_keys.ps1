param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$KeyBase = Join-Path $RepoRoot "cloud-laudry-pro-ssh"
$Priv = $KeyBase
$Pub = "$KeyBase.pub"

if ((Test-Path $Pub) -and -not $Force) {
  Write-Host "Keys already exist: $Pub"
  Write-Host "Re-run with -Force to replace."
  ssh-keygen -lf $Pub
  exit 0
}

if ($Force) {
  Remove-Item -Force -ErrorAction SilentlyContinue $Priv, $Pub
}

$sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
if (-not $sshKeygen) {
  throw "ssh-keygen not found (install OpenSSH Client)."
}

& ssh-keygen -t rsa -b 4096 -f $Priv -N '""' -C "laundrypro-cloud-deploy"
Write-Host ""
Write-Host "Public key (authorize in cPanel SSH Access for user cloud-laudry-pro-ssh):"
Write-Host ""
Get-Content $Pub
Write-Host ""
ssh-keygen -lf $Pub
