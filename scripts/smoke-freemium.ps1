# Freemium smoke - merit CLI PAR + verify (no BYOK required for local phase)
param(
    [string]$SkillsRoot = "$PSScriptRoot\..",
    [string]$ScratchRoot = ''
)

$ErrorActionPreference = 'Stop'
if (-not $ScratchRoot) {
    $baseTemp = if ($env:TEMP) { $env:TEMP } elseif ($env:TMPDIR) { $env:TMPDIR } else { [System.IO.Path]::GetTempPath() }
    $ScratchRoot = Join-Path $baseTemp 'merit-smoke'
}
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
if ($html -notmatch 'createAppShell') { throw "play shell missing DualRail Gloss createAppShell" }
if ($html -notmatch 'MeritUx|merit_ux') { throw "play shell missing merit_ux / MeritUx" }
if ($html -notmatch 'gloss-aurora|gloss-graphite|gloss-daylight') { throw "play shell missing GlossPack theme" }
if ($html -notmatch 'data-tour="ask"') { throw "play shell missing Value Tour Ask" }
if ($html -notmatch 'data-tour="meet"' -or $html -notmatch 'data-tour="book"' -or $html -notmatch 'data-tour="journal"') {
    throw "play shell missing Value Tour Meet/Book/Journal"
}
if ($html -notmatch 'class="geek"') { throw "play shell missing Advanced geek disclosure" }
if ($html -notmatch 'mountMeritWorkbenchPanel') { throw "play shell missing Advanced workbench (mountMeritWorkbenchPanel)" }
if ($html -notmatch 'Your MERIT rails') { throw "play shell missing Advanced capability tour (Your MERIT rails)" }
if ($html -notmatch 'app_logic') { throw "play shell missing app_logic next-step callout" }
if ($html -notmatch '/store/.*/register') { throw "play shell missing store register path for this app" }
if ($html -notmatch 'community-rails') { throw "play shell missing community-rails proof links" }

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
