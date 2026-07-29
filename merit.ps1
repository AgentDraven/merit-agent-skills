# MERIT public CLI — one entrypoint for free users.

param()

$ErrorActionPreference = 'Stop'
$MERIT_VERSION = '0.3.16'
$Root = $PSScriptRoot

$Command = if ($args.Count -gt 0) { "$($args[0])".ToLowerInvariant() } else { 'help' }
$Rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

function Write-MeritHelp {
    Write-Host @"
merit.ps1 v$MERIT_VERSION — public MERIT CLI

Use this one script for the free-user path.

Commands:
  init --path <repo>       Create .merit_launch.md and gitignore it
  apply --path <repo>      Read .merit_launch.md and generate config + .env.local
  verify --path <repo>     Verify local MERIT scaffold
  deploy --path <repo>     Apply launch file, link Vercel if needed, deploy production
  portal --path <repo>     Apply launch file, then publish here.now portal targets
  all --path <repo>        Apply, deploy Vercel, then publish portal targets
  closeout --path <repo>   Verify, run git whitespace check, and print git baseline
  par scaffold             Advanced: create play shell + cfg/par_pins.json
  branding scaffold        Advanced: create cfg/branding.json
  subs scaffold            Advanced: create meritsubs/meritstore cfg
  livealpha --path <repo>  Elevate consumer toward live alpha (Research + Baseline scaffold)
  baseline --path <repo>   Alias for livealpha
  admin gate demo-init     Advanced: create local demo operator-gate placeholders
  app scaffold             Print merit-demo clone guidance
  version                  Print version
  help                     Print help

Typical flow:
  .\merit.ps1 init --path ..\merit-demo
  # edit ..\merit-demo\.merit_launch.md
  .\merit.ps1 apply --path ..\merit-demo
  .\merit.ps1 deploy --path ..\merit-demo
"@
}

