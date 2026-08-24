# Legacy name. Users run Merit-Hub.ps1 (one file).
# This forwards to Hub PHASE 2 (-OssPhase). Internal implementation: _oss.ps1
#Requires -Version 5.1
param(
    [string]$Go = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-MeritHubScript {
    foreach ($c in @(
            (Join-Path ([Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'Process')) 'Merit-Hub.ps1'),
            (Join-Path ([Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'User')) 'Merit-Hub.ps1'),
            'C:\Tools\Merit-Hub.ps1'
        )) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

Write-Host ''
Write-Host '  Merit-Hub is the only user script. OSS BootStrap is PHASE 2 inside Hub.' -ForegroundColor Yellow
$hub = Find-MeritHubScript
if ($hub) {
    Write-Host "  Launching $hub -OssPhase" -ForegroundColor Green
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $hub -OssPhase
    }
    else {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $hub -OssPhase
    }
    exit $LASTEXITCODE
}

Write-Host '  Merit-Hub.ps1 not found under MYMERITTOOLS / C:\Tools.' -ForegroundColor Yellow
Write-Host '  Falling back to internal _oss.ps1 (still PHASE 2 keys D/G/F/U/3).'
$oss = Join-Path $PSScriptRoot '_oss.ps1'
if (-not (Test-Path -LiteralPath $oss)) {
    Write-Error "Missing $oss"
    exit 1
}
. $oss
Invoke-OssPhaseMenu
