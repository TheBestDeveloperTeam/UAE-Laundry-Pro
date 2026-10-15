param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("upload", "download", "downloadLogs", "list", "rename")]
  [string]$Action,

  [string]$RemoteRenameTo = "",

  [Parameter(Mandatory = $true)]
  [string]$HostName,

  [int]$Port = 21,

  [Parameter(Mandatory = $true)]
  [string]$UserName,

  [Parameter(Mandatory = $true)]
  [string]$Password,

  [string]$RemoteBasePath = "",
  [string]$LocalFile = "",
  [string]$RemoteRelativePath = "deploy_staging/cloud-cpanel-upload.zip",
  [string]$LocalLogDir = ""
)

$ErrorActionPreference = "Stop"

function Get-FtpUri([string]$path) {
  $p = $path.TrimStart("/").Replace("\", "/")
  return "ftp://${HostName}:${Port}/$p"
}

function Invoke-Ftp([string]$uri, [string]$method, [byte[]]$content = $null) {
  $request = [System.Net.FtpWebRequest]::Create($uri)
  $request.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
  $request.Method = $method
  $request.UseBinary = $true
  $request.UsePassive = $true
  $request.KeepAlive = $false
  if ($content -ne $null) {
    $request.ContentLength = $content.Length
    $stream = $request.GetRequestStream()
    $stream.Write($content, 0, $content.Length)
    $stream.Close()
  }
  $response = $request.GetResponse()
  $response.Close() | Out-Null
}

function Ensure-FtpDirectory([string]$dirPath) {
  $parts = $dirPath.Trim("/").Split("/")
  $built = ""
  foreach ($part in $parts) {
    if ($part -eq "") { continue }
    $built = if ($built -eq "") { $part } else { "$built/$part" }
    try {
      Invoke-Ftp (Get-FtpUri $built) ([System.Net.WebRequestMethods+Ftp]::MakeDirectory)
    } catch {
      # exists
    }
  }
}

$base = $RemoteBasePath.TrimEnd("/")

switch ($Action) {
  "upload" {
    if (-not $LocalFile -or -not (Test-Path $LocalFile)) { throw "LocalFile missing: $LocalFile" }
    $remoteDir = ($RemoteRelativePath -replace "/[^/]+$", "").TrimEnd("/")
    if ($remoteDir) { Ensure-FtpDirectory "$base/$remoteDir" }
    $remoteFull = "$base/$RemoteRelativePath".Replace("//", "/")
    $bytes = [System.IO.File]::ReadAllBytes($LocalFile)
    Invoke-Ftp (Get-FtpUri $remoteFull) ([System.Net.WebRequestMethods+Ftp]::UploadFile) $bytes
    Write-Host "Uploaded to $remoteFull"
  }
  "download" {
    if (-not $LocalFile) { throw "LocalFile required for download" }
    $remoteFull = "$base/$RemoteRelativePath".Replace("//", "/")
    $uri = Get-FtpUri $remoteFull
    $request = [System.Net.FtpWebRequest]::Create($uri)
    $request.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
    $request.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $request.UsePassive = $true
    $request.UseBinary = $true
    $response = $request.GetResponse()
    $parent = Split-Path -Parent $LocalFile
    if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $fs = [System.IO.File]::Create($LocalFile)
    $response.GetResponseStream().CopyTo($fs)
    $fs.Close()
    $response.Close()
    Write-Host "Downloaded $remoteFull -> $LocalFile"
  }
  "rename" {
    if (-not $RemoteRenameTo) { throw "RemoteRenameTo required for rename" }
    $from = "$base/$RemoteRelativePath".Replace("//", "/")
    $to = "$base/$RemoteRenameTo".Replace("//", "/")
    $request = [System.Net.FtpWebRequest]::Create((Get-FtpUri $from))
    $request.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
    $request.Method = [System.Net.WebRequestMethods+Ftp]::Rename
    $request.RenameTo = $to
    $request.UsePassive = $true
    $response = $request.GetResponse()
    $response.Close() | Out-Null
    Write-Host "Renamed $from -> $to"
  }
  "list" {
    $uri = Get-FtpUri $base
    $request = [System.Net.FtpWebRequest]::Create($uri)
    $request.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
    $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $request.UsePassive = $true
    $response = $request.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    Write-Output $reader.ReadToEnd()
    $reader.Close()
    $response.Close()
  }
  "downloadLogs" {
    if (-not $LocalLogDir) { $LocalLogDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "dist\cloud-logs" }
    New-Item -ItemType Directory -Force -Path $LocalLogDir | Out-Null
    $logRemote = "$base/cloud-api/logs"
    $uri = Get-FtpUri $logRemote
    $request = [System.Net.FtpWebRequest]::Create($uri)
    $request.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
    $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $request.UsePassive = $true
    try {
      $response = $request.GetResponse()
      $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
      $listing = $reader.ReadToEnd()
      $reader.Close()
      $response.Close()
    } catch {
      Write-Host "Log list failed: $_"
      return
    }
    foreach ($name in ($listing -split "`r?`n")) {
      $name = $name.Trim()
      if ($name -eq "" -or -not $name.EndsWith(".log")) { continue }
      $remoteFile = "$logRemote/$name"
      $localPath = Join-Path $LocalLogDir $name
      $dl = [System.Net.FtpWebRequest]::Create((Get-FtpUri $remoteFile))
      $dl.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
      $dl.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
      $dl.UsePassive = $true
      $dl.UseBinary = $true
      $resp = $dl.GetResponse()
      $fs = [System.IO.File]::Create($localPath)
      $resp.GetResponseStream().CopyTo($fs)
      $fs.Close()
      $resp.Close()
      Write-Host "Downloaded $name"
    }
  }
}