function Get-ArgValue {
    param([string[]]$ArgList, [string]$Name)
    for ($i = 0; $i -lt $ArgList.Count; $i++) {
        if ($ArgList[$i] -eq $Name -and ($i + 1) -lt $ArgList.Count) { return $ArgList[$i + 1] }
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
        if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
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
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Object | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Add-GitIgnoreLine {
    param([string]$TargetRoot, [string]$Line)
    $path = Join-Path $TargetRoot '.gitignore'
    if (Test-Path $path) {
        $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if ($text -match "(?m)^$([regex]::Escape($Line))$") { return }
        $prefix = if ($text.EndsWith("`n")) { '' } else { "`n" }
        [System.IO.File]::AppendAllText($path, "$prefix$Line`n", [System.Text.UTF8Encoding]::new($false))
    } else {
        [System.IO.File]::WriteAllText($path, "$Line`n", [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-LaunchPath {
    param([string]$TargetRoot, [string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--launch'
    if (-not $p) { $p = '.merit_launch.md' }
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $TargetRoot $p)
}

function Get-LaunchSettings {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Launch file not found: $Path. Run merit init --path <repo> first." }
    $settings = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trim = $line.Trim()
        if (-not $trim -or $trim.StartsWith('#') -or $trim.StartsWith('```') -or $trim.StartsWith('<!--')) { continue }
        $m = [regex]::Match($trim, '^([A-Za-z0-9_]+)\s*=\s*(.*)$')
        if ($m.Success) { $settings[$m.Groups[1].Value.ToLowerInvariant()] = $m.Groups[2].Value.Trim() }
    }
    return $settings
}

function Get-Setting {
    param([System.Collections.IDictionary]$Settings, [string]$Name, [string]$Default = '')
    $key = $Name.ToLowerInvariant()
    if ($Settings.Contains($key) -and $Settings[$key]) { return $Settings[$key] }
    return $Default
}

function Require-Setting {
    param([System.Collections.IDictionary]$Settings, [string]$Name)
    $value = Get-Setting -Settings $Settings -Name $Name
    if (-not $value) { throw ".merit_launch.md missing mandatory value: $Name" }
    return $value
}

function Set-EnvLocalValue {
    param([string]$Path, [string]$Name, [string]$Value)
    $lines = @()
    if (Test-Path $Path) { $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8) }
    $found = $false
    $out = foreach ($line in $lines) {
        if ($line -match "^$([regex]::Escape($Name))=") {
            $found = $true
            "$Name=$Value"
        } else {
            $line
        }
    }
    if (-not $found) { $out += "$Name=$Value" }
    Set-Content -LiteralPath $Path -Value $out -Encoding UTF8
}

function Write-EnvLocal {
    param([string]$TargetRoot, [System.Collections.IDictionary]$Settings, [string]$ConsumerId)
    $baseUrl = Get-Setting -Settings $Settings -Name 'meritsubs_public_base_url' -Default 'https://merit-prod.vercel.app/api/meritsubs'
    $lines = @(
        '# Generated by merit apply from .merit_launch.md. Do not commit.',
        "SUPABASE_URL=$(Require-Setting -Settings $Settings -Name 'supabase_url')",
        "SUPABASE_ANON_KEY=$(Require-Setting -Settings $Settings -Name 'supabase_anon_key')",
        "SUPABASE_SERVICE_ROLE_KEY=$(Require-Setting -Settings $Settings -Name 'supabase_service_role_key')",
        '',
        "MERIT_CONSUMER_ID=$ConsumerId",
        '',
        "MERIT_METERED_API_BASE_URL=$(Get-Setting -Settings $Settings -Name 'merit_metered_api_base_url' -Default 'https://merit-prod.vercel.app')",
        "MERITSUBS_PUBLIC_BASE_URL=$baseUrl",
        "MERITSTORE_BASE_URL=$(Get-Setting -Settings $Settings -Name 'meritstore_base_url' -Default 'https://merit-prod.vercel.app/store')",
        "MERIT_DEFAULT_PROMOCODE=$(Get-Setting -Settings $Settings -Name 'default_promocode' -Default 'MERITAGENT')",
        "MERIT_INTRO_CREDIT_USD=$(Get-Setting -Settings $Settings -Name 'intro_credit_usd' -Default '25')",
        "MERIT_VERCEL_LINKED=0",
        "MERIT_VERCEL_DEPLOYED=0"
    )
    $gate = Get-Setting -Settings $Settings -Name 'operator_gate_hash_slot_1'
    if ($gate) { $lines += @('', "OPERATOR_GATE_HASH_SLOT_1=$gate") }
    $here = Get-Setting -Settings $Settings -Name 'herenow_api_key'
    if ($here) { $lines += @('', "HERENOW_API_KEY=$here") }
    [System.IO.File]::WriteAllText((Join-Path $TargetRoot '.env.local'), ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Update-Branding {
    param([string]$TargetRoot, [System.Collections.IDictionary]$Settings)
    $path = Join-Path $TargetRoot 'cfg/branding.json'
    if (-not (Test-Path $path)) { return }
    $branding = Read-JsonFile $path
    $product = Get-Setting -Settings $Settings -Name 'product_name'
    $email = Get-Setting -Settings $Settings -Name 'operator_email'
    if ($product -and ($branding.PSObject.Properties.Name -contains 'product_name')) { $branding.product_name = $product }
    if ($email -and ($branding.PSObject.Properties.Name -contains 'operator_email')) { $branding.operator_email = $email }
    Write-JsonFile -Path $path -Object $branding
}

function Invoke-Init {
    param([string]$TargetRoot, [string[]]$ArgList)
    $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
    $template = Join-Path $Root 'templates/.merit_launch.md'
    if (-not (Test-Path $template)) { throw "missing template: $template" }
    if (Test-Path $launch) {
        Write-Host "init skipped (exists): $launch"
    } else {
        Copy-Item -LiteralPath $template -Destination $launch
        Write-Host "init OK: created $launch"
    }
    foreach ($line in @('.merit_launch.md', '.env.local', '.vercel')) { Add-GitIgnoreLine -TargetRoot $TargetRoot -Line $line }
}

function Invoke-Apply {
    param([string]$TargetRoot, [string[]]$ArgList)
    $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
    $settings = Get-LaunchSettings -Path $launch
    $consumerId = Require-Setting -Settings $settings -Name 'consumer_id'
    $scope = Require-Setting -Settings $settings -Name 'vercel_scope'
    $branch = Get-Setting -Settings $settings -Name 'production_branch' -Default 'main'
    $baseSlug = Get-Setting -Settings $settings -Name 'here_now_slug' -Default $consumerId
    Write-JsonFile -Path (Join-Path $TargetRoot 'cfg/flask_deploy.json') -Object ([ordered]@{
        project_id = $consumerId
        vercel_scope = $scope
        production_branch = $branch
        notes = "merit deploy links Vercel automatically when .vercel/project.json is missing."
    })
    Write-JsonFile -Path (Join-Path $TargetRoot 'cfg/portals.json') -Object ([ordered]@{
        schema = 'merit.portals.v1'
        surfaces = @(
            [ordered]@{ id = 'main'; path = 'portal/'; slug = (Get-Setting -Settings $settings -Name 'portal_main_slug' -Default $baseSlug) },
            [ordered]@{ id = 'journal'; path = 'portal/journal/'; slug = (Get-Setting -Settings $settings -Name 'portal_journal_slug' -Default "$baseSlug-journal") },
            [ordered]@{ id = 'ama'; path = 'portal/ama/'; slug = (Get-Setting -Settings $settings -Name 'portal_ama_slug' -Default "$baseSlug-ama") },
            [ordered]@{ id = 'subs'; path = 'portal/subs/'; slug = (Get-Setting -Settings $settings -Name 'portal_subs_slug' -Default "$baseSlug-subs") }
        )
        notes = 'Generated by merit apply from .merit_launch.md.'
    })
    Write-EnvLocal -TargetRoot $TargetRoot -Settings $settings -ConsumerId $consumerId
    Update-Branding -TargetRoot $TargetRoot -Settings $settings
    foreach ($line in @('.merit_launch.md', '.env.local', '.vercel')) { Add-GitIgnoreLine -TargetRoot $TargetRoot -Line $line }
    Write-Host "apply OK: .merit_launch.md -> .env.local, cfg/flask_deploy.json, cfg/portals.json"
}

function Invoke-Verify {
    param([string]$TargetRoot)
    $fail = @()
    $isSkillsRepo = (Test-Path (Join-Path $TargetRoot 'skills')) -and
        (Test-Path (Join-Path $TargetRoot 'templates')) -and
        (Test-Path (Join-Path $TargetRoot 'merit.ps1'))
    if ($isSkillsRepo) {
        foreach ($rel in @('docs/usage.md', 'docs/deploy.md', 'docs/design.md', 'templates/.merit_launch.md', 'cfg/par_pins.free.json', 'scripts/smoke-freemium.ps1', 'scripts/smoke-freemium.sh', 'merit.sh')) {
            if (-not (Test-Path (Join-Path $TargetRoot $rel))) { $fail += "missing $rel" }
        }
        if ($fail.Count) {
            Write-Host "verify FAILED:`n$($fail -join "`n")"
            exit 1
        }
        Write-Host "verify OK: merit-agent-skills repo"
        return
    }
    foreach ($rel in @('cfg/par_pins.json', 'cfg/branding.json')) {
        if (-not (Test-Path (Join-Path $TargetRoot $rel))) { $fail += "missing $rel" }
    }
    $gitignore = Join-Path $TargetRoot '.gitignore'
    if (Test-Path $gitignore) {
        $gi = Get-Content $gitignore -Raw
        foreach ($needle in @('.env.local', '.vercel')) {
            if ($gi -notmatch [regex]::Escape($needle)) { $fail += ".gitignore should list $needle" }
        }
    } else {
        $fail += 'missing .gitignore'
    }
    if ($fail.Count) {
        Write-Host "verify FAILED:`n$($fail -join "`n")"
        exit 1
    }
    Write-Host "verify OK: $TargetRoot"
}

function Invoke-ParScaffold {
    param([string]$TargetRoot, [string]$Variant)
    $pinsSrc = Join-Path $Root 'cfg/par_pins.free.json'
    $destCfg = Join-Path $TargetRoot 'cfg'
    New-Item -ItemType Directory -Force -Path $destCfg | Out-Null
    Copy-Item -LiteralPath $pinsSrc -Destination (Join-Path $destCfg 'par_pins.json') -Force
    $pins = Read-JsonFile (Join-Path $destCfg 'par_pins.json')
    $wb = $pins.packages.merit_workbench
    $playDir = Join-Path $TargetRoot 'play'
    New-Item -ItemType Directory -Force -Path $playDir | Out-Null
    $journalTags = ''
    if ($Variant -eq 'workbench-journal') {
        $jn = $pins.packages.journal
        $journalTags = @"
  <link rel="stylesheet" href="$($jn.artifacts.css.url)" integrity="$($jn.artifacts.css.sri)" crossorigin="anonymous">
  <script type="module" src="$($jn.artifacts.mjs.url)" integrity="$($jn.artifacts.mjs.sri)" crossorigin="anonymous"></script>
"@
    }
    $tplPath = Join-Path $Root 'templates/consumer-static/play/index.html.template'
    $html = (Get-Content -LiteralPath $tplPath -Raw -Encoding UTF8) `
        -replace '\{\{PRODUCT_NAME\}\}', 'MERIT Play' `
        -replace '\{\{WORKBENCH_CSS_URL\}\}', $wb.artifacts.css.url `
        -replace '\{\{WORKBENCH_CSS_SRI\}\}', $wb.artifacts.css.sri `
        -replace '\{\{WORKBENCH_JS_URL\}\}', $wb.artifacts.js.url `
        -replace '\{\{WORKBENCH_JS_SRI\}\}', $wb.artifacts.js.sri `
        -replace '\{\{JOURNAL_TAGS\}\}', $journalTags
    Set-Content -LiteralPath (Join-Path $playDir 'index.html') -Value $html -Encoding UTF8
    Write-Host "par scaffold OK ($Variant) -> $TargetRoot"
}

function Invoke-BrandingScaffold {
    param([string]$TargetRoot)
    $src = Join-Path $Root 'cfg/branding.json.template'
    $dest = Join-Path $TargetRoot 'cfg/branding.json'
    New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
    Copy-Item -LiteralPath $src -Destination $dest -Force
    Write-Host "branding scaffold OK -> $dest"
}

function Invoke-SubsScaffold {
    param([string]$TargetRoot)
    $cfg = Join-Path $TargetRoot 'cfg'
    New-Item -ItemType Directory -Force -Path $cfg | Out-Null
    Write-JsonFile -Path (Join-Path $cfg 'merit-sync.json') -Object ([ordered]@{
        schema = 'merit.merit_sync.v1'
        consumer_id = 'YOUR_CONSUMER_ID'
        metered_api_base = 'https://merit-prod.vercel.app'
        meritsubs_base = 'https://merit-prod.vercel.app/api/meritsubs'
        meritstore_register_url = 'https://merit-prod.vercel.app/store/YOUR_CONSUMER_ID/register'
        freemium_limits = 'cfg/freemium_limits.json'
        plus_sku = 'cfg/plus_sku.json'
    })
    foreach ($name in @('freemium_limits.json', 'plus_sku.json')) {
        Copy-Item -LiteralPath (Join-Path $Root "cfg/$name") -Destination (Join-Path $cfg $name) -Force
    }
    $portalsTpl = Join-Path $Root 'cfg/portals.json.template'
    if (Test-Path $portalsTpl) { Copy-Item -LiteralPath $portalsTpl -Destination (Join-Path $cfg 'portals.json') -Force }
    Write-Host "subs scaffold OK -> $cfg (edit consumer_id and register URL)"
}

function Get-ConsumerIdFromRepo {
    param([string]$TargetRoot)
    $syncPath = Join-Path $TargetRoot 'cfg/merit-sync.json'
    if (Test-Path $syncPath) {
        $sync = Read-JsonFile $syncPath
        if ($sync.consumer_id) { return [string]$sync.consumer_id }
    }
    return $null
}

function ConvertTo-ConsumerTitle {
    param([string]$ConsumerId)
    $parts = $ConsumerId -split '[-_]' | Where-Object { $_ }
    return (($parts | ForEach-Object { $_.Substring(0,1).ToUpperInvariant() + $_.Substring(1) }) -join ' ')
}

function Copy-LiveAlphaTemplateIfMissing {
    param([string]$Source, [string]$Dest, [hashtable]$Replacements, [switch]$Force)
    if ((Test-Path $Dest) -and -not $Force) {
        Write-Host "  keep $Dest"
        return $false
    }
    $dir = Split-Path -Parent $Dest
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $text = Get-Content -LiteralPath $Source -Raw -Encoding UTF8
    foreach ($key in $Replacements.Keys) {
        $text = $text.Replace("{{$key}}", [string]$Replacements[$key])
    }
    [System.IO.File]::WriteAllText($Dest, $text, [System.Text.UTF8Encoding]::new($false))
    Write-Host "  write $Dest"
    return $true
}

function Invoke-LiveAlpha {
    param([string]$TargetRoot, [string[]]$ArgList)
    $mode = 'scaffold'
    if ($ArgList.Count -gt 0 -and $ArgList[0] -notlike '--*') {
        $mode = "$($ArgList[0])".ToLowerInvariant()
    }
    $force = Test-ArgFlag -ArgList $ArgList -Name '--force'
    $consumerId = Get-ConsumerIdFromRepo -TargetRoot $TargetRoot
    if (-not $consumerId) {
        throw "livealpha needs cfg/merit-sync.json with consumer_id. Run merit init/apply or set consumer_id first. Path: $TargetRoot"
    }
    $title = ConvertTo-ConsumerTitle -ConsumerId $consumerId
    $date = (Get-Date).ToString('yyyy-MM-dd')
    $repl = @{
        CONSUMER_ID = $consumerId
        CONSUMER_TITLE = $title
        DATE = $date
    }
    $tplRoot = Join-Path $Root 'templates/livealpha'
    $cfg = Join-Path $TargetRoot 'cfg'
    $iar = Join-Path $TargetRoot 'docs/IAR'
    New-Item -ItemType Directory -Force -Path $cfg | Out-Null
    New-Item -ItemType Directory -Force -Path $iar | Out-Null

    if ($mode -eq 'status') {
        Write-Host "livealpha status -> $TargetRoot ($consumerId)"
        $cross = Join-Path $cfg 'research_crossrefs.json'
        $research = Join-Path $iar (($consumerId -replace '-', '_') + '_BASELINE_RESEARCH.md')
        $edgeCount = 0
        $catCount = 0
        if (Test-Path $cross) {
            $cx = Read-JsonFile $cross
            if ($cx.categories) { $catCount = @($cx.categories).Count }
            if ($cx.edges) { $edgeCount = @($cx.edges).Count }
        }
        Write-Host "  research_iar: $(Test-Path $research)"
        Write-Host "  categories: $catCount (floor 10)"
        Write-Host "  crossref_edges: $edgeCount (floor 50)"
        Write-Host "  freemium_limits: $(Test-Path (Join-Path $cfg 'freemium_limits.json'))"
        Write-Host "  plus_sku: $(Test-Path (Join-Path $cfg 'plus_sku.json'))"
        Write-Host "  meritsubs_consumer: $(Test-Path (Join-Path $cfg 'meritsubs_consumer.json'))"
        if ($catCount -ge 10 -and $edgeCount -ge 50) {
            Write-Host '  floors: PASS (structure)'
        } else {
            Write-Host '  floors: FAIL or incomplete — fill APA refs + ≥50 edges; see skill merit-livealpha'
        }
        Write-Host "Next: /merit-livealpha in Cursor on this repo"
        return
    }

    Write-Host "livealpha $mode -> $TargetRoot ($consumerId)"
    $researchName = ($consumerId -replace '-', '_') + '_BASELINE_RESEARCH.md'
    $forceSwitch = $force
    Copy-LiveAlphaTemplateIfMissing -Source (Join-Path $tplRoot 'research_crossrefs.json.template') `
        -Dest (Join-Path $cfg 'research_crossrefs.json') -Replacements $repl -Force:$forceSwitch | Out-Null
    Copy-LiveAlphaTemplateIfMissing -Source (Join-Path $tplRoot 'BASELINE_RESEARCH.md.template') `
        -Dest (Join-Path $iar $researchName) -Replacements $repl -Force:$forceSwitch | Out-Null
    Copy-LiveAlphaTemplateIfMissing -Source (Join-Path $tplRoot 'meritsubs_consumer.json.template') `
        -Dest (Join-Path $cfg 'meritsubs_consumer.json') -Replacements $repl -Force:$forceSwitch | Out-Null
    foreach ($name in @('freemium_limits.json', 'plus_sku.json')) {
        $dest = Join-Path $cfg $name
        if ((Test-Path $dest) -and -not $force) {
            Write-Host "  keep $dest"
        } else {
            Copy-Item -LiteralPath (Join-Path $Root "cfg/$name") -Destination $dest -Force
            Write-Host "  write $dest"
        }
    }
    if ($mode -eq 'research') {
        Write-Host 'livealpha research pack OK'
    } else {
        Write-Host 'livealpha scaffold OK'
    }
    Write-Host 'Next: open Cursor on this consumer and run /merit-livealpha …'
    Write-Host '  Or: .\merit.ps1 livealpha status --path <repo>'
}

function Invoke-AdminGateDemoInit {
    param([string]$TargetRoot)
    $envPath = Join-Path $TargetRoot '.env.local'
    if (-not (Test-Path $envPath)) {
        Set-Content -LiteralPath $envPath -Value @(
            '# MERIT demo — local MeritAdminGate placeholders only. Never commit real phrases.',
            'MERIT_ADMIN_GATE_DEMO=1',
            'OPERATOR_GATE_HASH_SLOT_1=replace-with-bcrypt-hash'
        ) -Encoding UTF8
        Write-Host "admin gate demo-init created $envPath"
    } else {
        Write-Host "admin gate demo-init skipped (exists): $envPath"
    }
    Copy-Item -LiteralPath (Join-Path $Root 'cfg/operator_gate_wordlists.excerpt.json') -Destination (Join-Path $TargetRoot 'cfg/operator_gate_wordlists.json') -Force
}

function Get-VercelScope {
    param([string]$TargetRoot)
    $deployCfg = Join-Path $TargetRoot 'cfg/flask_deploy.json'
    if (-not (Test-Path $deployCfg)) { throw "deploy needs cfg/flask_deploy.json. Run merit apply first." }
    $cfg = Read-JsonFile $deployCfg
    if (-not $cfg.vercel_scope) { throw "cfg/flask_deploy.json missing vercel_scope." }
    return $cfg.vercel_scope
}

function Ensure-VercelLinked {
    param([string]$TargetRoot, [string]$Scope)
    $project = Join-Path $TargetRoot '.vercel/project.json'
    if (Test-Path $project) {
        Set-EnvLocalValue -Path (Join-Path $TargetRoot '.env.local') -Name 'MERIT_VERCEL_LINKED' -Value '1'
        Write-Host 'vercel link OK: existing .vercel/project.json'
        return
    }
    Push-Location $TargetRoot
    try {
        Write-Host "vercel link: npx vercel link --yes --scope $Scope"
        & npx vercel link --yes --scope $Scope
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } finally {
        Pop-Location
    }
    Set-EnvLocalValue -Path (Join-Path $TargetRoot '.env.local') -Name 'MERIT_VERCEL_LINKED' -Value '1'
}

function Invoke-Deploy {
    param([string]$TargetRoot, [string[]]$ArgList)
    Invoke-Apply -TargetRoot $TargetRoot -ArgList $ArgList
    $scope = Get-VercelScope -TargetRoot $TargetRoot
    Ensure-VercelLinked -TargetRoot $TargetRoot -Scope $scope
    Push-Location $TargetRoot
    try {
        if (Test-Path 'package.json') { npm run build }
        Write-Host "npx vercel --prod --scope $scope"
        & npx vercel --prod --scope $scope
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    } finally {
        Pop-Location
    }
    Set-EnvLocalValue -Path (Join-Path $TargetRoot '.env.local') -Name 'MERIT_VERCEL_DEPLOYED' -Value '1'
    Set-EnvLocalValue -Path (Join-Path $TargetRoot '.env.local') -Name 'MERIT_VERCEL_DEPLOYED_AT' -Value ([DateTimeOffset]::UtcNow.ToString('o'))
}

function Invoke-PortalPublish {
    param([string]$TargetRoot, [string[]]$ArgList)
    Invoke-Apply -TargetRoot $TargetRoot -ArgList $ArgList
    if (-not $env:HERENOW_API_KEY -and -not (Test-Path "$env:USERPROFILE\.herenow\credentials")) {
        Write-Host 'portal publish: set HERENOW_API_KEY or ~/.herenow/credentials (BYOK).'
        exit 1
    }
    $portalsPath = Join-Path $TargetRoot 'cfg/portals.json'
    if (Test-Path $portalsPath) {
        $portals = Read-JsonFile $portalsPath
        foreach ($s in $portals.surfaces) {
            $sub = Join-Path $TargetRoot $s.path
            if (Test-Path $sub) { Write-Host "publish surface $($s.id): $($s.path) -> $($s.slug).here.now (here.now CLI/tool required)" }
        }
    } else {
        Write-Host "publish portal/ from $TargetRoot (here.now CLI/tool required)"
    }
}

function Invoke-Closeout {
    param([string]$TargetRoot)
    Invoke-Verify -TargetRoot $TargetRoot
    Push-Location $TargetRoot
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git diff --check
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            git status --short
            git rev-parse --short HEAD
        } else {
            Write-Host 'closeout WARN: git not available on PATH'
        }
    } finally {
        Pop-Location
    }
}

$target = Resolve-TargetRoot -ArgList $Rest

switch -Regex ($Command) {
    '^(help|\?)$' { Write-MeritHelp; exit 0 }
    '^version$' { Write-Host "merit $MERIT_VERSION"; exit 0 }
    '^init$' { Invoke-Init -TargetRoot $target -ArgList $Rest; exit 0 }
    '^apply$' { Invoke-Apply -TargetRoot $target -ArgList $Rest; exit 0 }
    '^verify$' { Invoke-Verify -TargetRoot $target; exit 0 }
    '^deploy$' { Invoke-Deploy -TargetRoot $target -ArgList $Rest; exit 0 }
    '^vercel$' { Invoke-Deploy -TargetRoot $target -ArgList $Rest; exit 0 }
    '^portal$' { Invoke-PortalPublish -TargetRoot $target -ArgList $Rest; exit 0 }
    '^all$' { Invoke-Deploy -TargetRoot $target -ArgList $Rest; Invoke-PortalPublish -TargetRoot $target -ArgList $Rest; exit 0 }
    '^closeout$' { Invoke-Closeout -TargetRoot $target; exit 0 }
    '^par$' {
        if (-not $Rest -or $Rest[0] -ne 'scaffold') { Write-MeritHelp; exit 1 }
        $variant = Get-ArgValue -ArgList $Rest -Name '--variant'
        if (-not $variant) { $variant = 'workbench' }
        Invoke-ParScaffold -TargetRoot $target -Variant $variant
        exit 0
    }
    '^branding$' {
        if (-not $Rest -or $Rest[0] -ne 'scaffold') { Write-MeritHelp; exit 1 }
        Invoke-BrandingScaffold -TargetRoot $target
        exit 0
    }
    '^subs$' {
        if (-not $Rest -or $Rest[0] -ne 'scaffold') { Write-MeritHelp; exit 1 }
        Invoke-SubsScaffold -TargetRoot $target
        exit 0
    }
    '^(livealpha|baseline)$' {
        Invoke-LiveAlpha -TargetRoot $target -ArgList $Rest
        exit 0
    }
    '^admin$' {
        if ($Rest.Count -lt 2 -or $Rest[0] -ne 'gate' -or $Rest[1] -ne 'demo-init') { Write-MeritHelp; exit 1 }
        Invoke-AdminGateDemoInit -TargetRoot $target
        exit 0
    }
    '^app$' {
        Write-Host "app scaffold: clone the reference consumer:"
        Write-Host "  git clone https://github.com/Mr-PI-Bala/merit-demo.git <target>"
        exit 0
    }
    default { Write-MeritHelp; exit 1 }
}
