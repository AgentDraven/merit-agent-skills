#Requires -Version 5.1
<#
.SYNOPSIS
  Process-scoped OSS bench for a second (or Nth) OC creator on one laptop.

  Tools stay shared (MYMERITTOOLS). Only MYMERITAPP changes. Does not SET User env.

.EXAMPLE
  pwsh -NoProfile -File .\oc-bench.ps1 -Name creator-01 -ProductName 'Creator 01 DualRail' -All
  pwsh -NoProfile -File .\oc-bench.ps1 -Name creator-02 -ProductName 'Creator 02 DualRail' -All -NewOc
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [string]$ProductName = '',
    [string]$ToolsRoot = '',
    [string]$BenchRoot = '',
    [switch]$InstallOss,
    [switch]$TryIt,
    [switch]$Oc,
    [switch]$NewOc,
    [switch]$All
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($All) {
    $InstallOss = $true
    $TryIt = $true
    $Oc = $true
}

$env:MERIT_HUB_NO_PERSIST_ENV = '1'
$env:MERIT_HUB_NO_ELEVATE = '1'
if ($ProductName) { $env:MERIT_OC_PRODUCT_NAME = $ProductName }

if ([string]::IsNullOrWhiteSpace($ToolsRoot)) {
    $ToolsRoot = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'Process')
    if ([string]::IsNullOrWhiteSpace($ToolsRoot)) {
        $ToolsRoot = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'User')
    }
    if ([string]::IsNullOrWhiteSpace($ToolsRoot)) { $ToolsRoot = 'C:\MyMeritTools' }
}
if ([string]::IsNullOrWhiteSpace($BenchRoot)) { $BenchRoot = 'C:\MyMeritApps\benches' }

$env:MYMERITTOOLS = $ToolsRoot
$env:MYMERITAPP = Join-Path $BenchRoot $Name
New-Item -ItemType Directory -Force -Path $env:MYMERITAPP | Out-Null

$hub = Join-Path $PSScriptRoot 'Merit-Hub.ps1'
if (-not (Test-Path -LiteralPath $hub)) {
    $hub = 'C:\Tools\Merit-Hub.ps1'
}
if (-not (Test-Path -LiteralPath $hub)) {
    throw "Merit-Hub.ps1 not found next to this script or at C:\Tools\Merit-Hub.ps1"
}

Write-Host "oc-bench name=$Name"
Write-Host "  MYMERITTOOLS=$($env:MYMERITTOOLS)  (shared)"
Write-Host "  MYMERITAPP=$($env:MYMERITAPP)  (this creator only, Process)"
Write-Host "  User env not written (MERIT_HUB_NO_PERSIST_ENV=1)"

$runner = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }

function Invoke-HubStep {
    param([string[]]$HubArgs)
    & $runner -NoProfile -File $hub @HubArgs
    if ($LASTEXITCODE -ne 0) { throw "Hub $($HubArgs -join ' ') exit $LASTEXITCODE" }
}

if ($InstallOss) { Invoke-HubStep -HubArgs @('-InstallOss') }
if ($TryIt) { Invoke-HubStep -HubArgs @('-TryIt') }
if ($Oc -or $NewOc) {
    $ocArgs = @('-Oc')
    if ($NewOc) { $ocArgs += '-NewOc' }
    Invoke-HubStep -HubArgs $ocArgs
}

$statePath = Join-Path $env:MYMERITAPP 'oss-bench.json'
if (Test-Path -LiteralPath $statePath) {
    Write-Host "Receipt file: $statePath"
}
