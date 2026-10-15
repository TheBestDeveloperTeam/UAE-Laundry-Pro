param(
  [switch]$Quiet
)

$ErrorActionPreference = "Continue"
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
$ssh = $creds.ssh
$ftp = $creds.ftp

$sshHosts = @($ssh.host, "laundrypro-cloudapi.magnificentsolution.co.in", "magnificentsolution.co.in", "209.133.207.90") | Select-Object -Unique
$sshPorts = @([int]$ssh.port, 2222, 21098) | Select-Object -Unique

function Write-Status([string]$msg) {
  if (-not $Quiet) { Write-Host $msg }
}

$sshOk = $false
$recommendedHost = $ssh.host
$recommendedPort = [int]$ssh.port
$openTargets = @()

Write-Status "=== TCP (SSH targets) ==="
foreach ($h in $sshHosts) {
  if (-not $h) { continue }
  foreach ($p in $sshPorts) {
    $r = Test-NetConnection -ComputerName $h -Port $p -WarningAction SilentlyContinue
    $st = if ($r.TcpTestSucceeded) { "OPEN" } else { "closed" }
    Write-Status ("  {0}:{1} -> {2}" -f $h, $p, $st)
    if ($r.TcpTestSucceeded) {
      $openTargets += @{ Host = $h; Port = $p }
    }
  }
}

Write-Status ""
Write-Status "=== SSH shell auth ==="
$identity = $ssh.identity_file
$hasKey = $identity -and (Test-Path $identity)
$remoteCmd = "echo SSH_OK"

if ($openTargets.Count -eq 0) {
  Write-Status "  (skipped: no open TCP ports on SSH candidates)"
}

foreach ($t in $openTargets) {
  $h = $t.Host
  $p = $t.Port
    if ($hasKey) {
      $out = & ssh -i $identity -p $p -o BatchMode=yes -o ConnectTimeout=12 -o StrictHostKeyChecking=accept-new ($ssh.username + "@" + $h) $remoteCmd 2>&1
      if ($LASTEXITCODE -eq 0 -and ($out -match "SSH_OK")) {
        Write-Status ("  KEY OK: {0}@{1}:{2}" -f $ssh.username, $h, $p)
        $sshOk = $true
        $recommendedHost = $h
        $recommendedPort = $p
        break
      }
    }
    if ($ssh.password -and (Get-Module -ListAvailable Posh-SSH)) {
      Import-Module Posh-SSH -ErrorAction SilentlyContinue | Out-Null
      try {
        $sec = ConvertTo-SecureString $ssh.password -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($ssh.username, $sec)
        $session = New-SSHSession -ComputerName $h -Port $p -Credential $cred -AcceptKey -ConnectionTimeout 12 -ErrorAction Stop
        $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $remoteCmd
        Remove-SSHSession -SessionId $session.SessionId | Out-Null
        $outText = $result.Output -join [Environment]::NewLine
        if ($result.ExitStatus -eq 0 -and ($outText -match "SSH_OK")) {
          Write-Status ("  PASSWORD OK: {0}@{1}:{2}" -f $ssh.username, $h, $p)
          $sshOk = $true
          $recommendedHost = $h
          $recommendedPort = $p
          break
        }
      } catch {
        if (-not $Quiet) {
          Write-Status ("  password @ {0}:{1} -> {2}" -f $h, $p, $_.Exception.Message)
        }
      }
    }
  if ($sshOk) { break }
}

Write-Status ""
Write-Status "=== FTP / SFTP (diagnostic) ==="
$ftpHost = if ($ftp.host) { $ftp.host } else { "magnificentsolution.co.in" }
foreach ($p in @(21, [int]$ftp.port, 22)) {
  $r = Test-NetConnection -ComputerName $ftpHost -Port $p -WarningAction SilentlyContinue
  $st = if ($r.TcpTestSucceeded) { "OPEN" } else { "closed" }
  Write-Status ("  FTP TCP {0}:{1} -> {2}" -f $ftpHost, $p, $st)
}

$ftpOk = $false
$ftpPort = if ($ftp.port) { [int]$ftp.port } else { 21 }
$ftpScript = Join-Path $PSScriptRoot "remote_ftp.ps1"
if ($ftp.username -and $ftp.password -and (Test-Path $ftpScript)) {
  try {
    & $ftpScript -Action list -HostName $ftpHost -Port $ftpPort -UserName $ftp.username -Password $ftp.password -RemoteBasePath $ftp.remote_path 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
      $ftpOk = $true
      Write-Status ("  FTP login OK on port {0}" -f $ftpPort)
    }
  } catch {
    Write-Status ("  FTP login failed: {0}" -f $_.Exception.Message)
  }
}

Write-Status ""
if ($sshOk) {
  Write-Status "SSH_OK - set in credentials.ini:"
  Write-Status ("  host={0}" -f $recommendedHost)
  Write-Status ("  port={0}" -f $recommendedPort)
  exit 0
}

if ($ftpOk) {
  Write-Status "FTP_OK - use: .\scripts\cloud_deploy.ps1 -Transport Ftp"
  Write-Status "  Set DEPLOY_AUTOMATION_TOKEN in cloud-api/.env + deploy_automation_token in credentials.ini"
  exit 0
}

Write-Status "SSH and FTP failed - cPanel checklist:"
Write-Status "  1. Enable SSH or verify FTP account on port 21"
Write-Status "  2. Set ftp_* and deploy_automation_token in credentials.ini"
Write-Status "  3. For FTP path: Transport Ftp runs HTTPS apply (needs token on server)"
exit 1
