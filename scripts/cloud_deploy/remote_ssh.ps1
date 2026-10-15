param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("mkdir", "upload", "exec")]
  [string]$Action,

  [Parameter(Mandatory = $true)]
  [string]$HostName,

  [int]$Port = 22,

  [Parameter(Mandatory = $true)]
  [string]$UserName,

  [Parameter(Mandatory = $true)]
  [string]$Password,

  [string]$RemotePath = "",
  [string]$LocalPath = "",
  [string]$RemoteCommand = ""
)

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
  Write-Error "Posh-SSH module required. Run: Install-Module Posh-SSH -Scope CurrentUser -Force"
}

Import-Module Posh-SSH -ErrorAction Stop

$sec = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($UserName, $sec)

switch ($Action) {
  "mkdir" {
    if (-not $RemotePath) { throw "RemotePath required for mkdir" }
    $session = New-SSHSession -ComputerName $HostName -Port $Port -Credential $cred -AcceptKey -ErrorAction Stop
    try {
      $cmd = "mkdir -p " + ($RemotePath -replace "'", "'\\''")
      $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $cmd
      if ($result.ExitStatus -ne 0) {
        Write-Error ("mkdir failed: " + $result.Error)
      }
    } finally {
      Remove-SSHSession -SessionId $session.SessionId | Out-Null
    }
  }
  "upload" {
    if (-not $LocalPath -or -not $RemotePath) { throw "LocalPath and RemotePath required for upload" }
    if (-not (Test-Path $LocalPath)) { throw "Local file missing: $LocalPath" }
    $remoteDir = ($RemotePath -replace '\\', '/')
    if ($remoteDir -match '^(.+)/[^/]+$') {
      $parent = $Matches[1]
      & $PSCommandPath -Action mkdir -HostName $HostName -Port $Port -UserName $UserName -Password $Password -RemotePath $parent | Out-Null
    }
    Set-SCPItem -ComputerName $HostName -Port $Port -Credential $cred -Path $LocalPath -Destination $remoteDir -AcceptKey -ErrorAction Stop
  }
  "exec" {
    if (-not $RemoteCommand) { throw "RemoteCommand required for exec" }
    $session = New-SSHSession -ComputerName $HostName -Port $Port -Credential $cred -AcceptKey -ErrorAction Stop
    try {
      $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $RemoteCommand
      if ($result.Output) { Write-Output ($result.Output -join "`n") }
      if ($result.ExitStatus -ne 0) {
        if ($result.Error) { Write-Error $result.Error }
        exit $result.ExitStatus
      }
    } finally {
      Remove-SSHSession -SessionId $session.SessionId | Out-Null
    }
  }
}
