# MERIT Live CLI — public freemium tooling (merit-agent-skills).
# Version 0.2.0 — pre-1.0.0 GA; minor bumps until HumanBala approves 1.0.0.

param()

$MERIT_LIVE_VERSION = '0.3.1'
$ErrorActionPreference = 'Stop'
$DistRoot = $PSScriptRoot

$Command = if ($args.Count -gt 0) { "$($args[0])".ToLowerInvariant() } else { 'help' }
$Rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

function Write-MeritLiveHelp {
    Write-Host @"
merit-live.ps1 v$MERIT_LIVE_VERSION — public MERIT freemium CLI

Usage:
  .\merit-live.ps1 <command> [options]

Commands:
  version              Print version
  verify --path <dir>  Check consumer cfg (pins, portals, branding, no secrets in git)
  par scaffold         Copy PAR play shells + cfg/par_pins.json
  branding scaffold    Copy cfg/branding.json from template
  subs scaffold        Copy meritsubs/meritstore cfg templates
  app scaffold         Copy Vercel consumer app skeleton (package.json, vercel.json, api/, scripts/)
  admin gate demo-init Placeholder .env.local keys for MeritAdminGate demo (local only)
  portal publish       Publish portal/ to here.now (BYOK: HERENOW_API_KEY)
  deploy vercel        Scoped production deploy via npx vercel

Global:
  --path <repo-root>   Target consumer repo (default: current directory)
  --variant <name>     par scaffold: workbench | workbench-journal

Examples:
  .\merit-live.ps1 par scaffold --path C:\repos\merit-demo --variant workbench-journal
  .\merit-live.ps1 portal publish --path C:\repos\merit-demo --all
  .\merit-live.ps1 deploy vercel --path C:\repos\merit-demo

Vault operators: use merit-private-vault scripts\merit.ps1 for cert, env SSOT, operator-gate hash.
"@
}

function Get-ArgValue {
    param([string[]]$ArgList, [string]$Name)
    for ($i = 0; $i -lt $ArgList.Count; $i++) {
        if ($ArgList[$i] -eq $Name -and ($i + 1) -lt $ArgList.Count) {
            return $ArgList[$i + 1]
        }
    }
    return $null
}

function Test-ArgFlag {
    param([string[]]$ArgList, [string]$Name)
    return $ArgList -contains $Name
}

