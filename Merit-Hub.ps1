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

# Windows PowerShell 5.1 can misread a UTF-8-without-BOM download (especially
# box-drawing and arrow characters) and report false parser errors. Normalize
# the fetched/current implementation to UTF-8 with BOM before invoking it.
try {
    $hubText = [IO.File]::ReadAllText($implementation)
    [IO.File]::WriteAllText($implementation, $hubText, (New-Object Text.UTF8Encoding($true)))
}
catch {
    throw "MERIT Hub implementation could not be normalized for Windows PowerShell: $implementation`n$($_.Exception.Message)"
}

& $implementation @args
exit $LASTEXITCODE
