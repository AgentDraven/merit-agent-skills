# MERIT root Hub launcher.
# Keep this file small and stable: the implementation lives under Merit-Hub/.
$ErrorActionPreference = 'Stop'
$implementation = Join-Path $PSScriptRoot 'Merit-Hub\Merit-Hub.ps1'
if (-not (Test-Path -LiteralPath $implementation -PathType Leaf)) {
    $url = 'https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1'
    $folder = Split-Path -Parent $implementation
    try {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        Write-Host "MERIT Hub implementation missing; downloading $url ..." -ForegroundColor Cyan
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $implementation
    }
    catch {
        throw "MERIT Hub implementation not found and download failed: $implementation`n$url`n$($_.Exception.Message)"
    }
    if (-not (Test-Path -LiteralPath $implementation -PathType Leaf)) {
        throw "MERIT Hub implementation download did not produce: $implementation"
    }
}

& $implementation @args
exit $LASTEXITCODE
