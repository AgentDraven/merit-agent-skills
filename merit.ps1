# MERIT public CLI — one entrypoint for free users.

param()

$ErrorActionPreference = 'Stop'
$MERIT_VERSION = '0.3.24'
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
  create --path <repo>     AutoMagic fullstack-consumer (default = local taste, no Vercel)
                           [--profile fullstack-consumer] [--deploy]
                           [--vercel-scope <slug>] [--product-name <name>]
                           [--scaffold-only]  (alias of default local mode)
  version                  Print version
  help                     Print help

Typical flow (AutoMagic — local taste, no Vercel account):
  .\merit.ps1 create --path ..\my-app --profile fullstack-consumer

Optional later (your own host):
  .\merit.ps1 create --path ..\my-app --profile fullstack-consumer --deploy --vercel-scope <your-team>
  # or: .\merit.ps1 deploy --path ..\my-app

Redo a single phase anytime with init / apply / par scaffold / verify / deploy.
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

function Set-LaunchIniValue {
    param([string]$Path, [string]$Name, [string]$Value)
    if (-not (Test-Path $Path)) { throw "Launch file not found: $Path" }
    $key = $Name.Trim()
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $found = $false
    $out = foreach ($line in $lines) {
        if ($line -match("^\s*$([regex]::Escape($key))\s*=")) {
            $found = $true
            "$key = $Value"
        } else {
            $line
        }
    }
    if (-not $found) { $out += "$key = $Value" }
    Set-Content -LiteralPath $Path -Value $out -Encoding UTF8
}

function ConvertTo-ConsumerSlug {
    param([string]$Name)
    $s = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-' -replace '^-+|-+$', ''
    if (-not $s) { $s = 'my-app' }
    return $s
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
            return $false
        }
        Write-Host "verify OK: merit-agent-skills repo"
        return $true
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
        return $false
    }
    Write-Host "verify OK: $TargetRoot"
    return $true
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
    $scope = [string]$cfg.vercel_scope
    if ($scope -eq '' -or $scope -eq 'local' -or $scope -eq 'pending') {
        throw @"
deploy needs your Vercel team slug (own-host step — not required for local dinner taste).
Pass:  --vercel-scope <your-team>
Or set: vercel_scope= in .merit_launch.md, then: .\merit.ps1 deploy --path <repo>
"@
    }
    return $scope
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
        if ($LASTEXITCODE -ne 0) { throw "vercel link failed (exit $LASTEXITCODE). Log in with vercel login, check --vercel-scope / vercel_scope, then retry." }
    } finally {
        Pop-Location
    }
    Set-EnvLocalValue -Path (Join-Path $TargetRoot '.env.local') -Name 'MERIT_VERCEL_LINKED' -Value '1'
}

function Invoke-Deploy {
    param([string]$TargetRoot, [string[]]$ArgList)
    $scopeArg = Get-ArgValue -ArgList $ArgList -Name '--vercel-scope'
    if ($scopeArg) {
        $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
        if (-not (Test-Path $launch)) { Invoke-Init -TargetRoot $TargetRoot -ArgList $ArgList }
        Set-LaunchIniValue -Path $launch -Name 'vercel_scope' -Value $scopeArg
    }
    Invoke-Apply -TargetRoot $TargetRoot -ArgList $ArgList
    $scope = Get-VercelScope -TargetRoot $TargetRoot
    Ensure-VercelLinked -TargetRoot $TargetRoot -Scope $scope
    Push-Location $TargetRoot
    try {
        if (Test-Path 'package.json') {
            npm run build
            if ($LASTEXITCODE -ne 0) { throw "npm run build failed (exit $LASTEXITCODE). Fix build errors, then retry deploy or create." }
        }
        Write-Host "npx vercel --prod --scope $scope"
        & npx vercel --prod --scope $scope
        if ($LASTEXITCODE -ne 0) { throw "vercel --prod failed (exit $LASTEXITCODE). Fix the Vercel error above, then: .\merit.ps1 deploy --path <repo>" }
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
        throw 'portal publish: set HERENOW_API_KEY or ~/.herenow/credentials (BYOK).'
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
    if (-not (Invoke-Verify -TargetRoot $TargetRoot)) { throw 'closeout blocked: verify FAILED' }
    Push-Location $TargetRoot
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git diff --check
            if ($LASTEXITCODE -ne 0) { throw "git diff --check failed (exit $LASTEXITCODE)" }
            git status --short
            git rev-parse --short HEAD
        } else {
            Write-Host 'closeout WARN: git not available on PATH'
        }
    } finally {
        Pop-Location
    }
}

