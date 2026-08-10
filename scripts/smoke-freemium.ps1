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
if ($html -notmatch "pathHtml\('Ask'" -or $html -notmatch "pathHtml\('Meet'" -or $html -notmatch "pathHtml\('Book'" -or $html -notmatch "pathHtml\('Journal'" -or $html -notmatch "Join free to ask") {
    throw "play shell missing Make Art capability paths (Ask/Meet/Book/Journal)"
}
if ($html -notmatch 'How it comes together') { throw "play shell missing composition section" }
if ($html -notmatch 'ma-table') { throw "play shell missing Plans table ma-table (FR-MPD-42)" }
if ($html -notmatch 'id=.plans.') { throw "play shell missing #plans (FR-MPD-42)" }
if ($html -notmatch 'class=.geek.') { throw "play shell missing Advanced geek disclosure" }
if ($html -match 'mountMeritWorkbenchPanel') { throw "play shell must NOT default-mount workbench (BUG-MPD-PLAY-02)" }
if ($html -match 'Your MERIT rails') { throw "play shell must NOT show operator rails grid as Advanced" }
if ($html -match 'community-rails/evidence/') { throw "play shell must NOT use e2e evidence as product art (BUG-MPD-PLAY-01)" }
if ($html -notmatch 'app_logic') { throw "play shell missing app_logic next-step callout" }
if ($html -notmatch '/store/.*/register') { throw "play shell missing store register path for this app" }
if ($html -notmatch 'community-member') { throw "play shell missing community-member plan id (FR-MPD-41)" }
if ($html -notmatch 'plus-monthly') { throw "play shell missing plus-monthly plan (FR-MPD-41)" }
if ($html -notmatch 'community-rails') { throw "play shell missing community-rails geek link" }
if ($html -notmatch 'merit-ux-brand|brand__moniker|useDefaultFlanks|merit-ux-brand__wordmark') {
    throw "play shell missing brand moniker band (Gotcha D1 / AP-MA-01)"
}
if ($html -notmatch 'merit-ux-legal|Powered by MERIT|MERIT Powered') {
    throw "play shell missing legal footer Powered by MERIT (Gotcha D6)"
}
if ($html -match 'FR-MPD-\d+.*dogfood|Make Art dogfood') {
    throw "play shell must not expose FR dogfood strings on member path (AP-MA-04)"
}
if ($html -notmatch 'hideCta|loginChooser|ma-login-fallback|You are') {
    throw "play shell missing guest/free/Plus identity chrome (FR-MPD-38/43)"
}

$cat = Join-Path $ScratchRoot 'cfg\store_catalog.json'
if (-not (Test-Path $cat)) { throw "subs scaffold missing cfg/store_catalog.json (FR-MPD-40)" }

$pins = Get-Content (Join-Path $ScratchRoot 'cfg\par_pins.json') -Raw | ConvertFrom-Json
$uxUrl = $pins.packages.merit_ux.artifacts.js.url
Write-Host "HEAD $uxUrl"
try {
    $r = Invoke-WebRequest -Uri $uxUrl -Method Head -UseBasicParsing -TimeoutSec 30
    if ($r.StatusCode -ge 400) { throw "PAR CDN HEAD failed: $($r.StatusCode)" }
} catch {
    Write-Warning "PAR CDN HEAD skipped or failed (offline?): $_"
}

Write-Host "[OK] freemium smoke passed (Make Art DualRail home)" -ForegroundColor Green
Write-Host "here.now publish: set HERENOW_API_KEY and run merit portal on a consumer with portal/"
