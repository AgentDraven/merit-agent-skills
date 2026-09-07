# MERIT root Hub launcher.
# Keep this file small and stable: the implementation lives under Merit-Hub/.
$ErrorActionPreference = 'Stop'
Write-Host 'MERIT launcher 0.5.179 | direct URI downloads' -ForegroundColor Cyan
$env:MERIT_HUB_LAUNCHER_VERSION = '0.5.179'
$implementation = Join-Path $PSScriptRoot 'Merit-Hub\Merit-Hub.ps1'
$url = 'https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1'
$folder = Split-Path -Parent $implementation
$staged = Join-Path $folder ('Merit-Hub.' + [guid]::NewGuid().ToString('N') + '.download.ps1')
try {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    if (Test-Path -LiteralPath $implementation -PathType Leaf) {
        Write-Host "MERIT Hub implementation found; refreshing it from GitHub ..." -ForegroundColor Yellow
    } else {
        Write-Host "MERIT Hub implementation missing; downloading it from GitHub ..." -ForegroundColor Cyan
    }
    $uri = [Uri]$url
    Write-Host "Source: $uri" -ForegroundColor DarkGray
    Invoke-WebRequest -UseBasicParsing -Uri $uri -Headers @{ 'Cache-Control' = 'no-cache' } -OutFile $staged -ErrorAction Stop
    # Decode UTF-8 explicitly; Windows PowerShell 5.1 needs a BOM when parsing.
    $hubText = [IO.File]::ReadAllText($staged, (New-Object Text.UTF8Encoding($false, $true)))
    $pinMatch = [regex]::Match($hubText, '"skillsPin"\s*:\s*"(skills-v[0-9]+\.[0-9]+\.[0-9]+)"')
    if (-not $pinMatch.Success) { throw 'Downloaded file has no MERIT skills pin; refusing to launch it.' }
    [IO.File]::WriteAllText($staged, $hubText, (New-Object Text.UTF8Encoding($true)))
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($staged, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count) { throw "Downloaded Hub failed parsing: $($parseErrors[0].Message)" }
    Move-Item -LiteralPath $staged -Destination $implementation -Force -ErrorAction Stop
    Write-Host "MERIT Hub downloaded | embedded skills pin: $($pinMatch.Groups[1].Value)" -ForegroundColor Green
    Write-Host "Starting: $implementation" -ForegroundColor Cyan
}
catch {
    throw "MERIT Hub refresh failed; no cached implementation was started.`nTarget: $implementation`nSource: $url`n$($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $staged) { Remove-Item -LiteralPath $staged -Force }
}

& $implementation @args
exit $LASTEXITCODE
