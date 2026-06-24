# Freemium smoke — merit-live PAR + verify (no BYOK required for local phase)
param(
    [string]$SkillsRoot = "$PSScriptRoot\..",
    [string]$ScratchRoot = "$env:TEMP\merit-live-smoke"
)

$ErrorActionPreference = 'Stop'
$live = Join-Path $SkillsRoot 'merit-live.ps1'
if (-not (Test-Path $live)) { throw "merit-live.ps1 not found: $live" }

Write-Host "=== merit-live freemium smoke ===" -ForegroundColor Cyan
if (Test-Path $ScratchRoot) { Remove-Item -Recurse -Force $ScratchRoot }
New-Item -ItemType Directory -Force -Path $ScratchRoot | Out-Null

# Minimal consumer gitignore
@"
.env.local
.vercel
node_modules/
dist/
"@ | Set-Content (Join-Path $ScratchRoot '.gitignore') -Encoding UTF8

& $live par scaffold --path $ScratchRoot --variant workbench-journal
& $live branding scaffold --path $ScratchRoot
& $live subs scaffold --path $ScratchRoot
& $live verify --path $ScratchRoot

$play = Join-Path $ScratchRoot 'play\index.html'
if (-not (Test-Path $play)) { throw "missing play/index.html" }
$html = Get-Content $play -Raw
if ($html -notmatch 'pkg-meritutils\.vercel\.app') { throw "play shell missing PAR CDN URL" }
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
Write-Host "here.now publish: set HERENOW_API_KEY and run portal publish --all on a consumer with portal/"