function Resolve-TargetRoot {
    param([string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--path'
    if ($p) {
        return (Resolve-Path $p).Path
    }
    return (Get-Location).Path
}

function Read-JsonFile {
    param([string]$Path)
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-JsonFile {
    param([string]$Path, [object]$Object)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $Object | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Invoke-MeritVerify {
    param([string]$Root)
    $fail = @()
    foreach ($rel in @('cfg/par_pins.json', 'cfg/branding.json')) {
        if (-not (Test-Path (Join-Path $Root $rel))) {
            $fail += "missing $rel"
        }
    }
    $gitignore = Join-Path $Root '.gitignore'
    if (Test-Path $gitignore) {
        $gi = Get-Content $gitignore -Raw
        foreach ($needle in @('.env.local', '.vercel')) {
            if ($gi -notmatch [regex]::Escape($needle)) {
                $fail += ".gitignore should list $needle"
            }
        }
    } else {
        $fail += 'missing .gitignore'
    }
    if ($fail.Count) {
        Write-Host "verify FAILED:`n$($fail -join "`n")"
        exit 1
    }
    Write-Host "verify OK: $Root"
}

function Invoke-ParScaffold {
    param([string]$Root, [string]$Variant)
    $pinsSrc = Join-Path $DistRoot 'cfg/par_pins.free.json'
    if (-not (Test-Path $pinsSrc)) { throw "missing distributor $pinsSrc" }
    $destCfg = Join-Path $Root 'cfg'
    New-Item -ItemType Directory -Force -Path $destCfg | Out-Null
    Copy-Item -LiteralPath $pinsSrc -Destination (Join-Path $destCfg 'par_pins.json') -Force

    $pins = Read-JsonFile (Join-Path $destCfg 'par_pins.json')
    $wb = $pins.packages.merit_workbench
    $playDir = Join-Path $Root 'play'
    New-Item -ItemType Directory -Force -Path $playDir | Out-Null

    $journalTags = ''
    if ($Variant -eq 'workbench-journal') {
        $jn = $pins.packages.journal
        $journalTags = @"
  <link rel="stylesheet" href="$($jn.artifacts.css.url)" integrity="$($jn.artifacts.css.sri)" crossorigin="anonymous">
  <script type="module" src="$($jn.artifacts.mjs.url)" integrity="$($jn.artifacts.mjs.sri)" crossorigin="anonymous"></script>
"@
    }

    $tplPath = Join-Path $DistRoot 'templates/consumer-static/play/index.html.template'
    if (Test-Path $tplPath) {
        $html = (Get-Content -LiteralPath $tplPath -Raw -Encoding UTF8) `
            -replace '\{\{PRODUCT_NAME\}\}', 'MERIT Play' `
            -replace '\{\{WORKBENCH_CSS_URL\}\}', $wb.artifacts.css.url `
            -replace '\{\{WORKBENCH_CSS_SRI\}\}', $wb.artifacts.css.sri `
            -replace '\{\{WORKBENCH_JS_URL\}\}', $wb.artifacts.js.url `
            -replace '\{\{WORKBENCH_JS_SRI\}\}', $wb.artifacts.js.sri `
            -replace '\{\{JOURNAL_TAGS\}\}', $journalTags
    } else {
        $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MERIT Play</title>
  <link rel="stylesheet" href="$($wb.artifacts.css.url)" integrity="$($wb.artifacts.css.sri)" crossorigin="anonymous">
</head>
<body>
  <header id="merit-header"><!-- operator branding via cfg/branding.json at runtime --></header>
  <main id="merit-workbench-mount"></main>
  <footer id="merit-footer"><small>MERIT Powered</small></footer>
  <script src="$($wb.artifacts.js.url)" integrity="$($wb.artifacts.js.sri)" crossorigin="anonymous"></script>
$journalTags
</body>
</html>
"@
    }
    Set-Content -LiteralPath (Join-Path $playDir 'index.html') -Value $html -Encoding UTF8

    $portalTpl = Join-Path $DistRoot 'templates/consumer-static/portal/index.html'
    $portalDir = Join-Path $Root 'portal'
    if (Test-Path $portalTpl) {
        New-Item -ItemType Directory -Force -Path $portalDir | Out-Null
        $portalHtml = (Get-Content -LiteralPath $portalTpl -Raw -Encoding UTF8) `
            -replace '\{\{PRODUCT_NAME\}\}', 'My MERIT Product' `
            -replace '\{\{PLAY_URL\}\}', '/play/'
        Set-Content -LiteralPath (Join-Path $portalDir 'index.html') -Value $portalHtml -Encoding UTF8
    }
    Write-Host "par scaffold OK ($Variant) -> $Root"
}

function Invoke-BrandingScaffold {
    param([string]$Root)
    $src = Join-Path $DistRoot 'cfg/branding.json.template'
    $dest = Join-Path $Root 'cfg/branding.json'
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dest -Force
    Write-Host "branding scaffold OK -> $dest"
}

function Invoke-SubsScaffold {
    param([string]$Root)
    $cfg = Join-Path $Root 'cfg'
    New-Item -ItemType Directory -Force -Path $cfg | Out-Null

    $sync = @{
        schema          = 'merit.merit_sync.v1'
        consumer_id     = 'YOUR_CONSUMER_ID'
        meritsubs_base  = '/api/meritsubs'
        meritstore_register_url = 'https://meritstore.vercel.app/YOUR_CONSUMER_ID/register'
        freemium_limits = 'cfg/freemium_limits.json'
        plus_sku        = 'cfg/plus_sku.json'
    }
    Write-JsonFile -Path (Join-Path $cfg 'merit-sync.json') -Object $sync

    $flSrc = Join-Path $DistRoot 'cfg/freemium_limits.json'
    $plusSrc = Join-Path $DistRoot 'cfg/plus_sku.json'
    if ((Resolve-Path $cfg).Path -ne (Resolve-Path (Join-Path $DistRoot 'cfg')).Path) {
        Copy-Item -LiteralPath $flSrc -Destination (Join-Path $cfg 'freemium_limits.json') -Force
        Copy-Item -LiteralPath $plusSrc -Destination (Join-Path $cfg 'plus_sku.json') -Force
    }

    $portalsTpl = Join-Path $DistRoot 'cfg/portals.json.template'
    if (Test-Path $portalsTpl) {
        Copy-Item -LiteralPath $portalsTpl -Destination (Join-Path $cfg 'portals.json') -Force
    }
    Write-Host "subs scaffold OK -> $cfg (edit consumer_id and register URL)"
}

function Invoke-AppScaffold {
    param([string]$Root)
    Write-Host "app scaffold: clone reference consumer Mr-PI-Bala/merit-demo or run:"
    Write-Host "  git clone https://github.com/Mr-PI-Bala/merit-demo.git $Root"
    Write-Host "Then: merit-live par scaffold, branding scaffold, subs scaffold"
}

function Invoke-AdminGateDemoInit {
    param([string]$Root)
    $envPath = Join-Path $Root '.env.local'
    $lines = @(
        '# MERIT Live demo — local MeritAdminGate placeholders only. Never commit real phrases.',
        'MERIT_ADMIN_GATE_DEMO=1',
        'OPERATOR_GATE_HASH_SLOT_1=replace-with-bcrypt-hash'
    )
    if (-not (Test-Path $envPath)) {
        Set-Content -LiteralPath $envPath -Value ($lines -join "`n") -Encoding UTF8
        Write-Host "admin gate demo-init created $envPath"
    } else {
        Write-Host "admin gate demo-init skipped (exists): $envPath"
    }
    $wlDest = Join-Path $Root 'cfg/operator_gate_wordlists.json'
    Copy-Item -LiteralPath (Join-Path $DistRoot 'cfg/operator_gate_wordlists.excerpt.json') -Destination $wlDest -Force
}

function Invoke-PortalPublish {
    param([string]$Root, [string[]]$ArgList)
    $publishAll = Test-ArgFlag -ArgList $ArgList -Name '--all'
    $surface = Get-ArgValue -ArgList $ArgList -Name '--surface'
    if (-not $env:HERENOW_API_KEY -and -not (Test-Path "$env:USERPROFILE\.herenow\credentials")) {
        Write-Host 'portal publish: set HERENOW_API_KEY or ~/.herenow/credentials (BYOK).'
        Write-Host 'See https://here.now/docs — publish portal/ paths only.'
        exit 1
    }
    $portalsPath = Join-Path $Root 'cfg/portals.json'
    if ($publishAll -and (Test-Path $portalsPath)) {
        $portals = Read-JsonFile $portalsPath
        foreach ($s in $portals.surfaces) {
            $sub = Join-Path $Root $s.path
            if (Test-Path $sub) {
                Write-Host "publish surface $($s.id): $($s.path) -> $($s.slug).here.now (use here.now CLI/skill)"
            }
        }
    } else {
        $sub = if ($surface) { "portal/$surface/" } else { 'portal/' }
        Write-Host "publish $sub from $Root (use here.now CLI: npx skills add heredotnow/skill --skill here-now -g)"
    }
    Write-Host 'portal publish: invoke here.now publish per surface; merit-live documents BYOK workflow.'
}

function Invoke-DeployVercel {
    param([string]$Root)
    $deployCfg = Join-Path $Root 'cfg/flask_deploy.json'
    $scope = $null
    if (Test-Path $deployCfg) {
        $cfg = Read-JsonFile $deployCfg
        $scope = $cfg.vercel_scope
    }
    if (-not $scope) {
        Write-Host 'deploy vercel: missing cfg/flask_deploy.json vercel_scope — add scope from your Vercel team.'
        exit 1
    }
    Push-Location $Root
    try {
        if (Test-Path 'package.json') {
            npm run build 2>$null
        }
        $args = @('--prod', '--scope', $scope)
        Write-Host "npx vercel $($args -join ' ')"
        & npx vercel @args
    } finally {
        Pop-Location
    }
}

# --- dispatch ---
$sub = $Command
$target = Resolve-TargetRoot -ArgList $Rest

switch -Regex ($sub) {
    '^(help|\?)$' { Write-MeritLiveHelp; exit 0 }
    '^version$' { Write-Host "merit-live $MERIT_LIVE_VERSION"; exit 0 }
    '^verify$' { Invoke-MeritVerify -Root $target; exit 0 }
    '^par$' {
        if (-not $Rest -or $Rest[0] -ne 'scaffold') { Write-MeritLiveHelp; exit 1 }
        $variant = Get-ArgValue -ArgList $Rest -Name '--variant'
        if (-not $variant) { $variant = 'workbench' }
        Invoke-ParScaffold -Root $target -Variant $variant
        exit 0
    }
    '^branding$' {
        if ($Rest[0] -ne 'scaffold') { Write-MeritLiveHelp; exit 1 }
        Invoke-BrandingScaffold -Root $target
        exit 0
    }
    '^subs$' {
        if ($Rest[0] -ne 'scaffold') { Write-MeritLiveHelp; exit 1 }
        Invoke-SubsScaffold -Root $target
        exit 0
    }
    '^app$' {
        if (-not $Rest -or $Rest[0] -ne 'scaffold') { Write-MeritLiveHelp; exit 1 }
        Invoke-AppScaffold -Root $target
        exit 0
    }
    '^admin$' {
        if ($Rest[0] -ne 'gate' -or $Rest[1] -ne 'demo-init') { Write-MeritLiveHelp; exit 1 }
        Invoke-AdminGateDemoInit -Root $target
        exit 0
    }
    '^portal$' {
        if ($Rest[0] -ne 'publish') { Write-MeritLiveHelp; exit 1 }
        Invoke-PortalPublish -Root $target -ArgList $Rest
        exit 0
    }
    '^deploy$' {
        if ($Rest[0] -ne 'vercel') { Write-MeritLiveHelp; exit 1 }
        Invoke-DeployVercel -Root $target
        exit 0
    }
    default { Write-MeritLiveHelp; exit 1 }
}
