#Requires -Version 5.1
<#
.SYNOPSIS
  Install Merit-Hub from this repo folder to %MYMERITTOOLS%\Merit-Hub.
#>
param(
    [string]$Target = $null
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
if (-not (Test-Path (Join-Path $src 'Merit-Hub.ps1'))) {
    throw "Run from merit-agent-skills/Merit-Hub (Merit-Hub.ps1 missing)."
}
if ([string]::IsNullOrWhiteSpace($Target)) {
    $cfgPath = Join-Path $src 'Merit-Hub.json'
    if (Test-Path $cfgPath) {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        $tools = if ($env:OS -match 'Windows') { $cfg.defaultMyMeritToolsWindows } else { $cfg.defaultMyMeritToolsUnix }
        $tools = $tools -replace '^~', $HOME
        $Target = Join-Path $tools 'Merit-Hub'
    }
    else {
        $Target = if ($env:OS -match 'Windows') { 'C:\Tools\Merit-Hub' } else { Join-Path $HOME 'Tools/Merit-Hub' }
    }
}
New-Item -ItemType Directory -Force -Path $Target | Out-Null
$exclude = @('backups', 'install.ps1')
Get-ChildItem -LiteralPath $src -Force | Where-Object {
    $_.Name -notin $exclude -and $_.Name -notlike '.*'
} | ForEach-Object {
    $dest = Join-Path $Target $_.Name
    if ($_.PSIsContainer) {
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
    }
}
Write-Host "[OK] Merit-Hub installed -> $Target"
Write-Host "Run: cd `"$Target`" ; .\Merit-Hub.cmd"