function Ensure-CreateLaunchDefaults {
    param([string]$TargetRoot, [string[]]$ArgList)
    $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
    $settings = Get-LaunchSettings -Path $launch
    $folderLeaf = Split-Path -Leaf $TargetRoot
    $slug = ConvertTo-ConsumerSlug $folderLeaf

    $consumerId = Get-ArgValue -ArgList $ArgList -Name '--consumer-id'
    if (-not $consumerId) { $consumerId = Get-Setting -Settings $settings -Name 'consumer_id' }
    if (-not $consumerId) { $consumerId = $slug }

    $productName = Get-ArgValue -ArgList $ArgList -Name '--product-name'
    if (-not $productName) { $productName = Get-Setting -Settings $settings -Name 'product_name' }
    if (-not $productName) { $productName = ConvertTo-ConsumerTitle $consumerId }

    $scope = Get-ArgValue -ArgList $ArgList -Name '--vercel-scope'
    if (-not $scope) { $scope = Get-Setting -Settings $settings -Name 'vercel_scope' }
    if (-not $scope) { $scope = $env:VERCEL_SCOPE }
    if (-not $scope) { $scope = $env:VERCEL_ORG_ID }
    if (-not $scope) { $scope = 'local' }

    $sbUrl = Get-Setting -Settings $settings -Name 'supabase_url'
    $sbAnon = Get-Setting -Settings $settings -Name 'supabase_anon_key'
    $sbSvc = Get-Setting -Settings $settings -Name 'supabase_service_role_key'
    if (-not $sbUrl) { $sbUrl = if ($env:SUPABASE_URL) { $env:SUPABASE_URL } else { 'https://platform-defaults.merit.local' } }
    if (-not $sbAnon) { $sbAnon = if ($env:SUPABASE_ANON_KEY) { $env:SUPABASE_ANON_KEY } else { 'create-pending-replace-with-supabase-anon-key' } }
    if (-not $sbSvc) { $sbSvc = if ($env:SUPABASE_SERVICE_ROLE_KEY) { $env:SUPABASE_SERVICE_ROLE_KEY } else { 'create-pending-replace-with-supabase-service-role-key' } }

    Set-LaunchIniValue -Path $launch -Name 'product_name' -Value $productName
    Set-LaunchIniValue -Path $launch -Name 'consumer_id' -Value $consumerId
    Set-LaunchIniValue -Path $launch -Name 'vercel_scope' -Value $scope
    Set-LaunchIniValue -Path $launch -Name 'supabase_url' -Value $sbUrl
    Set-LaunchIniValue -Path $launch -Name 'supabase_anon_key' -Value $sbAnon
    Set-LaunchIniValue -Path $launch -Name 'supabase_service_role_key' -Value $sbSvc
    if (-not (Get-Setting -Settings $settings -Name 'here_now_slug')) {
        Set-LaunchIniValue -Path $launch -Name 'here_now_slug' -Value $consumerId
    }
    Write-Host "create launch defaults: consumer_id=$consumerId product_name=$productName vercel_scope=$scope"
    if ($scope -eq 'local') {
        Write-Host 'create NOTE: vercel_scope=local (dinner default). Own-host deploy later with --deploy --vercel-scope <your-team>.'
    }
    if ($sbUrl -eq 'https://platform-defaults.merit.local') {
        Write-Host 'create NOTE: supabase_* are scaffold placeholders — platform rails via merit-prod; BYOK optional later.'
    }
}

