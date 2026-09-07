# MERIT root Hub launcher.
# Keep this file small and stable: the implementation lives under Merit-Hub/.
$ErrorActionPreference = 'Stop'
$implementation = Join-Path $PSScriptRoot 'Merit-Hub\Merit-Hub.ps1'
$url = 'https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1'
$versionUrl = 'https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/VERSION'
$folder = Split-Path -Parent $implementation
try {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    if (Test-Path -LiteralPath $implementation -PathType Leaf) {
        Write-Host "MERIT Hub implementation found; refreshing it from GitHub ..." -ForegroundColor Yellow
    } else {
        Write-Host "MERIT Hub implementation missing; downloading it from GitHub ..." -ForegroundColor Cyan
    }
    $cacheBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    Invoke-WebRequest -UseBasicParsing -Uri "$url?v=$cacheBust" -OutFile $implementation
    $remoteVersion = ((Invoke-WebRequest -UseBasicParsing -Uri "$versionUrl?v=$cacheBust").Content).Trim()
    Write-Host "MERIT Hub downloaded: skills-v$remoteVersion" -ForegroundColor Green
}
catch {
    throw "MERIT Hub implementation download failed: $implementation`n$url`n$($_.Exception.Message)"
}
if (-not (Test-Path -LiteralPath $implementation -PathType Leaf)) {
    throw "MERIT Hub implementation download did not produce: $implementation"
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
