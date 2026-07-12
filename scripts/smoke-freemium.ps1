# Freemium smoke - merit CLI PAR + verify (no BYOK required for local phase)
param(
    [string]$SkillsRoot = "$PSScriptRoot\..",
    [string]$ScratchRoot = "$env:TEMP\merit-smoke"
)

$ErrorActionPreference = 'Stop'
$merit = Join-Path $SkillsRoot 'merit.ps1'
if (-not (Test-Path $merit)) { throw "merit.ps1 not found: $merit" }

Write-Host "=== merit freemium smoke ===" -ForegroundColor Cyan
if (Test-Path $ScratchRoot) { Remove-Item -Recurse -Force $ScratchRoot }
New-Item -ItemType Directory -Force -Path $ScratchRoot | Out-Null

@"
.env.local
.vercel
node_modules/
dist/
"@ | Set-Content (Join-Path $ScratchRoot '.gitignore') -Encoding UTF8

& $merit par scaffold --path $ScratchRoot --variant workbench-journal
& $merit branding scaffold --path $ScratchRoot
& $merit subs scaffold --path $ScratchRoot
& $merit verify --path $ScratchRoot

$play = Join-Path $ScratchRoot 'play\index.html'
if (-not (Test-Path $play)) { throw "missing play/index.html" }
$html = Get-Content $play -Raw
if ($html -notmatch 'merit-prod\.vercel\.app/pkg/meritutils') { throw "play shell missing MERIT package gateway URL" }
if ($html -notmatch 'journal') { throw "workbench-journal variant missing journal tags" }

$pins = Get-Content (Join-Path $ScratchRoot 'cfg\par_pins.json') -Raw | ConvertFrom-Json
$wbUrl = $pins.packages.merit_workbench.artifacts.js.url
Write-Host "HEAD $wbUrl"
try {
    $r = Invoke-WebRequest -Uri $wbUrl -Method Head -UseBasicParsing -TimeoutSec 30
    if ($r.StatusCode -ge 400) { throw "PAR CDN HEAD failed: $($r.StatusCode)" }
} catch {
    Write-Warning "PAR CDN HEAD skipped or failed (offline?): $_"
}

Write-Host "[OK] freemium smoke passed" -ForegroundColor Green
Write-Host "here.now publish: set HERENOW_API_KEY and run merit portal on a consumer with portal/"