function Invoke-PortalScaffold {
    param([string]$TargetRoot, [string]$ProductName, [string]$ConsumerId)
    $portalDir = Join-Path $TargetRoot 'portal'
    New-Item -ItemType Directory -Force -Path $portalDir | Out-Null
    $indexPath = Join-Path $portalDir 'index.html'
    if (-not (Test-Path $indexPath)) {
        $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$ProductName</title>
  <meta name="description" content="$ProductName — MERIT-powered marketing portal stub.">
  <style>
    body { margin: 0; font-family: Georgia, 'Times New Roman', serif; background: #0c1220; color: #f4f1ea; }
    main { max-width: 40rem; margin: 0 auto; padding: 4rem 1.5rem 6rem; }
    h1 { font-size: clamp(2.4rem, 6vw, 3.6rem); line-height: 1.05; margin: 0 0 1rem; }
    p { color: #c9d0dc; line-height: 1.5; }
    .cta { display: inline-block; margin-top: 1.5rem; color: #0c1220; background: #e8dcc8; padding: 0.7rem 1.1rem; text-decoration: none; font-weight: 700; }
    footer { margin-top: 3rem; color: #8b93a3; font-size: 0.85rem; }
  </style>
</head>
<body>
  <main>
    <h1>$ProductName</h1>
    <p>Marketing portal stub from <code>merit.ps1 create</code>. Edit brand and CTAs, then publish with <code>merit.ps1 portal</code> (portal/ only).</p>
    <a class="cta" href="/play/">Open the app</a>
    <footer>MERIT Powered · consumer_id=$ConsumerId · checkout later at /store/$ConsumerId/register</footer>
  </main>
</body>
</html>
"@
        Set-Content -LiteralPath $indexPath -Value $html -Encoding UTF8
        Write-Host "portal scaffold OK -> $indexPath"
    } else {
        Write-Host "portal scaffold skipped (exists): $indexPath"
    }

    $docsDir = Join-Path $TargetRoot 'docs'
    New-Item -ItemType Directory -Force -Path $docsDir | Out-Null
    $prdPath = Join-Path $docsDir 'PRODUCT.prd.md'
    if (-not (Test-Path $prdPath)) {
        $prdTemplate = Join-Path $Root 'skills/merit-prd/examples/PRODUCT.prd.md'
        if (Test-Path $prdTemplate) {
            Copy-Item -LiteralPath $prdTemplate -Destination $prdPath -Force
            Write-Host "prd template OK -> $prdPath (fill with /merit-prd, then /merit-portal)"
        } else {
            Set-Content -LiteralPath $prdPath -Value @"
# $ProductName PRD

Fill this brief, then use ``/merit-prd`` in your AI IDE and ``/merit-portal`` for marketing.
See merit-agent-skills ``skills/merit-prd/examples/PRODUCT.prd.md``.

consumer_id=$ConsumerId
"@ -Encoding UTF8
            Write-Host "prd stub OK -> $prdPath"
        }
    } else {
        Write-Host "prd template skipped (exists): $prdPath"
    }

    $logicDir = Join-Path $TargetRoot 'app_logic'
    New-Item -ItemType Directory -Force -Path $logicDir | Out-Null
    $readme = Join-Path $logicDir 'README.md'
    if (-not (Test-Path $readme)) {
        Set-Content -LiteralPath $readme -Value @"
# app_logic/

Put **your** product features here only.

- Do not fork MERIT provider code into this folder.
- Login, store, and payments stay on `merit-prod.vercel.app` rails (isolated by ``consumer_id`` = ``$ConsumerId``).
- After dinner Step 2 create/deploy: fill ``docs/PRODUCT.prd.md`` (``/merit-prd``), shape ``portal/`` (``/merit-portal``), then implement Must FRs here.

Generated by ``merit.ps1 create``.
"@ -Encoding UTF8
        Write-Host "app_logic guidance OK -> $readme"
    } else {
        Write-Host "app_logic guidance skipped (exists): $readme"
    }
}

function Invoke-Create {
    param([string]$TargetRoot, [string[]]$ArgList)

    $profile = Get-ArgValue -ArgList $ArgList -Name '--profile'
    if (-not $profile) { $profile = 'fullstack-consumer' }
    if ($profile -ne 'fullstack-consumer') {
        throw "create: unknown --profile '$profile'. Supported: fullstack-consumer"
    }
    # Dinner default = local taste (no Vercel). --deploy opts into own-host publish.
    # --scaffold-only kept as alias of local mode for older docs/CI.
    $wantDeploy = Test-ArgFlag -ArgList $ArgList -Name '--deploy'
    $scaffoldOnly = -not $wantDeploy
    if (Test-ArgFlag -ArgList $ArgList -Name '--scaffold-only') { $scaffoldOnly = $true; $wantDeploy = $false }
    $theme = Get-ArgValue -ArgList $ArgList -Name '--theme'
    if ($theme) { Write-Host "create NOTE: --theme $theme recorded for GlossPack when available; branding scaffold uses defaults today." }
    if ($wantDeploy) {
        $scopeCheck = Get-ArgValue -ArgList $ArgList -Name '--vercel-scope'
        if (-not $scopeCheck -and -not $env:VERCEL_SCOPE) {
            throw "create --deploy needs --vercel-scope <your-team> (own Vercel host). For dinner taste without Vercel, omit --deploy."
        }
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " MERIT AutoMagic create  v$MERIT_VERSION"
    Write-Host " profile=$profile"
    Write-Host " path=$TargetRoot"
    if ($wantDeploy) { Write-Host ' mode=deploy (includes your Vercel host)' } else { Write-Host ' mode=local (default — no Vercel account; taste on your machine)' }
    Write-Host "============================================================"

    $phases = @(
        @{ n = 1; title = 'Repo skeleton and MERIT wiring (init + apply)'; script = {
            Invoke-Init -TargetRoot $TargetRoot -ArgList $ArgList
            Ensure-CreateLaunchDefaults -TargetRoot $TargetRoot -ArgList $ArgList
            Invoke-Apply -TargetRoot $TargetRoot -ArgList $ArgList
        }},
        @{ n = 2; title = 'Shared UI chrome — workbench / journal (par scaffold)'; script = {
            Invoke-ParScaffold -TargetRoot $TargetRoot -Variant 'workbench-journal'
        }},
        @{ n = 3; title = 'Starter look (branding scaffold)'; script = {
            Invoke-BrandingScaffold -TargetRoot $TargetRoot
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            Update-Branding -TargetRoot $TargetRoot -Settings (Get-LaunchSettings -Path $launch)
        }},
        @{ n = 4; title = 'Free / Plus subscriber embed (subs scaffold)'; script = {
            Invoke-SubsScaffold -TargetRoot $TargetRoot
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            $settings = Get-LaunchSettings -Path $launch
            $cid = Require-Setting -Settings $settings -Name 'consumer_id'
            $syncPath = Join-Path $TargetRoot 'cfg/merit-sync.json'
            if (Test-Path $syncPath) {
                $sync = Read-JsonFile $syncPath
                $sync.consumer_id = $cid
                $sync.meritstore_register_url = "https://merit-prod.vercel.app/store/$cid/register"
                Write-JsonFile -Path $syncPath -Object $sync
            }
        }},
        @{ n = 5; title = 'Local demo admin gate (admin gate demo-init)'; script = {
            Invoke-AdminGateDemoInit -TargetRoot $TargetRoot
        }},
        @{ n = 6; title = 'Local health check (verify)'; script = {
            if (-not (Invoke-Verify -TargetRoot $TargetRoot)) {
                throw 'verify FAILED. Fix the missing files listed above, then re-run create or: .\merit.ps1 verify --path <repo>'
            }
        }},
        @{ n = 7; title = 'Marketing portal stub + app_logic guidance'; script = {
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            $settings = Get-LaunchSettings -Path $launch
            $cid = Require-Setting -Settings $settings -Name 'consumer_id'
            $pname = Get-Setting -Settings $settings -Name 'product_name' -Default $cid
            Invoke-PortalScaffold -TargetRoot $TargetRoot -ProductName $pname -ConsumerId $cid
        }},
        @{ n = 8; title = 'Platform rails (merit-prod) + optional here.now portal'; script = {
            if (-not $scaffoldOnly) {
                # Advanced: builder's own Vercel host
                Invoke-Deploy -TargetRoot $TargetRoot -ArgList $ArgList
                return
            }
            # Dinner default: no builder Vercel. Attach to platform gateway rails.
            $gateway = 'https://merit-prod.vercel.app'
            Write-Host "Platform host for dinner: $gateway (no --vercel-scope / no your-team)"
            try {
                $health = Invoke-RestMethod -Uri "$gateway/api/health" -Method Get -TimeoutSec 20
                Write-Host "merit-prod health OK (status/ok probe)"
                if ($health.ok -eq $false) { Write-Host 'create NOTE: health payload ok=false — continue; re-check later if APIs fail.' }
            } catch {
                throw "merit-prod unreachable at $gateway/api/health. Check network, then re-run create. $_"
            }
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            $settings = Get-LaunchSettings -Path $launch
            $cid = Require-Setting -Settings $settings -Name 'consumer_id'
            Write-Host "Rails wired for consumer_id=$cid (store/auth via $gateway)"
            Write-Host "Register path (after tenant): $gateway/store/$cid/register"
            # Optional marketing publish — only if BYOK already present (never required for dinner).
            $hasHere = $env:HERENOW_API_KEY -or (Test-Path "$env:USERPROFILE\.herenow\credentials")
            if ($hasHere) {
                Write-Host 'here.now credentials found — publishing portal/ (optional)'
                try {
                    Invoke-PortalPublish -TargetRoot $TargetRoot -ArgList $ArgList
                } catch {
                    Write-Host "create NOTE: portal publish skipped — $($_.Exception.Message)"
                }
            } else {
                Write-Host 'here.now: skipped (no HERENOW_API_KEY / ~/.herenow/credentials). Local portal/ stub is enough for dinner; publish later with merit.ps1 portal.'
            }
        }},
        @{ n = 9; title = 'Success banner'; script = {
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            $settings = Get-LaunchSettings -Path $launch
            $cid = Get-Setting -Settings $settings -Name 'consumer_id' -Default (Split-Path -Leaf $TargetRoot)
            Write-Host ''
            Write-Host '------------------------------------------------------------'
            if ($scaffoldOnly) {
                Write-Host " Your MERIT shell is ready — consumer_id=$cid"
                Write-Host ' UI: open play/ on your machine (IDE preview or npx serve).'
                Write-Host ' Rails: merit-prod.vercel.app (platform Supabase/Square/store — no your Vercel).'
                Write-Host "   cd `"$TargetRoot`""
                Write-Host '   npx --yes serve . -p 5173'
                Write-Host ' Recommended: push this folder to GitHub to archive the repo.'
                Write-Host ' Advanced later: own Vercel host via --deploy --vercel-scope <your-team>'
                Write-Host " Checkout later: https://merit-prod.vercel.app/store/$cid/register"
            } else {
                Write-Host ' Your app is live on your Vercel — shell ready for'
                Write-Host ' app_logic/ and your portal. Enjoy dinner.'
                Write-Host " consumer_id=$cid"
                Write-Host ' Next: shape portal/ then .\merit.ps1 portal --path <repo>'
                Write-Host " Checkout later: https://merit-prod.vercel.app/store/$cid/register"
            }
            Write-Host '------------------------------------------------------------'
        }}
    )

    foreach ($phase in $phases) {
        Write-Host ""
        Write-Host "======== CREATE phase $($phase.n)/9: $($phase.title) ========"
        try {
            & $phase.script
            Write-Host "OK phase $($phase.n)/9"
        } catch {
            Write-Host ""
            Write-Host "FAILED phase $($phase.n)/9 — $($phase.title)" -ForegroundColor Red
            Write-Host $_.Exception.Message
            Write-Host ""
            Write-Host 'Recovery tips:'
            Write-Host "  • Re-run create (idempotent where safe): .\merit.ps1 create --path `"$TargetRoot`" --profile fullstack-consumer"
            Write-Host "  • Or redo this phase alone, then continue from the next verb"
            Write-Host "  • Dinner guide: https://merit-prod.vercel.app/portal/developers/full-app/"
            throw "create stopped at phase $($phase.n)/9"
        }
    }
    Write-Host ""
    Write-Host "create OK: AutoMagic fullstack-consumer finished for $TargetRoot"
}

$target = Resolve-TargetRoot -ArgList $Rest

switch -Regex ($Command) {
    '^(help|\?)$' { Write-MeritHelp; exit 0 }
    '^version$' { Write-Host "merit $MERIT_VERSION"; exit 0 }
    '^init$' { Invoke-Init -TargetRoot $target -ArgList $Rest; exit 0 }
    '^apply$' { Invoke-Apply -TargetRoot $target -ArgList $Rest; exit 0 }
    '^verify$' { if (-not (Invoke-Verify -TargetRoot $target)) { exit 1 }; exit 0 }
    '^deploy$' { try { Invoke-Deploy -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^vercel$' { try { Invoke-Deploy -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^portal$' { try { Invoke-PortalPublish -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^all$' { try { Invoke-Deploy -TargetRoot $target -ArgList $Rest; Invoke-PortalPublish -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^closeout$' { try { Invoke-Closeout -TargetRoot $target; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^create$' {
        try {
            Invoke-Create -TargetRoot $target -ArgList $Rest
            exit 0
        } catch {
            Write-Host $_.Exception.Message
            exit 1
        }
    }
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
