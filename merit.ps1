# MERIT public CLI - one entrypoint for free users.

param()

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$MERIT_VERSION = if (Test-Path (Join-Path $Root 'VERSION')) {
    ((Get-Content (Join-Path $Root 'VERSION') -Raw) -split '\r?\n')[0].Trim()
} else { '0.0.0-dev' }

$Script:MeritResolveRepoRoot = $Root
try { . (Join-Path $Root 'merit\modules\Merit.Core.ps1') } catch { throw "MERIT core module failed to load: $($_.Exception.Message)" }
try { . (Join-Path $Root 'merit\modules\Merit.Skills.ps1') } catch { throw "MERIT skills module failed to load: $($_.Exception.Message)" }
try { . (Join-Path $Root 'merit\modules\Merit.Surface.ps1') } catch { throw "MERIT surface module failed to load: $($_.Exception.Message)" }
try { . (Join-Path $Root 'merit\modules\Merit.Law.ps1') } catch { throw "MERIT law module failed to load: $($_.Exception.Message)" }
try { . (Join-Path $Root 'merit\modules\Merit.Vault.ps1') } catch { throw "MERIT vault module failed to load: $($_.Exception.Message)" }

$Command = if ($args.Count -gt 0) { "$($args[0])".ToLowerInvariant() } else { 'help' }
$Rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

function Write-MeritHelp {
    Write-Host @"
merit.ps1 v$MERIT_VERSION - public MERIT CLI

Use this one script for the free-user path.

Commands:
  init --path <repo>       Create .merit_launch.md and gitignore it
  apply --path <repo>      Read .merit_launch.md and generate config + .env.local
  verify --path <repo>     Verify local MERIT scaffold
  e2e --path <repo>        Run consumer static smoke E2E (npm run e2e)
  e2e:playwright --path <repo>  Run consumer browser E2E (npm run e2e:playwright)
  deploy --path <repo>     Apply launch file, link Vercel if needed, deploy production
  portal --path <repo>     Apply launch file, then publish here.now portal targets
  all --path <repo>        Apply, deploy Vercel, then publish portal targets
  closeout [--path <repo>] Full release closeout: validate, CHANGELOG, commit, push
                           Use --validate-only to skip commit/push
  release [--path <repo>]  Alias for default release closeout
  law [list|closeout|edition|<section>]  OSS L1 excerpt from merit/merit.blob (in-memory unpack)
                           law --section VIII.F | law --for-skill merit-portal
  where                    Print Merit Surface map (OSS bench / IDE / vault discovery)
  surface                  Alias for where
  vault <mXin|mXout|runtime|env|cert|git>  Delegate explicit operator commands when a vault is present
  skills list|status|install|remove      Install and inspect IDE skills
  par scaffold             Advanced: create play shell + cfg/par_pins.json
  branding scaffold        Advanced: create cfg/branding.json
  subs scaffold            Advanced: create meritsubs/meritstore cfg
  community scaffold       Baseline community cfg (community / collab_schedule / alerts)
  livealpha --path <repo>  Elevate consumer toward live alpha (Research + Baseline scaffold)
  baseline --path <repo>   Alias for livealpha
  admin gate demo-init     Advanced: create local demo operator-gate placeholders
  admin ownership repair --path <repo>  Repair Windows repo owner/Modify ACL (confirmation required)
  admin ownership status --path <repo>  Inspect owner, ACL, and write access
                           (legacy alias: admin repair-ownership)
  admin github access status [--repo <owner/name>] [--user <login>]
  admin github access add [--repo <owner/name>] [--user <login>] [--permission <pull|triage|push|maintain|admin>] [--yes]
  admin github access remove [--repo <owner/name>] [--user <login>] [--yes]
  admin github auth status                     Show the active GitHub account
  admin github auth login                      Authenticate another GitHub account
  admin github auth switch [--user <login>]   Switch the active GitHub account
  app scaffold             Print merit-demo clone guidance
  create --path <repo>     AutoMagic fullstack-consumer (default = platform URL on merit-prod)
                           [--profile fullstack-consumer] [--deploy]
                           [--vercel-scope <slug>] [--product-name <name>]
                           [--scaffold-only]  (alias of default platform mode)
  oc --path <repo> [--consumer-id oc-...] [--product-name <name>]
                          OSS in the Cloud: DualRail play + required store activate
                          + demo portal/ as a MERIT-hosted marketing site
                          (here.now is a platform-key upgrade; laptop never needs one)
  apps publish --path <repo>  Upload play/+cfg/ to merit-prod /apps/<app>/play (create phase 8)
                          [--consumer-id <id>] override launch consumer_id
  apps refresh --path <repo>  Re-activate store + sync scaffold (never touches app_logic/)
                          Store free-community activate ? UserGuide ? community cfg ? publish
  apps remove --path <repo> --yes
                          Remove platform /apps/<id> files (local delete does NOT)
                          [--tenant-all] also wipe tenant collections for that id
                          [--with-portal] also DELETE here.now site from portals.json
  apps remove --consumer-id <id> --yes
                          Same without a local folder (cloud UI only)
  version                  Print version
  help                     Print help (includes create phase redo map)

Typical flow (AutoMagic - live on merit-prod):
  .\merit.ps1 create --path ..\<app> --profile fullstack-consumer

Create phase redo map (after a failed phase):
  .\merit.ps1 help
  # prints every verb + the 9-phase redo commands below
  .\merit.ps1 apps publish --path ..\my-app
  # example: redo phase 8 alone after a publish failure
  .\merit.ps1 apps refresh --path ..\my-app
  # rails-only upgrade: store activate + UserGuide + publish (keeps app_logic/)
  .\merit.ps1 create --path ..\my-app --profile fullstack-consumer
  # or re-run full create (idempotent); opens https://merit-prod.vercel.app/apps/<app>/play

Optional later (your own Vercel host):
  .\merit.ps1 create --path ..\my-app --profile fullstack-consumer --deploy --vercel-scope <your-team>
  # or: .\merit.ps1 deploy --path ..\my-app

Redo a single phase anytime - phase map is printed below on help, and again in Recovery tips after a failure.
"@
    Write-CreatePhaseGuide -TargetRoot '..\<app>'
}

function New-UsageOperatorPhrase {
    $wlPath = Join-Path $Root 'cfg/operator_gate_wordlists.excerpt.json'
    $wl = Read-JsonFile $wlPath
    $adj = @($wl.adjectives)
    $noun = @($wl.nouns)
    $a = $adj[(Get-Random -Maximum $adj.Count)]
    $n = $noun[(Get-Random -Maximum $noun.Count)]
    $pin = '{0:D4}' -f (Get-Random -Maximum 10000)
    return "$a-$n-$pin"
}

function Ensure-UsageOperatorPhrase {
    param([string]$TargetRoot, [string]$ConsumerId)
    $envPath = Join-Path $TargetRoot '.env.local'
    $name = Get-UsagePassphraseEnvName -ConsumerId $ConsumerId
    $existing = ''
    if (Test-Path $envPath) {
        foreach ($line in @(Get-Content -LiteralPath $envPath -Encoding UTF8)) {
            if ($line -match "^$([regex]::Escape($name))=(.+)$") {
                $existing = $Matches[1].Trim()
                break
            }
        }
    }
    if (-not $existing) {
        $existing = New-UsageOperatorPhrase
        Set-EnvLocalValue -Path $envPath -Name $name -Value $existing
        Write-Host "Operator usage phrase written to .env.local as $name (open that file; never commit)."
    }
    $hash = Get-Sha256Hex -Text ("usage|" + $ConsumerId.ToLowerInvariant() + "|" + $existing.ToLowerInvariant())
    return $hash
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
    $portalDefaults = @{
        main = (Get-Setting -Settings $settings -Name 'portal_main_slug' -Default $baseSlug)
        journal = (Get-Setting -Settings $settings -Name 'portal_journal_slug' -Default "$baseSlug-journal")
        ama = (Get-Setting -Settings $settings -Name 'portal_ama_slug' -Default "$baseSlug-ama")
        subs = (Get-Setting -Settings $settings -Name 'portal_subs_slug' -Default "$baseSlug-subs")
    }
    $existingSlugs = @{}
    $portalsOut = Join-Path $TargetRoot 'cfg/portals.json'
    if (Test-Path -LiteralPath $portalsOut) {
        try {
            $prev = Read-JsonFile $portalsOut
            foreach ($s in @($prev.surfaces)) {
                $sid = [string]$s.id
                $sslug = [string]$s.slug
                if ($sid -and $sslug -and $sslug -notmatch '^\{\{' ) { $existingSlugs[$sid] = $sslug }
            }
        } catch { }
    }
    function Pick-PortalSlug([string]$Id) {
        if ($existingSlugs.ContainsKey($Id) -and $existingSlugs[$Id] -and $existingSlugs[$Id] -ne $portalDefaults[$Id]) {
            # Keep a previously published here.now slug (random or renamed) so re-apply does not orphan the live site.
            return $existingSlugs[$Id]
        }
        if ($existingSlugs.ContainsKey($Id) -and $existingSlugs[$Id]) { return $existingSlugs[$Id] }
        return $portalDefaults[$Id]
    }
    Write-JsonFile -Path $portalsOut -Object ([ordered]@{
        schema = 'merit.portals.v1'
        surfaces = @(
            [ordered]@{ id = 'main'; path = 'portal/'; slug = (Pick-PortalSlug 'main') },
            [ordered]@{ id = 'journal'; path = 'portal/journal/'; slug = (Pick-PortalSlug 'journal') },
            [ordered]@{ id = 'ama'; path = 'portal/ama/'; slug = (Pick-PortalSlug 'ama') },
            [ordered]@{ id = 'subs'; path = 'portal/subs/'; slug = (Pick-PortalSlug 'subs') }
        )
        notes = 'Generated by merit apply from .merit_launch.md (preserves live here.now slugs).'
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
        $fail += Test-WebpageShellHtml -Path (Join-Path $TargetRoot 'templates/consumer-static/play/index.html.template') -Label 'play template'
        if ($fail.Count) {
            Write-Host "verify FAILED:`n$($fail -join "`n")"
            return $false
        }
        Write-Host "verify OK: merit-agent-skills repo (webpage-shell AP-MA-13)"
        return $true
    }
    foreach ($rel in @('cfg/par_pins.json', 'cfg/branding.json')) {
        if (-not (Test-Path (Join-Path $TargetRoot $rel))) { $fail += "missing $rel" }
    }
    foreach ($rel in @('cfg/community.json', 'cfg/collab_schedule.json', 'cfg/alerts.json')) {
        if (-not (Test-Path (Join-Path $TargetRoot $rel))) {
            if ($env:MERIT_VERIFY_QUIET -ne '1') {
                Write-Host "verify NOTE (optional): missing $rel - skip for OSS freeware; later: .\merit.ps1 community scaffold --path <repo>"
            }
        }
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
    $playHtml = Join-Path $TargetRoot 'play/index.html'
    if (Test-Path -LiteralPath $playHtml) {
        $fail += Test-WebpageShellHtml -Path $playHtml -Label 'play/index.html'
    }
    if ($fail.Count) {
        Write-Host "verify FAILED:`n$($fail -join "`n")"
        return $false
    }
    Write-Host "verify OK: $TargetRoot (webpage-shell AP-MA-13)"
    return $true
}

function Resolve-ScaffoldConsumerId {
    param([string]$TargetRoot)
    $syncPath = Join-Path $TargetRoot 'cfg/merit-sync.json'
    if (Test-Path -LiteralPath $syncPath) {
        try {
            $sync = Read-JsonFile $syncPath
            if ($sync.consumer_id) { return ([string]$sync.consumer_id).Trim().ToLowerInvariant() }
        } catch { }
    }
    $launch = Join-Path $TargetRoot '.merit_launch.md'
    if (Test-Path -LiteralPath $launch) {
        try {
            $settings = Get-LaunchSettings -Path $launch
            $cid = Get-Setting -Settings $settings -Name 'consumer_id'
            if ($cid) { return ([string]$cid).Trim().ToLowerInvariant() }
        } catch { }
    }
    $leaf = Split-Path -Leaf $TargetRoot
    if ($leaf) { return $leaf.Trim().ToLowerInvariant() }
    return 'app'
}

function Invoke-ParScaffold {
    param([string]$TargetRoot, [string]$Variant, [string]$Theme = '', [string]$ConsumerId = '')
    $pinsSrc = Join-Path $Root 'cfg/par_pins.free.json'
    $destCfg = Join-Path $TargetRoot 'cfg'
    New-Item -ItemType Directory -Force -Path $destCfg | Out-Null
    Copy-Item -LiteralPath $pinsSrc -Destination (Join-Path $destCfg 'par_pins.json') -Force
    $pins = Read-JsonFile (Join-Path $destCfg 'par_pins.json')
    $wb = $pins.packages.merit_workbench
    $ux = $pins.packages.merit_ux
    if (-not $ux) { throw 'par scaffold: merit_ux pin missing from cfg/par_pins.free.json (DualRail Gloss)' }
    $playDir = Join-Path $TargetRoot 'play'
    New-Item -ItemType Directory -Force -Path $playDir | Out-Null
    $productName = 'MERIT Play'
    $brandingPath = Join-Path $destCfg 'branding.json'
    $brandTheme = ''
    if (Test-Path -LiteralPath $brandingPath) {
        try {
            $branding = Read-JsonFile $brandingPath
            if ($branding.product_name) { $productName = [string]$branding.product_name }
            if ($branding.gloss_theme) { $brandTheme = [string]$branding.gloss_theme }
            elseif ($branding.theme) { $brandTheme = [string]$branding.theme }
        } catch { }
    }
    $glossTheme = 'gloss-aurora'
    foreach ($candidate in @($Theme, $brandTheme)) {
        if ($candidate -and $candidate -match '^gloss-(aurora|graphite|daylight)$') {
            $glossTheme = $candidate
            break
        }
    }
    $themeArt = $ux.artifacts.themes.$glossTheme
    if (-not $themeArt) {
        $glossTheme = 'gloss-aurora'
        $themeArt = $ux.artifacts.themes.'gloss-aurora'
    }
    $consumerId = if ($ConsumerId) { ([string]$ConsumerId).Trim().ToLowerInvariant() } else { Resolve-ScaffoldConsumerId -TargetRoot $TargetRoot }
    $registerUrl = "https://merit-prod.vercel.app/store/$consumerId/register"
    $communityRailsUrl = 'https://merit-prod.vercel.app/portal/developers/community-rails/'
    $evidenceBaseUrl = 'https://merit-prod.vercel.app/portal/developers/community-rails/evidence'
    $productNameJs = ConvertTo-Json -InputObject $productName -Compress
    $consumerIdJs = ConvertTo-Json -InputObject $consumerId -Compress
    $registerUrlJs = ConvertTo-Json -InputObject $registerUrl -Compress
    $glossThemeJs = ConvertTo-Json -InputObject $glossTheme -Compress
    $communityRailsUrlJs = ConvertTo-Json -InputObject $communityRailsUrl -Compress
    $evidenceBaseUrlJs = ConvertTo-Json -InputObject $evidenceBaseUrl -Compress
    $journalTags = ''
    if ($Variant -eq 'workbench-journal') {
        $jn = $pins.packages.journal
        $journalTags = @"
  <link rel="stylesheet" href="$($jn.artifacts.css.url)" integrity="$($jn.artifacts.css.sri)" crossorigin="anonymous">
  <script type="module" src="$($jn.artifacts.mjs.url)" integrity="$($jn.artifacts.mjs.sri)" crossorigin="anonymous"></script>
"@
    }
    $tplPath = Join-Path $Root 'templates/consumer-static/play/index.html.template'
    $html = Get-Content -LiteralPath $tplPath -Raw -Encoding UTF8
    $html = $html.Replace('{{PRODUCT_NAME_JS}}', $productNameJs).
        Replace('{{PRODUCT_NAME}}', $productName).
        Replace('{{CONSUMER_ID_JS}}', $consumerIdJs).
        Replace('{{REGISTER_URL_JS}}', $registerUrlJs).
        Replace('{{REGISTER_URL}}', $registerUrl).
        Replace('{{GLOSS_THEME_JS}}', $glossThemeJs).
        Replace('{{GLOSS_THEME}}', $glossTheme).
        Replace('{{GLOSS_THEME_CSS_URL}}', [string]$themeArt.url).
        Replace('{{GLOSS_THEME_CSS_SRI}}', [string]$themeArt.sri).
        Replace('{{MERIT_UX_CSS_URL}}', [string]$ux.artifacts.css.url).
        Replace('{{MERIT_UX_CSS_SRI}}', [string]$ux.artifacts.css.sri).
        Replace('{{MERIT_UX_JS_URL}}', [string]$ux.artifacts.js.url).
        Replace('{{MERIT_UX_JS_SRI}}', [string]$ux.artifacts.js.sri).
        Replace('{{WORKBENCH_CSS_URL}}', [string]$wb.artifacts.css.url).
        Replace('{{WORKBENCH_CSS_SRI}}', [string]$wb.artifacts.css.sri).
        Replace('{{WORKBENCH_JS_URL}}', [string]$wb.artifacts.js.url).
        Replace('{{WORKBENCH_JS_SRI}}', [string]$wb.artifacts.js.sri).
        Replace('{{COMMUNITY_RAILS_URL_JS}}', $communityRailsUrlJs).
        Replace('{{COMMUNITY_RAILS_URL}}', $communityRailsUrl).
        Replace('{{EVIDENCE_BASE_URL_JS}}', $evidenceBaseUrlJs).
        Replace('{{EVIDENCE_BASE_URL}}', $evidenceBaseUrl).
        Replace('{{JOURNAL_TAGS}}', $journalTags)
    [System.IO.File]::WriteAllText((Join-Path $playDir 'index.html'), $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host "par scaffold OK ($Variant, $glossTheme) -> $TargetRoot (Make Art DualRail home for $consumerId)"
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
    foreach ($name in @('freemium_limits.json', 'plus_sku.json', 'store_catalog.json')) {
        Copy-Item -LiteralPath (Join-Path $Root "cfg/$name") -Destination (Join-Path $cfg $name) -Force
    }
    $portalsTpl = Join-Path $Root 'cfg/portals.json.template'
    if (Test-Path $portalsTpl) { Copy-Item -LiteralPath $portalsTpl -Destination (Join-Path $cfg 'portals.json') -Force }
    Write-Host "subs scaffold OK -> $cfg (edit consumer_id and register URL)"
}

function Invoke-BaselineCommunityScaffold {
    param([string]$TargetRoot)
    $cfg = Join-Path $TargetRoot 'cfg'
    New-Item -ItemType Directory -Force -Path $cfg | Out-Null
    foreach ($name in @('community.json', 'collab_schedule.json', 'alerts.json', 'usage.json')) {
        $src = Join-Path $Root "cfg/$name"
        $dest = Join-Path $cfg $name
        if (-not (Test-Path -LiteralPath $src)) { throw "baseline community missing template: $src" }
        if (-not (Test-Path -LiteralPath $dest)) {
            Copy-Item -LiteralPath $src -Destination $dest -Force
        }
    }
    Write-Host "baseline community scaffold OK -> $cfg (community / collab_schedule / alerts)"
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
            Write-Host '  floors: FAIL or incomplete - fill APA refs + >=50 edges; see skill merit-livealpha'
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
    foreach ($name in @('freemium_limits.json', 'plus_sku.json', 'store_catalog.json')) {
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
    Write-Host 'Next: open Cursor on this consumer and run /merit-livealpha ...'
    Write-Host '  Or: .\merit.ps1 livealpha status --path <repo>'
}

function Invoke-AdminGateDemoInit {
    param([string]$TargetRoot)
    $envPath = Join-Path $TargetRoot '.env.local'
    if (-not (Test-Path $envPath)) {
        Set-Content -LiteralPath $envPath -Value @(
            '# MERIT demo - local MeritAdminGate placeholders only. Never commit real phrases.',
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
deploy needs your Vercel team slug (own-host step - not required for local dinner taste).
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

function Get-HereNowApiKey {
    if ($env:HERENOW_API_KEY -and "$($env:HERENOW_API_KEY)".Trim()) {
        return "$($env:HERENOW_API_KEY)".Trim()
    }
    $cred = Join-Path $env:USERPROFILE '.herenow\credentials'
    if (Test-Path -LiteralPath $cred) {
        $raw = (Get-Content -LiteralPath $cred -Raw -Encoding UTF8)
        if ($null -eq $raw) { return $null }
        return $raw.Trim()
    }
    return $null
}

function Get-ContentTypeForHereNow {
    param([string]$RelPath)
    $ext = [IO.Path]::GetExtension($RelPath).ToLowerInvariant()
    switch ($ext) {
        '.html' { return 'text/html; charset=utf-8' }
        '.htm' { return 'text/html; charset=utf-8' }
        '.css' { return 'text/css; charset=utf-8' }
        '.js' { return 'text/javascript; charset=utf-8' }
        '.mjs' { return 'text/javascript; charset=utf-8' }
        '.json' { return 'application/json; charset=utf-8' }
        '.svg' { return 'image/svg+xml' }
        '.png' { return 'image/png' }
        '.jpg' { return 'image/jpeg' }
        '.jpeg' { return 'image/jpeg' }
        '.gif' { return 'image/gif' }
        '.webp' { return 'image/webp' }
        '.md' { return 'text/plain; charset=utf-8' }
        '.txt' { return 'text/plain; charset=utf-8' }
        default { return 'application/octet-stream' }
    }
}

function Invoke-HereNowPublishDir {
    param(
        [string]$Dir,
        [string]$Slug,
        [string]$Title = '',
        [string]$Description = '',
        [string]$BaseUrl = 'https://here.now'
    )
    $apiKey = Get-HereNowApiKey
    if (-not $apiKey) {
        throw 'here.now: set HERENOW_API_KEY or ~/.herenow/credentials (BYOK).'
    }
    if (-not (Test-Path -LiteralPath $Dir)) {
        throw "here.now: missing publish dir $Dir"
    }
    $files = @()
    $rootResolved = (Resolve-Path -LiteralPath $Dir).Path
    Get-ChildItem -LiteralPath $Dir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($rootResolved.Length).TrimStart('\', '/').Replace('\', '/')
        if ($rel -match '(^|/)\.herenow(/|$)' -or $rel -match '(^|/)\.DS_Store$' -or $rel -match '(^|/)\.merit-keep$') { return }
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $files += [ordered]@{
            path = $rel
            size = [int]$_.Length
            contentType = (Get-ContentTypeForHereNow -RelPath $rel)
            hash = $hash
            fullPath = $_.FullName
        }
    }
    if ($files.Count -lt 1) {
        throw "here.now: no files under $Dir"
    }
    $manifest = @($files | ForEach-Object {
        [ordered]@{ path = $_.path; size = $_.size; contentType = $_.contentType; hash = $_.hash }
    })
    $bodyObj = [ordered]@{ files = $manifest }
    if ($Title -or $Description) {
        $viewer = [ordered]@{}
        if ($Title) { $viewer.title = $Title }
        if ($Description) { $viewer.description = $Description }
        $bodyObj.viewer = $viewer
    }
    $bodyJson = $bodyObj | ConvertTo-Json -Depth 8 -Compress
    $headers = @{
        Authorization = "Bearer $apiKey"
        'Content-Type' = 'application/json; charset=utf-8'
        'x-herenow-client' = 'merit-ps1/portal'
    }
    $method = 'POST'
    $url = "$BaseUrl/api/v1/publish"
    if ($Slug) {
        $method = 'PUT'
        $url = "$BaseUrl/api/v1/publish/$Slug"
    }
    Write-Host ("here.now: {0} {1} ({2} files)..." -f $method, $url, $files.Count)
    try {
        $resp = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson)) -TimeoutSec 60
    } catch {
        # First-time slug may 404 on PUT - fall back to POST create
        if ($Slug -and ("$($_.Exception.Message)" -match '404|Not Found')) {
            Write-Host "here.now: slug '$Slug' not found - creating new site..."
            $resp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/publish" -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson)) -TimeoutSec 60
        } else {
            throw "here.now create/update failed: $_"
        }
    }
    if ($resp.error) { throw "here.now: $($resp.error)" }
    $outSlug = [string]$resp.slug
    $siteUrl = [string]$resp.siteUrl
    $versionId = [string]$resp.upload.versionId
    $finalizeUrl = [string]$resp.upload.finalizeUrl
    if (-not $outSlug -or -not $finalizeUrl -or -not $versionId) {
        throw "here.now: unexpected response (missing slug/finalize)"
    }
    $uploads = @($resp.upload.uploads)
    if ($uploads.Count -gt 0) {
        Write-Host "here.now: uploading $($uploads.Count) file(s)..."
        $byPath = @{}
        foreach ($f in $files) { $byPath[$f.path] = $f.fullPath }
        foreach ($u in $uploads) {
            $local = $byPath[[string]$u.path]
            if (-not $local -or -not (Test-Path -LiteralPath $local)) {
                throw "here.now: missing local file for upload path $($u.path)"
            }
            $bytes = [IO.File]::ReadAllBytes($local)
            $ct = $null
            if ($u.headers -and $u.headers.'Content-Type') { $ct = [string]$u.headers.'Content-Type' }
            if (-not $ct) { $ct = Get-ContentTypeForHereNow -RelPath ([string]$u.path) }
            try {
                Invoke-WebRequest -Uri ([string]$u.url) -Method Put -Headers @{ 'Content-Type' = $ct } -Body $bytes -UseBasicParsing -TimeoutSec 120 | Out-Null
            } catch {
                throw "here.now upload failed for $($u.path): $_"
            }
        }
    } else {
        Write-Host 'here.now: no new uploads (unchanged files skipped)'
    }
    Write-Host 'here.now: finalizing...'
    $finBody = (@{ versionId = $versionId } | ConvertTo-Json -Compress)
    try {
        $fin = Invoke-RestMethod -Uri $finalizeUrl -Method Post -Headers $headers -Body ([System.Text.Encoding]::UTF8.GetBytes($finBody)) -TimeoutSec 60
    } catch {
        throw "here.now finalize failed: $_"
    }
    if ($fin.error) { throw "here.now finalize: $($fin.error)" }
    if ($fin.siteUrl) { $siteUrl = [string]$fin.siteUrl }
    if (-not $siteUrl) { $siteUrl = "https://$outSlug.here.now" }
    $stateDir = Join-Path $Dir '.herenow'
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    $statePath = Join-Path $stateDir 'state.json'
    (@{ publishes = @{ $outSlug = @{ siteUrl = $siteUrl } } } | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $statePath -Encoding UTF8
    Write-Host "here.now published: $siteUrl"
    return $siteUrl
}


function Invoke-PortalPublish {
    param([string]$TargetRoot, [string[]]$ArgList)
    Invoke-Apply -TargetRoot $TargetRoot -ArgList $ArgList
    if (-not (Get-HereNowApiKey)) {
        throw 'portal publish: set HERENOW_API_KEY or ~/.herenow/credentials (BYOK).'
    }
    $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
    $settings = Get-LaunchSettings -Path $launch
    $cid = Require-Setting -Settings $settings -Name 'consumer_id'
    $pname = Get-Setting -Settings $settings -Name 'product_name' -Default $cid
    $portalsPath = Join-Path $TargetRoot 'cfg/portals.json'
    $published = @()
    if (Test-Path -LiteralPath $portalsPath) {
        $portals = Read-JsonFile $portalsPath
        foreach ($s in @($portals.surfaces)) {
            $sub = Join-Path $TargetRoot ([string]$s.path)
            $idx = Join-Path $sub 'index.html'
            if (-not (Test-Path -LiteralPath $idx)) { continue }
            $slug = [string]$s.slug
            $stateFile = Join-Path $sub '.herenow\state.json'
            if (Test-Path -LiteralPath $stateFile) {
                try {
                    $st = Read-JsonFile $stateFile
                    $live = @($st.publishes.PSObject.Properties.Name) | Select-Object -First 1
                    if ($live) { $slug = [string]$live }
                } catch { }
            }
            if (-not $slug -or $slug -match '^\{\{') {
                throw "portal publish: cfg/portals.json slug for $($s.id) is unset/template - re-run apply"
            }
            $url = Invoke-HereNowPublishDir -Dir $sub -Slug $slug -Title $pname -Description "$pname MERIT portal ($($s.id))"
            $published += [pscustomobject]@{ id = [string]$s.id; slug = $slug; url = $url }
        }
    } else {
        $portalDir = Join-Path $TargetRoot 'portal'
        $baseSlug = Get-Setting -Settings $settings -Name 'here_now_slug' -Default $cid
        $url = Invoke-HereNowPublishDir -Dir $portalDir -Slug $baseSlug -Title $pname -Description "$pname MERIT portal"
        $published += [pscustomobject]@{ id = 'main'; slug = $baseSlug; url = $url }
    }
    if ($published.Count -lt 1) {
        throw 'portal publish: no portal surfaces with index.html found (run create phase 7 first)'
    }
    Write-Host 'portal publish OK:'
    foreach ($p in $published) { Write-Host "  $($p.id): $($p.url)" }
    return $published
}
function Invoke-Closeout {
    param([string]$TargetRoot, [switch]$Release)
    if (-not (Invoke-Verify -TargetRoot $TargetRoot)) { throw 'closeout blocked: verify FAILED' }
    $contractPath = Join-Path $Root 'cfg\merit_closeout_contract.json'
    if (-not (Test-Path -LiteralPath $contractPath)) { throw "closeout blocked: missing law contract $contractPath" }
    $contract = Read-JsonFile -Path $contractPath
    if (-not $contract.chatThreeThreeRequired) { throw 'closeout blocked: law contract does not require chat 3-3' }
    Write-Host ''
    Write-Host 'closeout: displaying binding MERIT law before validation' -ForegroundColor Cyan
    Invoke-MeritLaw -ArgList @('closeout') -RepoRoot $Root
    $head = ''
    $status = @()
    Push-Location $TargetRoot
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            git -c "safe.directory=$TargetRoot" diff --check
            if ($LASTEXITCODE -ne 0) { throw "git diff --check failed (exit $LASTEXITCODE)" }
            $status = @(git -c "safe.directory=$TargetRoot" status --short)
            $head = (git -c "safe.directory=$TargetRoot" rev-parse --short HEAD 2>$null).Trim()
        } else {
            Write-Host 'closeout WARN: git not available on PATH'
        }
        $evidenceDir = $null
        foreach ($candidate in @(
                (Join-Path $TargetRoot 'merit-demo docs\IAR\evidence'),
                (Join-Path $TargetRoot 'docs\IAR\evidence'),
                (Join-Path $TargetRoot '.merit\evidence')
            )) {
            if (Test-Path -LiteralPath $candidate -PathType Container) {
                try { New-Item -ItemType Directory -Force -Path $candidate -ErrorAction Stop | Out-Null; $evidenceDir = $candidate; break } catch { }
            }
        }
        if (-not $evidenceDir) {
            $pathHash = [Security.Cryptography.SHA256]::Create()
            $key = ([BitConverter]::ToString($pathHash.ComputeHash([Text.Encoding]::UTF8.GetBytes($TargetRoot.ToLowerInvariant())))).Replace('-', '')
            $evidenceDir = Join-Path ([IO.Path]::GetTempPath()) "merit-closeout\$key"
            New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
            Write-Host "closeout note: target evidence directory is not writable; using $evidenceDir" -ForegroundColor Yellow
        }
        $receipt = [ordered]@{
            schemaVersion = 1
            status = 'validated'
            target = $TargetRoot
            validatedAt = (Get-Date).ToString('o')
            gitHead = $head
            gitStatus = @($status)
            lawContractId = [string]$contract.contractId
            lawContractVersion = [int]$contract.schemaVersion
            lawCommand = [string]$contract.lawCommand
            validationCommand = [string]$contract.validationCommand
            releaseCommand = [string]$contract.ossReleaseCommand
            operatorReleaseCommand = [string]$contract.operatorReleaseCommand
            chatThreeThreeRequired = [bool]$contract.chatThreeThreeRequired
            releaseNotPerformed = $true
        }
        $receiptPath = Join-Path $evidenceDir 'closeout-validation.json'
        $receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
        Write-Host "closeout receipt: $receiptPath" -ForegroundColor Green
        Write-Host 'closeout: validate only. Run plain .\merit.ps1 closeout for full release closeout.'
        Write-Host 'closeout: webpage-shell AP-MA-13. Checklist: merit-prod docs/IAR/plans/WEBPAGE_SHELL_COMPLIANCE.md'
        Write-Host 'closeout tiers: (1) validate-only = this command; (2) release = plain closeout; (3) operator vault policy; (4) agent response = chat 3-3'
        Write-Host ''
        Write-Host '3-3' -ForegroundColor Cyan
        Write-Host 'Done: validation-only closeout checks completed; no commit or push performed.'
        Write-Host "State: current commit $head; release remains pending."
        Write-Host 'Next: run plain closeout for release, or remediate any failed validation.'
    } finally {
        Pop-Location
    }
}

function Invoke-ReleaseCloseout {
    param([string]$TargetRoot, [string[]]$ArgList)
    if (-not (Invoke-Verify -TargetRoot $TargetRoot)) { throw 'release blocked: verify FAILED' }
    Invoke-Closeout -TargetRoot $TargetRoot
    Push-Location $TargetRoot
    try {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'release blocked: git not available' }
        $branch = (git -c "safe.directory=$TargetRoot" branch --show-current).Trim()
        if ([string]::IsNullOrWhiteSpace($branch)) { throw 'release blocked: detached HEAD; checkout a branch first' }
        $versionFile = Join-Path $TargetRoot 'VERSION'
        $changelogFile = Join-Path $TargetRoot 'CHANGELOG.md'
        if (Test-Path -LiteralPath $versionFile) {
            if (-not (Test-Path -LiteralPath $changelogFile)) { throw 'release blocked: CHANGELOG.md is required when VERSION exists' }
            $version = ((Get-Content -LiteralPath $versionFile -Raw) -split '\r?\n')[0].Trim()
            $changelog = Get-Content -LiteralPath $changelogFile -Raw
            if ($changelog -notmatch [regex]::Escape($version)) { throw "release blocked: CHANGELOG.md has no entry for VERSION $version" }
        }
        git -c "safe.directory=$TargetRoot" add -A
        $message = if ($ArgList -contains '-Message') { Get-ArgValue -ArgList $ArgList -Name '-Message' } else { 'chore: MERIT release closeout' }
        if ([string]::IsNullOrWhiteSpace($message)) { $message = 'chore: MERIT release closeout' }
        $pending = @(git -c "safe.directory=$TargetRoot" status --porcelain)
        if ($pending.Count -gt 0) {
            git -c "safe.directory=$TargetRoot" commit -m $message
            if ($LASTEXITCODE -ne 0) { throw "release blocked: git commit failed (exit $LASTEXITCODE)" }
        } else { Write-Host 'release closeout: no local changes; continuing with remote push/tag verification.' }
        git -c "safe.directory=$TargetRoot" push origin $branch
        if ($LASTEXITCODE -ne 0) { throw "release blocked: git push failed (exit $LASTEXITCODE)" }
        Write-Host "release closeout OK: pushed $branch" -ForegroundColor Green
        if ((Test-Path (Join-Path $TargetRoot 'skills')) -and (Test-Path (Join-Path $TargetRoot 'VERSION'))) {
            $version = ((Get-Content (Join-Path $TargetRoot 'VERSION') -Raw) -split '\r?\n')[0].Trim()
            $prefix = if (Test-Path (Join-Path $TargetRoot 'TAG_PREFIX')) { ((Get-Content (Join-Path $TargetRoot 'TAG_PREFIX') -Raw) -split '\r?\n')[0].Trim() } else { 'skills-v' }
            $tag = "$prefix$version"
            if (-not (git tag --points-at HEAD | Where-Object { $_ -eq $tag })) { git tag -a $tag -m "${tag}: MERIT release closeout"; if ($LASTEXITCODE -ne 0) { throw "release blocked: tag creation failed (exit $LASTEXITCODE)" } }
            git push origin $tag
            if ($LASTEXITCODE -ne 0) { throw "release blocked: tag push failed (exit $LASTEXITCODE)" }
            Write-Host "release closeout OK: pushed tag $tag" -ForegroundColor Green
        }
        Write-Host ''
        Write-Host '3-3' -ForegroundColor Cyan
        Write-Host "Done: release closeout validated, committed, and pushed $branch."
        Write-Host "State: commit $((git rev-parse --short HEAD).Trim()); remote origin; release tag handled by skills release policy."
        Write-Host 'Next: review the remote commit; continue with the next scoped task or run validation-only for diagnostics.'
    } finally { Pop-Location }
}

function Test-MeritWindowsAdmin {
    if ($env:OS -notmatch 'Windows') { return $false }
    try {
        return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Invoke-AdminRepairOwnership {
    param([string]$TargetRoot, [string[]]$ArgList)
    if (-not ($env:OS -match 'Windows')) { throw 'admin repair-ownership is currently supported on Windows only' }
    if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) { throw "admin repair-ownership: repo directory not found: $TargetRoot" }
    $resolved = (Resolve-Path -LiteralPath $TargetRoot).Path.TrimEnd('\', '/')
    $root = [IO.Path]::GetPathRoot($resolved).TrimEnd('\', '/')
    if ($resolved -eq $root) { throw 'admin repair-ownership refuses a filesystem root; pass an exact repository path' }
    if (-not (Test-Path -LiteralPath (Join-Path $resolved '.git'))) {
        throw "admin repair-ownership: target is not a Git worktree (.git missing): $resolved"
    }
    $yes = (Test-ArgFlag -ArgList $ArgList -Name '--yes') -or (Test-ArgFlag -ArgList $ArgList -Name '-Force')
    if (-not $yes) {
        Write-Host "This will take ownership and grant Modify to the current user recursively under:`n  $resolved" -ForegroundColor Yellow
        $answer = Read-Host 'Continue? [y/N]'
        if ($answer -notmatch '^[Yy]$') { Write-Host 'admin repair-ownership: cancelled'; return }
    }
    if (-not (Test-MeritWindowsAdmin)) {
        $hostExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $scriptPath = $PSCommandPath
        $argText = '-NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '" admin repair-ownership --path "' + $resolved + '" --yes'
        Write-Host 'Administrator permission is required. Requesting UAC elevation...' -ForegroundColor Yellow
        $proc = Start-Process -FilePath $hostExe -Verb RunAs -ArgumentList $argText -Wait -PassThru
        if ($proc.ExitCode -ne 0) { throw "admin repair-ownership elevated process failed (exit $($proc.ExitCode))" }
        return
    }
    $takeown = Join-Path $env:SystemRoot 'System32\takeown.exe'
    $icacls = Join-Path $env:SystemRoot 'System32\icacls.exe'
    $principal = if ($env:USERDOMAIN) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
    Write-Host "admin repair-ownership: takeown $resolved" -ForegroundColor Cyan
    & $takeown /F $resolved /R /D Y
    if ($LASTEXITCODE -ne 0) { throw "takeown failed (exit $LASTEXITCODE)" }
    Write-Host "admin repair-ownership: grant Modify to $principal" -ForegroundColor Cyan
    & $icacls $resolved /grant "${principal}:(OI)(CI)M" /T /C
    if ($LASTEXITCODE -ne 0) { throw "icacls failed (exit $LASTEXITCODE)" }
    $probe = Join-Path $resolved '.merit-write-probe.tmp'
    try {
        Set-Content -LiteralPath $probe -Value 'write probe' -Encoding ASCII
        Remove-Item -LiteralPath $probe -Force
    } catch { throw "ownership repair completed but write probe failed: $($_.Exception.Message)" }
    $owner = (Get-Acl -LiteralPath $resolved).Owner
    Write-Host "admin repair-ownership OK: owner=$owner writable=yes target=$resolved" -ForegroundColor Green
}

function Invoke-AdminOwnershipStatus {
    param([string]$TargetRoot)
    if (-not ($env:OS -match 'Windows')) { throw 'admin ownership status is currently supported on Windows only' }
    if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) { throw "admin ownership status: repo directory not found: $TargetRoot" }
    $resolved = (Resolve-Path -LiteralPath $TargetRoot).Path.TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath (Join-Path $resolved '.git'))) { throw "admin ownership status: .git missing under $resolved" }
    $acl = Get-Acl -LiteralPath $resolved
    Write-Host "owner: $($acl.Owner)"
    Write-Host 'relevant ACL entries:'
    $acl.Access | Where-Object { $_.IdentityReference -match 'Administrators|Users|Authenticated Users|Draven|Codex' } |
        Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited |
        Format-Table -AutoSize | Out-Host
    $probe = Join-Path $resolved '.merit-ownership-status.tmp'
    try {
        Set-Content -LiteralPath $probe -Value 'write probe' -Encoding ASCII -ErrorAction Stop
        Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
        Write-Host 'write probe: PASS' -ForegroundColor Green
    } catch {
        Write-Host "write probe: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    }
    $safe = git -c "safe.directory=$resolved" -C $resolved status --porcelain 2>&1
    if ($LASTEXITCODE -eq 0) { Write-Host 'git safe-directory probe: PASS' -ForegroundColor Green }
    else { Write-Host "git safe-directory probe: FAIL - $($safe -join ' ')" -ForegroundColor Red }
}

function Invoke-AdminGithubAccess {
    param([string[]]$ArgList)
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'admin github access requires GitHub CLI (gh) on PATH' }
    $sub = if ($ArgList.Count -gt 2) { "$($ArgList[2])".ToLowerInvariant() } else { 'status' }
    if ($sub -eq 'switch') {
        $switchArgs = @('github','auth','switch')
        if ($ArgList.Count -gt 3) { $switchArgs += @($ArgList[3..($ArgList.Count - 1)]) }
        Invoke-AdminGithubAuth -ArgList $switchArgs
        return
    }
    $repo = Get-ArgValue -ArgList $ArgList -Name '--repo'
    if ([string]::IsNullOrWhiteSpace($repo)) { $remote = (& git remote get-url origin 2>$null).Trim(); if ($remote -match 'github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$') { $repo = "$($Matches[1])/$($Matches[2])" } }
    if ([string]::IsNullOrWhiteSpace($repo) -or $repo -notmatch '^[^/\s]+/[^/\s]+$') { throw 'Could not infer GitHub repo from origin; pass --repo <owner/name>' }
    $user = Get-ArgValue -ArgList $ArgList -Name '--user'
    if ([string]::IsNullOrWhiteSpace($user)) { $user = (& gh api user --jq .login 2>$null).Trim() }
    if ([string]::IsNullOrWhiteSpace($user) -or $user -notmatch '^[A-Za-z0-9-]+$') { throw 'Could not infer GitHub user; pass --user <login>' }
    $endpoint = "repos/$repo/collaborators/$user"
    if ($sub -eq 'status') { Write-Host "MERIT access context: repo=$repo user=$user cwd=$((Get-Location).Path) origin=$((& git remote get-url origin 2>$null).Trim())" -ForegroundColor Cyan }
    switch ($sub) {
        'status' {
            $response = (& gh api $endpoint --jq '{user: .login, permissions: .permissions}' 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) {
                if ($response -match 'Must have push access|HTTP 403') { throw "GitHub access status unavailable: the active account ($user) cannot view collaborator permissions for $repo. Ask a repository administrator to run the access check." }
                if ($response -match 'Not Found|HTTP 404') { throw "GitHub access status unavailable: $repo was not found or the active account cannot administer it." }
                throw "GitHub access status failed: $response"
            }
            if ([string]::IsNullOrWhiteSpace($response)) {
                Write-Host "GitHub access status: $user on $repo -> collaborator access present (HTTP 204; no permission body returned)." -ForegroundColor Green
            } else {
                try {
                    $obj = $response | ConvertFrom-Json
                    $perms = $obj.permissions
                    Write-Host "GitHub access status: $user on $repo" -ForegroundColor Green
                    Write-Host ("  admin={0} maintain={1} push={2} triage={3} pull={4}" -f $perms.admin,$perms.maintain,$perms.push,$perms.triage,$perms.pull)
                } catch { Write-Host "GitHub access status: $user on $repo -> collaborator access present" -ForegroundColor Green }
            }
        }
        'add' {
            $permission = Get-ArgValue -ArgList $ArgList -Name '--permission'; if ([string]::IsNullOrWhiteSpace($permission)) { $permission = Read-Host 'Permission [pull/triage/push/maintain/admin] (default push)'; if ([string]::IsNullOrWhiteSpace($permission)) { $permission = 'push' } }
            if ($permission -notin @('pull','triage','push','maintain','admin')) { throw 'permission must be pull, triage, push, maintain, or admin' }
            if (-not (Test-ArgFlag -ArgList $ArgList -Name '--yes')) { $answer = Read-Host "Grant $permission access to $user on $repo? [y/N]"; if ($answer -notmatch '^[Yy]$') { Write-Host 'GitHub access add: cancelled'; return } }
            $response = (& gh api --method PUT $endpoint --field permission=$permission 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) {
                if ($response -match 'Not Found|HTTP 404') { throw "GitHub access grant failed: the active account cannot administer $repo, or the repository does not exist. Switch to the repository owner/admin account, then retry." }
                if ($response -match 'HTTP 403|Forbidden') { throw "GitHub access grant failed: the active account is not allowed to manage collaborators for $repo." }
                throw "GitHub access grant failed: $response"
            }
            Write-Host "GitHub access granted: $user -> $repo ($permission)" -ForegroundColor Green
        }
        'remove' {
            if (-not (Test-ArgFlag -ArgList $ArgList -Name '--yes')) { $answer = Read-Host "Remove access for $user from $repo? [y/N]"; if ($answer -notmatch '^[Yy]$') { Write-Host 'GitHub access remove: cancelled'; return } }
            $response = (& gh api --method DELETE $endpoint 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) {
                if ($response -match 'Not Found|HTTP 404|HTTP 403') { throw "GitHub access removal failed: the active account cannot administer $repo, or the collaborator was not found." }
                throw "GitHub access removal failed: $response"
            }
            Write-Host "GitHub access removed: $user from $repo" -ForegroundColor Green
        }
        default { throw 'use admin github access status|add|remove' }
    }
}

function Invoke-AdminGithubAuth {
    param([string[]]$ArgList)
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'admin github auth requires GitHub CLI (gh) on PATH' }
    $action = if ($ArgList.Count -gt 2) { "$($ArgList[2])".ToLowerInvariant() } else { 'status' }
    switch ($action) {
        'status' {
            & gh auth status
            if ($LASTEXITCODE -ne 0) { throw "GitHub auth status failed (exit $LASTEXITCODE)" }
        }
        'login' {
            Write-Host 'Opening GitHub authentication. Complete the browser/device flow for the repository-owner account.' -ForegroundColor Cyan
            # HTTPS avoids the post-login SSH-key upload prompt and works even when
            # the selected account already has this laptop's public key registered.
            & gh auth login --hostname github.com --git-protocol https --web
            if ($LASTEXITCODE -ne 0) { throw "GitHub auth login failed (exit $LASTEXITCODE)" }
            Write-Host 'GitHub authentication completed. Run admin github auth status, then admin github auth switch if needed.' -ForegroundColor Green
        }
        'switch' {
            $user = Get-ArgValue -ArgList $ArgList -Name '--user'
            if ([string]::IsNullOrWhiteSpace($user)) { $user = Read-Host 'GitHub account to activate (login)' }
            if ([string]::IsNullOrWhiteSpace($user)) { throw 'GitHub account login is required' }
            & gh auth switch --user $user
            if ($LASTEXITCODE -ne 0) { throw "GitHub auth switch failed (exit $LASTEXITCODE)" }
            Write-Host "GitHub account active: $user" -ForegroundColor Green
        }
        default { throw 'use admin github auth status|login|switch [--user <login>]' }
    }
}

function Invoke-ConsumerE2E {
    param([string]$TargetRoot, [ValidateSet('e2e','e2e:playwright')][string]$Mode)
    $packagePath = Join-Path $TargetRoot 'package.json'
    if (-not (Test-Path -LiteralPath $packagePath)) {
        throw "$Mode requires package.json under $TargetRoot"
    }
    $package = Read-JsonFile -Path $packagePath
    $scriptName = $Mode
    if (-not $package.scripts -or -not $package.scripts.PSObject.Properties.Name.Contains($scriptName)) {
        throw "$Mode requires package.json script '$scriptName' under $TargetRoot"
    }
    Push-Location $TargetRoot
    try {
        Write-Host "consumer ${Mode}: npm run $scriptName"
        & npm run $scriptName
        if ($LASTEXITCODE -ne 0) {
            throw "consumer $Mode failed (exit $LASTEXITCODE)"
        }
    } finally {
        Pop-Location
    }
    Write-Host "consumer $Mode OK: $TargetRoot"
}

function Test-MeritSkillsShipRepo {
    param([string]$RepoRoot)
    $tagFile = Join-Path $RepoRoot 'TAG_PREFIX'
    $verFile = Join-Path $RepoRoot 'VERSION'
    $skills = Join-Path $RepoRoot 'skills'
    if (-not (Test-Path -LiteralPath $tagFile)) { return $false }
    if (-not (Test-Path -LiteralPath $verFile)) { return $false }
    if (-not (Test-Path -LiteralPath $skills)) { return $false }
    return $true
}

function Invoke-MeritWhere {
    param([string[]]$ArgList)
    $noWrite = Test-ArgFlag -ArgList $ArgList -Name '-NoWrite'
    $asJson = Test-ArgFlag -ArgList $ArgList -Name '-Json'
    if (-not (Get-Command Get-MeritSurface -ErrorAction SilentlyContinue)) {
        Write-Host 'where: BootStrap\_resolve.ps1 not loaded'
        exit 1
    }
    $surf = Get-MeritSurface -NoWrite:$noWrite
    Write-MeritAccessContext -Surface $surf -AsJson:$asJson
    Write-MeritSurfaceReport -Surface $surf -AsJson:$asJson
    exit 0
}

function Write-MeritAccessContext {
    param($Surface, [switch]$AsJson)
    $cwd = (Get-Location).Path
    $origin = (& git remote get-url origin 2>$null).Trim()
    $repo = if ($origin -match 'github\.com[:/]([^/]+)/([^/]+?)(?:\.git)?$') { "$($Matches[1])/$($Matches[2])" } else { '' }
    $ghUser = if (Get-Command gh -ErrorAction SilentlyContinue) { (& gh api user --jq .login 2>$null).Trim() } else { '' }
    $ctx = [ordered]@{ cwd = $cwd; origin = $origin; githubRepo = $repo; githubUser = $ghUser; MYMERITAPP = $env:MYMERITAPP; MYMERITTOOLS = $env:MYMERITTOOLS; skillsRoot = $Surface.skillsRoot; demoFolder = $Surface.demoFolder; authStatus = if ($ghUser) { 'authenticated' } else { 'unknown-or-not-installed' } }
    if ($AsJson) { Write-Host (($ctx | ConvertTo-Json -Depth 5 -Compress)); return }
    Write-Host 'MERIT access context:' -ForegroundColor Cyan
    foreach ($p in $ctx.GetEnumerator()) { if ($p.Value) { Write-Host ("  {0}: {1}" -f $p.Key, $p.Value) } }
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
        Write-Host 'create NOTE: vercel_scope=local means platform host on merit-prod /apps (cloud). Own Vercel later: --deploy --vercel-scope <your-team>.'
    }
    if ($sbUrl -eq 'https://platform-defaults.merit.local') {
        Write-Host 'create NOTE: supabase_* are scaffold placeholders - platform rails via merit-prod; BYOK optional later.'
    }
}

function Invoke-PortalScaffold {
    param(
        [string]$TargetRoot,
        [string]$ProductName,
        [string]$ConsumerId,
        [string]$AppUrl = '',
        [string]$PortalUrl = ''
    )
    if (-not $AppUrl) { $AppUrl = "https://merit-prod.vercel.app/apps/$ConsumerId/play" }
    if (-not $PortalUrl) { $PortalUrl = "https://$ConsumerId.here.now" }
    $portalDir = Join-Path $TargetRoot 'portal'
    New-Item -ItemType Directory -Force -Path $portalDir | Out-Null
    $keep = Join-Path $portalDir '.merit-keep'
    $indexPath = Join-Path $portalDir 'index.html'
    $tpl = Join-Path $Root 'templates/portal/index.html'
    if (Test-Path -LiteralPath $keep) {
        Write-Host "portal scaffold skipped (.merit-keep): $indexPath"
    } elseif (-not (Test-Path -LiteralPath $tpl)) {
        throw "portal scaffold: missing template $tpl"
    } else {
        $html = Get-Content -LiteralPath $tpl -Raw -Encoding UTF8
        $html = $html.Replace('{{PRODUCT_NAME}}', $ProductName).Replace('{{CONSUMER_ID}}', $ConsumerId).Replace('{{APP_URL}}', $AppUrl).Replace('{{DINNER_URL}}', 'https://merit-prod.vercel.app/portal/developers/full-app/')
        Set-Content -LiteralPath $indexPath -Value $html -Encoding UTF8
        Write-Host "portal jumpstart OK -> $indexPath (overwrite unless portal/.merit-keep)"
    }

    $docsDir = Join-Path $TargetRoot 'docs'
    New-Item -ItemType Directory -Force -Path $docsDir | Out-Null
    $prdPath = Join-Path $docsDir 'PRODUCT.prd.md'
    $prdTemplate = Join-Path $Root 'skills/merit-prd/examples/PRODUCT.prd.md'
    $prdKeep = Join-Path $docsDir '.merit-prd-keep'
    if (Test-Path -LiteralPath $prdKeep) {
        Write-Host "prd scaffold skipped (.merit-prd-keep): $prdPath"
    } elseif (Test-Path -LiteralPath $prdTemplate) {
        $prd = Get-Content -LiteralPath $prdTemplate -Raw -Encoding UTF8
        $prd = $prd.Replace('{{PRODUCT_NAME}}', $ProductName).Replace('{{CONSUMER_ID}}', $ConsumerId).Replace('{{APP_URL}}', $AppUrl).Replace('{{PORTAL_URL}}', $PortalUrl)
        Set-Content -LiteralPath $prdPath -Value $prd -Encoding UTF8
        Write-Host "prd template OK -> $prdPath (fill with /merit-prd; Make Art + anti-patterns included)"
    } else {
        Set-Content -LiteralPath $prdPath -Value @"
# $ProductName PRD

Fill this brief, then use ``/merit-prd`` in your AI IDE and ``/merit-portal`` for marketing.
See merit-agent-skills ``skills/merit-prd/examples/PRODUCT.prd.md``.

consumer_id=$ConsumerId
live_app=$AppUrl
"@ -Encoding UTF8
        Write-Host "prd stub OK -> $prdPath"
    }

    Write-UserGuideScaffold -TargetRoot $TargetRoot -ProductName $ProductName -ConsumerId $ConsumerId -Force:$false

    $logicDir = Join-Path $TargetRoot 'app_logic'
    New-Item -ItemType Directory -Force -Path $logicDir | Out-Null
    $readme = Join-Path $logicDir 'README.md'
    Set-Content -LiteralPath $readme -Value @"
# app_logic/

Product features for ``$ConsumerId`` live here.

- Rails: auth, store, and payments come from ``merit-prod.vercel.app`` (isolated by ``consumer_id``).
- After create: fill ``docs/PRODUCT.prd.md`` (``/merit-prd``), shape ``portal/`` (``/merit-portal``), then run ``/merit-applogic`` for Must FRs.
- Prove on the cloud app URL: ``$AppUrl``.
- Jumpstart marketing + workflow: ``portal/index.html`` (published to here.now in create phase 8 when credentials exist).

Generated by ``merit.ps1 create``.
"@ -Encoding UTF8
    Write-Host "app_logic README OK -> $readme"
}

function Write-UserGuideScaffold {
    param(
        [string]$TargetRoot,
        [string]$ProductName,
        [string]$ConsumerId,
        [bool]$Force = $false,
        [string]$Gateway = 'https://merit-prod.vercel.app'
    )
    $docsDir = Join-Path $TargetRoot 'docs'
    New-Item -ItemType Directory -Force -Path $docsDir | Out-Null
    $guidePath = Join-Path $docsDir 'UserGuide.md'
    $keep = Join-Path $docsDir '.merit-userguide-keep'
    if ((Test-Path -LiteralPath $keep) -and -not $Force) {
        Write-Host "UserGuide scaffold skipped (.merit-userguide-keep): $guidePath"
        return
    }
    if ((Test-Path -LiteralPath $guidePath) -and -not $Force) {
        $existing = Get-Content -LiteralPath $guidePath -Raw -Encoding UTF8
        if ($existing -notmatch 'MERIT_SCAFFOLD:user-guide') {
            Write-Host "UserGuide scaffold skipped (custom docs/UserGuide.md without scaffold marker): $guidePath"
            return
        }
    }
    $tpl = Join-Path $Root 'templates/consumer-static/docs/UserGuide.md.template'
    $playUrl = "$Gateway/apps/$ConsumerId/play"
    $registerUrl = "$Gateway/store/$ConsumerId/register"
    if (Test-Path -LiteralPath $tpl) {
        $body = Get-Content -LiteralPath $tpl -Raw -Encoding UTF8
        $body = $body.Replace('{{PRODUCT_NAME}}', $ProductName).Replace('{{CONSUMER_ID}}', $ConsumerId).Replace('{{PLAY_URL}}', $playUrl).Replace('{{REGISTER_URL}}', $registerUrl)
        Set-Content -LiteralPath $guidePath -Value $body -Encoding UTF8
        Write-Host "UserGuide OK -> $guidePath (ToC ? If/Then ? OH/Consult ? OIDs)"
    } else {
        Set-Content -LiteralPath $guidePath -Value @"
---
# MERIT_SCAFFOLD:user-guide:v1
---
# User Guide ? $ProductName

Play: $playUrl  
Register: $registerUrl  

Join Free (email + handle). Optional Office Hours / Consult add-ons on register.
See merit-agent-skills templates/consumer-static/docs/UserGuide.md.template for the full scaffold.
"@ -Encoding UTF8
        Write-Host "UserGuide stub OK -> $guidePath"
    }
}

function Invoke-AppsRefresh {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string[]]$ArgList,
        [string]$Gateway = 'https://merit-prod.vercel.app'
    )
    # GOAT lifecycle verb: re-activate store catalog + sync rails scaffold without touching app_logic/.
    Write-Host "apps refresh: consumer_id=$ConsumerId (never edits app_logic/)"
    $logicProbe = Join-Path $TargetRoot 'app_logic'
    if (-not (Test-Path -LiteralPath $logicProbe)) {
        Write-Host 'apps refresh NOTE: app_logic/ missing ? create first if this is a new app.'
    }

    # 1) Store free-community re-activate (idempotent catalog refresh).
    $activateUri = "$Gateway/api/meritstore/v1/tenants/$ConsumerId/activate"
    $display = $ConsumerId
    try {
        $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
        $settings = Get-LaunchSettings -Path $launch
        $pn = Get-Setting -Settings $settings -Name 'product_name' -Default $ConsumerId
        if ($pn) { $display = [string]$pn }
    } catch { }
    $activateBody = (@{ template = 'free-community'; display_name = $display } | ConvertTo-Json -Compress)
    try {
        $null = Invoke-RestMethod -Uri $activateUri -Method Post -Body $activateBody -ContentType 'application/json' -TimeoutSec 60
        Write-Host "Store re-activated (free-community): $Gateway/store/$ConsumerId/register"
    } catch {
        throw "apps refresh: store activate failed ($activateUri). $_"
    }

    # 2) Baseline community cfg (overwrite only when present templates allow).
    try {
        Invoke-BaselineCommunityScaffold -TargetRoot $TargetRoot
    } catch {
        Write-Host "apps refresh NOTE: community scaffold: $($_.Exception.Message)"
    }

    # 2b) PAR pins + play shell from skills SSOT (never app_logic/).
    try {
        $playHtml = Join-Path $TargetRoot 'play/index.html'
        if (Test-Path -LiteralPath $playHtml) {
            $pinsProbe = Read-JsonFile (Join-Path $Root 'cfg/par_pins.free.json')
            $variant = if ($pinsProbe.packages.journal) { 'workbench-journal' } else { 'workbench' }
            Invoke-ParScaffold -TargetRoot $TargetRoot -Variant $variant
            Write-Host 'apps refresh: par pins + play resynced from cfg/par_pins.free.json'
        }
    } catch {
        Write-Host "apps refresh NOTE: par pin resync: $($_.Exception.Message)"
    }

    # 3) UserGuide ? refresh when scaffold marker present (or missing).
    Write-UserGuideScaffold -TargetRoot $TargetRoot -ProductName $display -ConsumerId $ConsumerId -Force:$false -Gateway $Gateway

    # 4) Republish play/+cfg/ to platform.
    $url = Invoke-AppsPublish -TargetRoot $TargetRoot -ConsumerId $ConsumerId -Gateway $Gateway
    Write-Host "apps refresh OK: $url"
    Write-Host "Register: $Gateway/store/$ConsumerId/register"
    Write-Host "Member guide: $(Join-Path $TargetRoot 'docs\UserGuide.md')"
    return $url
}

function Get-ContentTypeForPublish {
    param([string]$RelPath)
    $lower = $RelPath.ToLowerInvariant()
    if ($lower.EndsWith('.html') -or $lower.EndsWith('.htm')) { return 'text/html; charset=utf-8' }
    if ($lower.EndsWith('.css')) { return 'text/css; charset=utf-8' }
    if ($lower.EndsWith('.js') -or $lower.EndsWith('.mjs')) { return 'text/javascript; charset=utf-8' }
    if ($lower.EndsWith('.json')) { return 'application/json; charset=utf-8' }
    if ($lower.EndsWith('.svg')) { return 'image/svg+xml' }
    return 'text/plain; charset=utf-8'
}

function ConvertTo-JsonEscapedString {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return '""' }
    # Avoid ConvertTo-Json on large trees (Windows PowerShell can hang / bloat). Escape one string safely.
    $sb = [System.Text.StringBuilder]::new($Value.Length + 16)
    [void]$sb.Append('"')
    foreach ($ch in $Value.ToCharArray()) {
        switch ($ch) {
            '"' { [void]$sb.Append('\"') }
            '\' { [void]$sb.Append('\\') }
            "`b" { [void]$sb.Append('\b') }
            "`f" { [void]$sb.Append('\f') }
            "`n" { [void]$sb.Append('\n') }
            "`r" { [void]$sb.Append('\r') }
            "`t" { [void]$sb.Append('\t') }
            default {
                $code = [int][char]$ch
                if ($code -lt 0x20) {
                    [void]$sb.AppendFormat('\u{0:x4}', $code)
                } else {
                    [void]$sb.Append($ch)
                }
            }
        }
    }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Invoke-AppsPublish {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string]$Gateway = 'https://merit-prod.vercel.app'
    )
    # Vercel Functions reject bodies > ~4.5MB (413 FUNCTION_PAYLOAD_TOO_LARGE).
    # Upload one file per request so dinner create never hits that ceiling.
    Write-Host "Packing play/ + cfg/ for $Gateway/apps/$ConsumerId/play ..."
    $files = [System.Collections.Generic.List[object]]::new()
    $totalBytes = 0
    foreach ($folder in @('play', 'cfg')) {
        $root = Join-Path $TargetRoot $folder
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
            $rel = ($folder + '/' + $_.FullName.Substring($root.Length).TrimStart('\', '/')).Replace('\', '/')
            if ($rel -notmatch '\.(html?|css|js|mjs|json|svg|txt|md)$') { return }
            $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
            if ($null -eq $content) { $content = '' }
            $bytes = [System.Text.Encoding]::UTF8.GetByteCount($content)
            if ($bytes -gt 200000) {
                throw "apps publish: $rel is $bytes bytes (max 200000). Shrink the file or exclude it from play/cfg."
            }
            $totalBytes += $bytes
            $files.Add([ordered]@{
                path = $rel
                content = $content
                contentType = (Get-ContentTypeForPublish -RelPath $rel)
                bytes = $bytes
            })
        }
    }
    if ($files.Count -lt 1) {
        throw "apps publish: no play/ or cfg/ files under $TargetRoot"
    }
    $usageGateHash = ''
    try {
        $usageGateHash = Ensure-UsageOperatorPhrase -TargetRoot $TargetRoot -ConsumerId $ConsumerId
    } catch {
        Write-Host 'apps publish NOTE: no local usage operator phrase (optional - the usage gate stays unset).'
    }
    $kb = [math]::Max(1, [math]::Round($totalBytes / 1KB, 1))
    Write-Host "Packed $($files.Count) file(s) (~$kb KB). Uploading in batches..."

    $appUrl = Send-AppFileList -Files $files -ConsumerId $ConsumerId -Gateway $Gateway -UsageGateHash $usageGateHash -Label 'apps publish'
    if (-not $appUrl) {
        throw 'apps publish returned no appUrl'
    }
    Write-Host "Live app URL: $appUrl"
    return $appUrl
}

function Send-AppFileList {
    param(
        [object[]]$Files,
        [string]$ConsumerId,
        [string]$Gateway = 'https://merit-prod.vercel.app',
        [string]$UsageGateHash = '',
        [string]$Label = 'apps publish'
    )
    # Batch per request: the gateway counts requests against the free-community publish
    # quota, and one-file-per-request burns it fast. Chunks stay well under the Vercel
    # ~4.5MB body ceiling and the gateway's 40-file / 600KB payload limits.
    $maxFilesPerRequest = 15
    $maxBytesPerRequest = 400000
    $chunks = [System.Collections.Generic.List[object]]::new()
    $current = [System.Collections.Generic.List[object]]::new()
    $currentBytes = 0
    foreach ($file in $Files) {
        if ($current.Count -ge $maxFilesPerRequest -or ($current.Count -gt 0 -and ($currentBytes + $file.bytes) -gt $maxBytesPerRequest)) {
            $chunks.Add($current)
            $current = [System.Collections.Generic.List[object]]::new()
            $currentBytes = 0
        }
        $current.Add($file)
        $currentBytes += $file.bytes
    }
    if ($current.Count -gt 0) { $chunks.Add($current) }

    # Invoke-WebRequest: works on Windows PowerShell 5.1 without System.Net.Http assembly load.
    $appUrl = $null
    $n = 0
    foreach ($chunk in $chunks) {
        $n++
        $names = (@($chunk | ForEach-Object { $_.path }) -join ', ')
        if ($names.Length -gt 90) { $names = $names.Substring(0, 90) + '...' }
        Write-Host "  [$n/$($chunks.Count)] $($chunk.Count) file(s): $names"
        $parts = New-Object System.Collections.Generic.List[string]
        foreach ($file in $chunk) {
            $parts.Add(
                ('{"path":' + (ConvertTo-JsonEscapedString $file.path) +
                 ',"content":' + (ConvertTo-JsonEscapedString $file.content) +
                 ',"contentType":' + (ConvertTo-JsonEscapedString $file.contentType) + '}')
            )
        }
        $payload = '{"consumerId":' + (ConvertTo-JsonEscapedString $ConsumerId)
        if ($UsageGateHash -and $n -eq 1) {
            $payload += ',"usage_gate_hash":' + (ConvertTo-JsonEscapedString $UsageGateHash)
        }
        $payload += ',"files":[' + ($parts -join ',') + ']}'
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        try {
            $wr = Invoke-WebRequest -Uri "$Gateway/api/apps/publish" -Method Post -Body $bodyBytes -ContentType 'application/json; charset=utf-8' -UseBasicParsing -TimeoutSec 90
            $resp = $wr.Content | ConvertFrom-Json
        } catch {
            $detail = "$_"
            if ($detail -match 'rate_limited') {
                $wait = 300
                if ($detail -match '"retry_after_sec"\s*:\s*(\d+)') { $wait = [int]$Matches[1] }
                throw "$Label hit the free-community publish quota. Wait about $wait seconds and re-run (publishing is idempotent)."
            }
            throw "$Label failed on batch $n ($Gateway/api/apps/publish). Re-run is safe + idempotent. $detail"
        }
        if (-not $resp.ok -or -not $resp.appUrl) {
            throw "$Label rejected on batch $n : $($wr.Content)"
        }
        $appUrl = [string]$resp.appUrl
    }
    return $appUrl
}

function Test-OcConsumerId {
    param([string]$ConsumerId)
    $id = ([string]$ConsumerId).Trim().ToLowerInvariant()
    if ($id -notmatch '^oc-[a-z0-9][a-z0-9-]{0,58}$') {
        throw 'oc: consumer-id must look like oc-a1b2c3d4e5 (prefix oc-, a-z0-9- only)'
    }
    return $id
}

function Set-OcCreatorFace {
    param(
        [string]$TargetRoot,
        [string]$ProductName,
        [string]$PlayUrl,
        [string]$RegisterUrl,
        [string]$ConsumerId = '',
        [string]$SiteUrl = '',
        [switch]$SkipScaffold
    )
    $name = ([string]$ProductName).Trim()
    if (-not $name) { throw 'oc: product-name is required so DualRail is this creator face, not a second merit-demo' }
    $cfgDir = Join-Path $TargetRoot 'cfg'
    New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
    $brandingPath = Join-Path $cfgDir 'branding.json'
    $branding = $null
    if (Test-Path -LiteralPath $brandingPath) {
        try { $branding = Read-JsonFile $brandingPath } catch { $branding = $null }
    }
    if (-not $branding) {
        $branding = [pscustomobject]@{ schema = 'merit.branding.v1'; product_name = $name }
    } else {
        $branding.product_name = $name
    }
    Write-JsonFile -Path $brandingPath -Object $branding
    $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList @()
    if (Test-Path -LiteralPath $launch) {
        Set-LaunchIniValue -Path $launch -Name 'product_name' -Value $name
    }
    if (-not $SkipScaffold) {
        $pinsProbePath = Join-Path $Root 'cfg/par_pins.free.json'
        $variant = 'workbench'
        if (Test-Path -LiteralPath $pinsProbePath) {
            try {
                $pinsProbe = Read-JsonFile $pinsProbePath
                if ($pinsProbe.packages.journal) { $variant = 'workbench-journal' }
            } catch { }
        }
        Invoke-ParScaffold -TargetRoot $TargetRoot -Variant $variant -ConsumerId $ConsumerId
    }
    # Play and the marketing site are one creator face, so the hero carries the round trip.
    # Must run before apps publish: play/index.html is uploaded once, early in oc.
    if ($SiteUrl) {
        $playIndex = Join-Path $TargetRoot 'play/index.html'
        if (Test-Path -LiteralPath $playIndex) {
            $playHtml = Get-Content -LiteralPath $playIndex -Raw -Encoding UTF8
            $seePlans = "'<a class=`"ma-cta ma-cta--ghost`" href=`"#plans`">See plans</a>' +"
            if ($playHtml -notmatch 'Marketing site' -and $playHtml.Contains($seePlans)) {
                $siteCta = "'<a class=`"ma-cta ma-cta--ghost`" href=`"$SiteUrl`">Marketing site</a>' +"
                $playHtml = $playHtml.Replace($seePlans, $seePlans + "`r`n                " + $siteCta)
                [System.IO.File]::WriteAllText($playIndex, $playHtml, [System.Text.UTF8Encoding]::new($false))
            }
        }
    }
    $portalJsonPath = Join-Path $TargetRoot 'portal/portal.json'
    if (Test-Path -LiteralPath $portalJsonPath) {
        $pj = Read-JsonFile $portalJsonPath
        if (-not $pj.brand) { $pj | Add-Member -NotePropertyName brand -NotePropertyValue ([pscustomobject]@{}) -Force }
        $pj.brand.name = $name
        # Stock demo copy would read as a second merit-demo; creator-written copy is left alone.
        if (([string]$pj.brand.tagline) -match 'MERIT Demo|hello-world') {
            $pj.brand.tagline = "Play free, join free - $name runs on MERIT cloud."
        }
        if (([string]$pj.brand.description) -match 'MERIT Demo|hello-world') {
            $pj.brand.description = "$name is a DualRail app: an open play surface plus free Community Member signup, hosted by MERIT. No Vercel or here.now account needed to run it."
        }
        if ($PlayUrl) { $pj.appBaseUrl = $PlayUrl }
        if ($pj.ctas) {
            foreach ($cta in @($pj.ctas)) {
                $label = [string]$cta.label
                if ($label -match 'play|workbench|open' -and $PlayUrl) { $cta.href = $PlayUrl }
                elseif ($label -match 'register|join|plus|member' -and $RegisterUrl) {
                    $cta.href = $RegisterUrl
                    # OC is freeware: never advertise Plus/paid checkout on a Community Member face.
                    $cta.label = 'Join free - Community Member $0'
                }
            }
        }
        if ($pj.providers) {
            foreach ($p in @($pj.providers)) {
                $n = [string]$p.name
                $href = [string]$p.href
                if ($n -match 'workbench|play' -and $PlayUrl) { $p.href = $PlayUrl }
                elseif ($n -match 'merit.?subs|register|store' -and $RegisterUrl) { $p.href = $RegisterUrl }
                elseif ($PlayUrl -and $href -match 'merit-demo\.vercel\.app|oc-yardstick01|merit-demo') { $p.href = $PlayUrl }
                if ($ConsumerId -and $p.statusPath) {
                    $p.statusPath = ([string]$p.statusPath).Replace('merit-demo', $ConsumerId)
                }
            }
        }
        if ($PlayUrl -and $RegisterUrl) {
            $pj | Add-Member -NotePropertyName notes -NotePropertyValue @(
                "$name runs on MERIT cloud - no Vercel or here.now account on the creator laptop.",
                'Subscribers join free as Community Member $0; Plus and payouts are not part of OC.',
                'Powered by MERIT.'
            ) -Force
        }
        Write-JsonFile -Path $portalJsonPath -Object $pj
    }
    $portalIndex = Join-Path $TargetRoot 'portal/index.html'
    if ($PlayUrl -and $RegisterUrl -and (Test-Path -LiteralPath $portalIndex)) {
        $idx = Get-Content -LiteralPath $portalIndex -Raw -Encoding UTF8
        if ($idx -notmatch [regex]::Escape($RegisterUrl) -and $idx -notmatch 'Join free') {
            $cta = "      <p class=`"oc-ctas`"><a href=`"$PlayUrl`">Open play</a> ? <a href=`"$RegisterUrl`">Join free - Community Member `$0</a></p>"
            if ($idx.Contains('<div class="actions" id="portal-ctas"></div>')) {
                $idx = $idx.Replace('<div class="actions" id="portal-ctas"></div>', "<div class=`"actions`" id=`"portal-ctas`"></div>`r`n$cta")
                [System.IO.File]::WriteAllText($portalIndex, $idx, [System.Text.UTF8Encoding]::new($false))
            }
        }
    }
}

function Get-OcPortalPublishFiles {
    param([string]$TargetRoot)
    $portalDir = Join-Path $TargetRoot 'portal'
    if (-not (Test-Path -LiteralPath $portalDir)) {
        throw "oc: missing portal/ under $TargetRoot - OC-done publishes the demo portal tree, not stub HTML"
    }
    $rootResolved = (Resolve-Path -LiteralPath $portalDir).Path
    $files = [System.Collections.Generic.List[object]]::new()
    Get-ChildItem -LiteralPath $portalDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($rootResolved.Length).TrimStart('\', '/').Replace('\', '/')
        if ($rel -match '(^|/)\.herenow(/|$)' -or $rel -match '(^|/)\.DS_Store$' -or $rel -match '(^|/)\.merit-keep$') { return }
        if ($rel -notmatch '\.(html?|css|js|mjs|json|svg|txt|md)$') { return }
        $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        if ($null -eq $content) { $content = '' }
        $bytes = [System.Text.Encoding]::UTF8.GetByteCount($content)
        if ($bytes -gt 200000) {
            throw "oc portal: $rel is $bytes bytes (max 200000)"
        }
        $files.Add([ordered]@{
            path = $rel
            content = $content
            contentType = (Get-ContentTypeForHereNow -RelPath $rel)
            bytes = $bytes
        })
    }
    if ($files.Count -lt 1) {
        throw "oc: no portal/ files under $portalDir"
    }
    return $files
}

function Get-OcSiteFiles {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string]$ProductName
    )
    $portalDir = Join-Path $TargetRoot 'portal'
    if (-not (Test-Path -LiteralPath $portalDir)) {
        throw "oc: missing portal/ under $TargetRoot - OC publishes the demo portal tree, not stub HTML"
    }
    $rootResolved = (Resolve-Path -LiteralPath $portalDir).Path
    $base = "/apps/$ConsumerId/play/site/"
    $files = [System.Collections.Generic.List[object]]::new()
    Get-ChildItem -LiteralPath $portalDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($rootResolved.Length).TrimStart('\', '/').Replace('\', '/')
        if ($rel -match '(^|/)\.herenow(/|$)' -or $rel -match '(^|/)\.DS_Store$' -or $rel -match '(^|/)\.merit-keep$') { return }
        if ($rel -notmatch '\.(html?|css|js|mjs|json|svg|txt|md)$') { return }
        $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        if ($null -eq $content) { $content = '' }
        if ($rel -match '\.html?$') {
            # The app host serves /apps/<id>/play/site (no trailing slash), so relative URLs
            # would resolve one level up. <base> fixes assets and portal.json fetch alike.
            if ($content -notmatch '(?i)<base\s') {
                $content = [regex]::Replace($content, '(?i)(<head[^>]*>)', "`$1`r`n  <base href=`"$base`">", 1)
            }
            # Directory links (ama/) 404 on the host rewrite; point straight at index.html.
            $content = [regex]::Replace($content, '(?i)(href=")([A-Za-z0-9._-]+)/(")', '$1$2/index.html$3')
            if ($ProductName) {
                $content = $content.Replace('MERIT Demo Portal', $ProductName).Replace('MERIT Demo', $ProductName)
            }
        }
        $bytes = [System.Text.Encoding]::UTF8.GetByteCount($content)
        if ($bytes -gt 200000) {
            throw "oc site: $rel is $bytes bytes (max 200000)"
        }
        $files.Add([ordered]@{
            path = "play/site/$rel"
            content = $content
            contentType = (Get-ContentTypeForPublish -RelPath $rel)
            bytes = $bytes
        })
    }
    if ($files.Count -lt 1) {
        throw "oc: no portal/ files under $portalDir"
    }
    return $files
}

function Confirm-OcLive {
    param(
        [string]$PlayUrl,
        [string]$RegisterUrl,
        [string]$SiteUrl,
        [string]$ConsumerId,
        [string]$ProductName
    )
    $playHtml = ''
    $siteHtml = ''
    $lastErr = $null
    foreach ($attempt in 1..4) {
        try {
            $playHtml = [string](Invoke-WebRequest -Uri $PlayUrl -UseBasicParsing -TimeoutSec 45).Content
            $siteHtml = [string](Invoke-WebRequest -Uri $SiteUrl -Headers @{ Accept = 'text/html' } -UseBasicParsing -TimeoutSec 45).Content
            $lastErr = $null
            break
        } catch {
            $lastErr = $_
            Start-Sleep -Seconds (2 * $attempt)
        }
    }
    if ($lastErr) {
        throw "OC live-check could not GET play/site. $lastErr"
    }
    if ($playHtml -match 'Play UI not published' -or $playHtml -notmatch 'createAppShell' -or $playHtml -notmatch 'Register free') {
        throw "OC play is not DualRail at $PlayUrl (got the unpublished shell or a non-Gloss face). Re-run oc."
    }
    if ($playHtml -notmatch [regex]::Escape("/store/$ConsumerId/register")) {
        throw "OC play Register CTA is not this tenant ($ConsumerId). Re-run oc so DualRail is not merit-demo."
    }
    if ($siteHtml -match 'Play UI not published' -or $siteHtml -match '"error"\s*:\s*"not_found"' -or $siteHtml.Length -lt 300) {
        throw "OC marketing site missing at $SiteUrl. Publish portal/ as play/site/**."
    }
    Write-Host "OC live-check OK ($ProductName DualRail play + marketing site)."
}

function Invoke-OcSitePublish {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string]$ProductName,
        [string]$Gateway = 'https://merit-prod.vercel.app'
    )
    $files = Get-OcSiteFiles -TargetRoot $TargetRoot -ConsumerId $ConsumerId -ProductName $ProductName
    Write-Host "Packing portal/ -> MERIT-hosted marketing site ($($files.Count) file(s))..."
    [void](Send-AppFileList -Files $files -ConsumerId $ConsumerId -Gateway $Gateway -Label 'oc site publish')
    return "$Gateway/apps/$ConsumerId/play/site"
}

function Invoke-Oc {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string]$ProductName = '',
        [string]$Gateway = 'https://merit-prod.vercel.app'
    )
    $cid = Test-OcConsumerId -ConsumerId $ConsumerId
    $name = ([string]$ProductName).Trim()
    if (-not $name) {
        $brandingPath = Join-Path $TargetRoot 'cfg/branding.json'
        if (Test-Path -LiteralPath $brandingPath) {
            try {
                $b = Read-JsonFile $brandingPath
                if ($b.product_name) { $name = [string]$b.product_name }
            } catch { }
        }
    }
    if (-not $name -or $name -eq 'MERIT Demo') {
        $name = "OC $cid"
    }
    $probePlay = "$Gateway/apps/$cid/play"
    $probeReg = "$Gateway/store/$cid/register"
    $probeSite = "$Gateway/apps/$cid/play/site"
    Set-OcCreatorFace -TargetRoot $TargetRoot -ProductName $name -PlayUrl $probePlay -RegisterUrl $probeReg -ConsumerId $cid -SiteUrl $probeSite
    $appUrl = Invoke-AppsPublish -TargetRoot $TargetRoot -ConsumerId $cid -Gateway $Gateway
    $activateUri = "$Gateway/api/meritstore/v1/tenants/$cid/activate"
    $activateBody = (@{ template = 'free-community'; display_name = $name } | ConvertTo-Json -Compress)
    try {
        $null = Invoke-RestMethod -Uri $activateUri -Method Post -Body $activateBody -ContentType 'application/json' -TimeoutSec 60
    } catch {
        throw "OC activate is required and failed ($activateUri). $_"
    }
    $registerUrl = "$Gateway/store/$cid/register"
    Write-Host "Store activated (free-community): $registerUrl"
    Set-OcCreatorFace -TargetRoot $TargetRoot -ProductName $name -PlayUrl $appUrl -RegisterUrl $registerUrl -SiteUrl $probeSite -SkipScaffold
    $siteUrl = Invoke-OcSitePublish -TargetRoot $TargetRoot -ConsumerId $cid -ProductName $name -Gateway $Gateway
    Write-Host "Marketing portal (MERIT-hosted): $siteUrl"

    # here.now is the optional platform-key upgrade. The laptop never holds the key, so a
    # missing route or unset key is reported as a blocker - never as a fabricated slug URL.
    $hereNow = ''
    $portalGet = $null
    try {
        $portalGet = Invoke-RestMethod -Uri "$Gateway/api/portal/publish" -Method Get -TimeoutSec 30
    } catch {
        $portalGet = $null
    }
    if (-not $portalGet -or -not $portalGet.ok) {
        $hereNow = 'pending-gateway-deploy'
        Write-Host "OC here.now: not available yet (GET $Gateway/api/portal/publish is not live). Marketing portal is MERIT-hosted above."
    } elseif ($portalGet.configured -ne $true) {
        $hereNow = 'blocked-no-platform-key'
        Write-Host 'OC here.now: platform HERENOW_API_KEY is not set on merit-prod (configured:false). Reported, not faked.'
    } else {
        $portalFiles = Get-OcPortalPublishFiles -TargetRoot $TargetRoot
        $fileJsonParts = New-Object System.Collections.Generic.List[string]
        foreach ($f in $portalFiles) {
            $fileJsonParts.Add(
                ('{"path":' + (ConvertTo-JsonEscapedString $f.path) +
                 ',"content":' + (ConvertTo-JsonEscapedString $f.content) +
                 ',"contentType":' + (ConvertTo-JsonEscapedString $f.contentType) + '}')
            )
        }
        $portalPayload = '{"consumerId":' + (ConvertTo-JsonEscapedString $cid) +
            ',"productName":' + (ConvertTo-JsonEscapedString $name) +
            ',"playUrl":' + (ConvertTo-JsonEscapedString $appUrl) +
            ',"registerUrl":' + (ConvertTo-JsonEscapedString $registerUrl) +
            ',"files":[' + ($fileJsonParts -join ',') + ']}'
        $wr = $null
        try {
            $wr = Invoke-WebRequest -Uri "$Gateway/api/portal/publish" -Method Post -Body ([System.Text.Encoding]::UTF8.GetBytes($portalPayload)) -ContentType 'application/json; charset=utf-8' -UseBasicParsing -TimeoutSec 120
        } catch {
            throw "OC here.now publish failed ($Gateway/api/portal/publish). $_"
        }
        $presp = $wr.Content | ConvertFrom-Json
        if (-not $presp.ok -or -not $presp.siteUrl) {
            throw "OC here.now publish rejected: $($wr.Content)"
        }
        if ($presp.stub -eq $true) {
            throw 'OC here.now published stub HTML - send portal/ files (index + css/js/legal), not the stub.'
        }
        $hereNow = [string]$presp.siteUrl
        Write-Host "OC here.now (platform key, laptop never sees it): $hereNow"
    }
    Confirm-OcLive -PlayUrl $appUrl -RegisterUrl $registerUrl -SiteUrl $siteUrl -ConsumerId $cid -ProductName $name
    Write-Host "OC play:     $appUrl"
    Write-Host "OC register: $registerUrl"
    Write-Host "OC portal:   $siteUrl"
    Write-Host "OC product:  $name"
    # Host stream, not Write-Output: callers assign the returned object, which would
    # otherwise capture the receipt line and hide it from the Hub's stdout parse.
    Write-Host ("OC_RECEIPT play={0} register={1} portal={2} herenow={3} product={4}" -f $appUrl, $registerUrl, $siteUrl, $hereNow, $name)
    return [pscustomobject]@{
        consumerId  = $cid
        productName = $name
        playUrl     = $appUrl
        registerUrl = $registerUrl
        portalUrl   = $siteUrl
        hereNowUrl  = $hereNow
    }
}

function Invoke-HereNowDeleteSite {
    param(
        [string]$Slug,
        [string]$BaseUrl = 'https://here.now'
    )
    $apiKey = Get-HereNowApiKey
    if (-not $apiKey) {
        throw 'here.now delete: set HERENOW_API_KEY or ~/.herenow/credentials (BYOK).'
    }
    if (-not $Slug -or $Slug -match '^\{\{') {
        throw "here.now delete: invalid slug '$Slug'"
    }
    $headers = @{
        Authorization = "Bearer $apiKey"
        'x-herenow-client' = 'merit-ps1/apps-remove'
    }
    Write-Host "here.now: DELETE ${BaseUrl}/api/v1/publish/${Slug} ..."
    try {
        Invoke-RestMethod -Uri "${BaseUrl}/api/v1/publish/${Slug}" -Method Delete -Headers $headers -TimeoutSec 60 | Out-Null
    } catch {
        $err = "$_"
        # Idempotent leave: multi-surface cfg/portals.json often lists journal/ama/subs slugs never published.
        if ($err -match '\(404\)|404|Not Found') {
            Write-Host ('here.now: {0} already gone (404) - OK - never published or already deleted' -f $Slug)
            return $null
        }
        throw ('here.now delete failed for {0}: {1}' -f $Slug, $err)
    }
    Write-Host ('here.now deleted: https://{0}.here.now/' -f $Slug)
    return ('https://{0}.here.now/' -f $Slug)
}

function Invoke-AppsRemove {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string[]]$ArgList,
        [string]$Gateway = 'https://merit-prod.vercel.app'
    )
    if (-not (Test-ArgFlag -ArgList $ArgList -Name '--yes')) {
        $playUi = '{0}/apps/{1}/play' -f $Gateway, $ConsumerId
        throw @"
apps remove: refusing without --yes (destructive).
  Platform UI:  $playUi
  Then e.g.:    .\merit.ps1 apps remove --path `"$TargetRoot`" --yes
  Full leave:   .\merit.ps1 apps remove --path `"$TargetRoot`" --yes --tenant-all --with-portal
"@
    }
    $scope = if (Test-ArgFlag -ArgList $ArgList -Name '--tenant-all') { 'tenant_all' } else { 'app_files' }
    $payload = @{
        consumerId = $ConsumerId
        confirm = $ConsumerId
        scope = $scope
    } | ConvertTo-Json -Compress
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    Write-Host ('Removing {0} for consumer_id={1} on {2} ...' -f $scope, $ConsumerId, $Gateway)
    $removeUri = '{0}/api/apps/remove' -f $Gateway
    try {
        $wr = Invoke-WebRequest -Uri $removeUri -Method Post -Body $bodyBytes -ContentType 'application/json; charset=utf-8' -UseBasicParsing -TimeoutSec 60
    } catch {
        throw ('apps remove failed ({0}). {1}' -f $removeUri, $_)
    }
    $parsed = $null
    try { $parsed = $wr.Content | ConvertFrom-Json } catch { }
    if (-not $parsed -or -not $parsed.ok) {
        throw ('apps remove rejected: {0}' -f $wr.Content)
    }
    Write-Host ('apps remove OK: consumer_id={0} scope={1} (was {2})' -f $ConsumerId, $parsed.scope, $parsed.appUrlWas)
    if (Test-ArgFlag -ArgList $ArgList -Name '--with-portal') {
        if (-not $TargetRoot -or -not (Test-Path -LiteralPath $TargetRoot)) {
            throw 'apps remove --with-portal needs --path <repo> (to read cfg/portals.json / .herenow state)'
        }
        $portalsPath = Join-Path $TargetRoot 'cfg/portals.json'
        $slugs = @()
        if (Test-Path -LiteralPath $portalsPath) {
            $portals = Read-JsonFile $portalsPath
            foreach ($s in @($portals.surfaces)) {
                $slug = [string]$s.slug
                $sub = Join-Path $TargetRoot ([string]$s.path)
                $stateFile = Join-Path $sub '.herenow\state.json'
                if (Test-Path -LiteralPath $stateFile) {
                    try {
                        $st = Read-JsonFile $stateFile
                        $live = @($st.publishes.PSObject.Properties.Name) | Select-Object -First 1
                        if ($live) { $slug = [string]$live }
                    } catch { }
                }
                if ($slug -and $slug -notmatch '^\{\{') { $slugs += $slug }
            }
        }
        if ($slugs.Count -lt 1) {
            Write-Host 'apps remove: --with-portal set but no portal slug found (skip here.now delete)'
        } else {
            # Prefer live slug from portal/.herenow/state.json when present; still walk every surface in portals.json.
            foreach ($slug in ($slugs | Select-Object -Unique)) {
                try {
                    Invoke-HereNowDeleteSite -Slug $slug | Out-Null
                } catch {
                    # Platform leave already succeeded above; do not block folder delete / recreate.
                    Write-Warning ('here.now delete skipped for {0}: {1}. Platform apps remove already OK - continue start-over.' -f $slug, $_)
                }
            }
        }
    }
    return $parsed
}

function Write-CreateSuccessCelebration {
    param(
        [string]$TargetRoot,
        [string]$ConsumerId,
        [string]$ProductName,
        [string]$AppUrl,
        [object]$PortalUrls,
        [bool]$OwnHost = $false
    )
    if (-not $OwnHost -and -not $AppUrl) {
        throw 'create: missing cloud app URL after phase 8 (Cloud First Security Centric). Re-run create.'
    }
    $portalLine = $null
    if ($PortalUrls) {
        $first = @($PortalUrls) | Select-Object -First 1
        if ($first -and $first.url) { $portalLine = [string]$first.url }
    }
    $box = '================================================================'
    Write-Host ''
    Write-Host $box -ForegroundColor Green
    Write-Host '  SUCCESS  AutoMagic create finished (all 9 phases)' -ForegroundColor Green
    Write-Host "  Product: $ProductName    consumer_id=$ConsumerId" -ForegroundColor Green
    Write-Host $box -ForegroundColor Green
    Write-Host ''
    Write-Host '  CLAIM: your MERIT shell is LIVE in production (cloud).' -ForegroundColor Green
    Write-Host ''
    if (-not $OwnHost) {
        $linkColor = 'Cyan'
        $noteColor = 'DarkGray'
        $gatewayHost = 'https://merit-prod.vercel.app'
        Write-Host '  === Open these in the browser (production) ===' -ForegroundColor Cyan
        Write-Host '  1) App UI (play)  - open this first (your live app):' -ForegroundColor White
        Write-Host "     $AppUrl" -ForegroundColor $linkColor
        Write-Host '     <== try your app here; a shorter fancy domain can come later' -ForegroundColor $noteColor
        if ($portalLine) {
            Write-Host '  2) Marketing portal  - share this with visitors:' -ForegroundColor White
            Write-Host "     $portalLine" -ForegroundColor $linkColor
            Write-Host '     <== public jumpstart / marketing site for your app' -ForegroundColor $noteColor
        } else {
            Write-Host '  2) Marketing portal  - publish when ready:' -ForegroundColor White
            Write-Host '     local portal/ only - run: .\merit.ps1 portal --path <repo>' -ForegroundColor Yellow
            Write-Host '     <== after portal publish, this becomes your visitor-facing URL' -ForegroundColor $noteColor
        }
        Write-Host '  3) Gateway host  - platform rails (reference only):' -ForegroundColor White
        Write-Host "     $gatewayHost" -ForegroundColor DarkCyan
        Write-Host "     <== not a page to browse; auth/store for $ConsumerId run on this host" -ForegroundColor $noteColor
        Write-Host ''
        Write-Host '  === Validate / celebrate (2 minutes) ===' -ForegroundColor Cyan
        Write-Host '  [ ] Paste link 1 (App UI) into Chrome/Edge/Safari (incognito is fine).'
        Write-Host '  [ ] Confirm the page loads (play shell / workbench chrome) - hard-refresh if blank.'
        Write-Host '  [ ] Confirm the address bar is merit-prod.vercel.app/apps/<id>/play (cloud, not localhost).'
        if ($portalLine) {
            Write-Host '  [ ] Open link 2 (Marketing portal) - jumpstart PRD / app_logic guide should appear.'
        }
        Write-Host '  [ ] Optional: Windows Start -> type the App UI URL, or use Quick open below.'
        Write-Host ''
        Write-Host '  Quick open (PowerShell) - link 1 first:' -ForegroundColor Cyan
        Write-Host "    start `"$AppUrl`"" -ForegroundColor $linkColor
        if ($portalLine) { Write-Host "    start `"$portalLine`"" -ForegroundColor $linkColor }
        Write-Host ''
        Write-Host '  === What success means ===' -ForegroundColor Cyan
        Write-Host '  Phases 1-9 OK. UI is published. Rails are on merit-prod.'
        Write-Host '  Local laptop is not the host - production is link 1 above.'
        Write-Host ''
        Write-Host '  === Next (dinner Steps 3-4) ===' -ForegroundColor Cyan
        Write-Host '  /merit-prd  -> fill docs/PRODUCT.prd.md'
        Write-Host '  /merit-portal -> shape portal/ then: .\merit.ps1 portal --path <repo>'
        Write-Host '  /merit-applogic -> implement Must FRs under app_logic/'
        Write-Host '  Guide: ' -NoNewline
        Write-Host 'https://merit-prod.vercel.app/portal/developers/full-app/' -ForegroundColor $linkColor
        Write-Host '  4) Store register  - members join your app:' -ForegroundColor White
        Write-Host "     https://merit-prod.vercel.app/store/$ConsumerId/register" -ForegroundColor $linkColor
        Write-Host '     <== free-community path; activate re-runs if this 404s' -ForegroundColor $noteColor
        Write-Host '  Optional: push this folder to GitHub to archive the repo.'
        Write-Host '  Advanced later: --deploy --vercel-scope <your-team> (own host).'
        Write-Host '  Auth BYOK (optional): templates/auth/AUTH_ON_PLATFORM.md'
    } else {
        Write-Host '  CLAIM: your app is live on your Vercel host.' -ForegroundColor Green
        Write-Host "  consumer_id=$ConsumerId"
        Write-Host '  Next: shape portal/ then .\merit.ps1 portal --path <repo>'
        Write-Host '  Then /merit-applogic under app_logic/.'
        Write-Host "  Checkout later: https://merit-prod.vercel.app/store/$ConsumerId/register"
    }
    Write-Host ''
    Write-Host $box -ForegroundColor Green
    Write-Host '  Celebrate: you shipped a cloud app URL. Open it. Share it. Build on it.' -ForegroundColor Green
    Write-Host $box -ForegroundColor Green
    Write-Host ''
}

function Write-CreatePhaseGuide {
    param(
        [string]$TargetRoot,
        [int]$FromPhase = 1
    )
    Write-Host 'Create phases -> independent redo commands (run from merit-agent-skills):'
    $lines = @(
        @{ n = 1; text = ".\merit.ps1 init --path `"$TargetRoot`"; .\merit.ps1 apply --path `"$TargetRoot`"" },
        @{ n = 2; text = ".\merit.ps1 par scaffold --path `"$TargetRoot`" --variant workbench-journal" },
        @{ n = 3; text = ".\merit.ps1 branding scaffold --path `"$TargetRoot`"" },
        @{ n = 4; text = ".\merit.ps1 subs scaffold --path `"$TargetRoot`"; .\merit.ps1 community scaffold --path `"$TargetRoot`"" },
        @{ n = 5; text = ".\merit.ps1 admin gate demo-init --path `"$TargetRoot`"" },
        @{ n = 6; text = ".\merit.ps1 verify --path `"$TargetRoot`"" },
        @{ n = 7; text = "re-run create (portal stub is bundled) OR continue to phase 8 if portal/ already exists" },
        @{ n = 8; text = ".\merit.ps1 apps publish --path `"$TargetRoot`"; .\merit.ps1 portal --path `"$TargetRoot`"" },
        @{ n = 9; text = "(success banner - automatic after phase 8 OK; no separate command)" },
        @{ n = 'R'; text = ".\merit.ps1 apps refresh --path `"$TargetRoot`"  # store re-activate + UserGuide + publish; never app_logic/" }
    )
    foreach ($row in $lines) {
        if ($row.n -lt $FromPhase) { continue }
        Write-Host ("  {0}  {1}" -f $row.n, $row.text)
    }
    Write-Host 'See all CLI verbs anytime: .\merit.ps1 help'
}

function Write-CreateRecoveryTips {
    param(
        [string]$TargetRoot,
        [int]$FailedPhase
    )
    $redoByPhase = @{
        1 = ".\merit.ps1 init --path `"$TargetRoot`"; .\merit.ps1 apply --path `"$TargetRoot`""
        2 = ".\merit.ps1 par scaffold --path `"$TargetRoot`" --variant workbench-journal"
        3 = ".\merit.ps1 branding scaffold --path `"$TargetRoot`""
        4 = ".\merit.ps1 subs scaffold --path `"$TargetRoot`"; .\merit.ps1 community scaffold --path `"$TargetRoot`""
        5 = ".\merit.ps1 admin gate demo-init --path `"$TargetRoot`""
        6 = ".\merit.ps1 verify --path `"$TargetRoot`""
        7 = ".\merit.ps1 create --path `"$TargetRoot`" --profile fullstack-consumer   # or skip to phase 8 if portal/ exists"
        8 = ".\merit.ps1 apps publish --path `"$TargetRoot`"; .\merit.ps1 portal --path `"$TargetRoot`""
        9 = ".\merit.ps1 create --path `"$TargetRoot`" --profile fullstack-consumer"
    }
    Write-Host 'Recovery tips:'
    Write-Host "  - Re-run full create (safe/idempotent where prior phases already OK):"
    Write-Host "      .\merit.ps1 create --path `"$TargetRoot`" --profile fullstack-consumer"
    if ($FailedPhase -ge 1 -and $FailedPhase -le 9 -and $redoByPhase.ContainsKey($FailedPhase)) {
        Write-Host "  - Or redo this failed phase alone, then continue through the remaining phases:"
        Write-Host "      $($redoByPhase[$FailedPhase])"
        Write-Host "  - Commands for phase $FailedPhase onward:"
        Write-CreatePhaseGuide -TargetRoot $TargetRoot -FromPhase $FailedPhase
        Write-Host "  - After phase $FailedPhase succeeds, run each later phase command above through phase 8."
    }
    Write-Host '  - Full command list (all verbs + phase map): .\merit.ps1 help'
    Write-Host '  - Dinner guide: https://merit-prod.vercel.app/portal/developers/full-app/'
}

function Invoke-Create {
    param([string]$TargetRoot, [string[]]$ArgList)

    $profile = Get-ArgValue -ArgList $ArgList -Name '--profile'
    if (-not $profile) { $profile = 'fullstack-consumer' }
    if ($profile -ne 'fullstack-consumer') {
        throw "create: unknown --profile '$profile'. Supported: fullstack-consumer"
    }
    # Cloud First Security Centric: create always lands a live cloud URL.
    # Default = merit-prod /apps. --deploy = own-host Vercel (still cloud).
    foreach ($banned in @('--local-only', '--no-publish', '--offline', '--local-deploy')) {
        if (Test-ArgFlag -ArgList $ArgList -Name $banned) {
            throw "create: $banned is banned (Cloud First Security Centric). App UI must publish to merit-prod /apps or your Vercel --deploy. Local scaffold alone is not a deploy."
        }
    }
    $wantDeploy = Test-ArgFlag -ArgList $ArgList -Name '--deploy'
    $scaffoldOnly = -not $wantDeploy
    if (Test-ArgFlag -ArgList $ArgList -Name '--scaffold-only') {
        # Compat alias of platform cloud mode - never skips cloud publish.
        $scaffoldOnly = $true
        $wantDeploy = $false
        Write-Host 'create NOTE: --scaffold-only = platform cloud publish on merit-prod (does not skip cloud).'
    }
    $script:CreateAppUrl = $null
    $theme = Get-ArgValue -ArgList $ArgList -Name '--theme'
    if ($theme -and $theme -notmatch '^gloss-(aurora|graphite|daylight)$') {
        throw "create: --theme must be gloss-aurora, gloss-graphite, or gloss-daylight (got '$theme')"
    }
    if ($theme) { Write-Host "create NOTE: --theme $theme ? DualRail Gloss play shell (par scaffold)." }
    if ($wantDeploy) {
        $scopeCheck = Get-ArgValue -ArgList $ArgList -Name '--vercel-scope'
        if (-not $scopeCheck -and -not $env:VERCEL_SCOPE) {
            throw "create --deploy needs --vercel-scope <your-team> (own Vercel host). For dinner on merit-prod, omit --deploy."
        }
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host " MERIT AutoMagic create  v$MERIT_VERSION"
    Write-Host " profile=$profile"
    Write-Host " path=$TargetRoot"
    if ($wantDeploy) { Write-Host ' mode=deploy (your Vercel host)' } else { Write-Host ' mode=platform (default - live on merit-prod.vercel.app/apps/<app>/)' }
    Write-Host "============================================================"

    $phases = @(
        @{ n = 1; title = 'Repo skeleton and MERIT wiring (init + apply)'; script = {
            Invoke-Init -TargetRoot $TargetRoot -ArgList $ArgList
            Ensure-CreateLaunchDefaults -TargetRoot $TargetRoot -ArgList $ArgList
            Invoke-Apply -TargetRoot $TargetRoot -ArgList $ArgList
        }},
        @{ n = 2; title = 'DualRail Gloss Make Art play (par scaffold)'; script = {
            Invoke-ParScaffold -TargetRoot $TargetRoot -Variant 'workbench-journal' -Theme $theme
        }},
        @{ n = 3; title = 'Starter look (branding scaffold)'; script = {
            Invoke-BrandingScaffold -TargetRoot $TargetRoot
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            Update-Branding -TargetRoot $TargetRoot -Settings (Get-LaunchSettings -Path $launch)
        }},
        @{ n = 4; title = 'Free / Plus subscriber embed + baseline community cfg'; script = {
            Invoke-SubsScaffold -TargetRoot $TargetRoot
            Invoke-BaselineCommunityScaffold -TargetRoot $TargetRoot
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
            $baseSlug = Get-Setting -Settings $settings -Name 'here_now_slug' -Default $cid
            Invoke-PortalScaffold -TargetRoot $TargetRoot -ProductName $pname -ConsumerId $cid -AppUrl "https://merit-prod.vercel.app/apps/$cid/play" -PortalUrl "https://$baseSlug.here.now"
        }},
        @{ n = 8; title = 'Publish UI to merit-prod /apps + baseline here.now portal'; script = {
            if (-not $scaffoldOnly) {
                # Advanced: builder's own Vercel host
                Invoke-Deploy -TargetRoot $TargetRoot -ArgList $ArgList
                return
            }
            # Dinner default: host UI + rails on merit-prod (no builder Vercel).
            $gateway = 'https://merit-prod.vercel.app'
            Write-Host "Platform host for dinner: $gateway"
            try {
                $health = Invoke-RestMethod -Uri "$gateway/api/health" -Method Get -TimeoutSec 20
                Write-Host "merit-prod health OK (status/ok probe)"
                if ($health.ok -eq $false) { Write-Host 'create NOTE: health payload ok=false - continue; re-check later if APIs fail.' }
            } catch {
                throw "merit-prod unreachable at $gateway/api/health. Check network, then re-run create. $_"
            }
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            $settings = Get-LaunchSettings -Path $launch
            $cid = Require-Setting -Settings $settings -Name 'consumer_id'
            Write-Host "Rails wired for consumer_id=$cid (store/auth via $gateway)"
            Write-Host "Register path (after your store is live): $gateway/store/$cid/register"
            Write-Host 'Phase 8 next: publish UI to merit-prod /apps (re-run create is safe if this step hangs).'
            $script:CreateAppUrl = Invoke-AppsPublish -TargetRoot $TargetRoot -ConsumerId $cid -Gateway $gateway
            if (-not $script:CreateAppUrl) {
                throw 'create: cloud publish returned no app URL (Cloud First Security Centric). Fix merit-prod /api/apps/publish, then re-run create.'
            }
            # Self-serve store activate (FR-MPD-04) so /store/<app>/register is live without operator.
            try {
                $activateUri = "$gateway/api/meritstore/v1/tenants/$cid/activate"
                $activateBody = (@{ template = 'free-community'; display_name = $cid } | ConvertTo-Json -Compress)
                $null = Invoke-RestMethod -Uri $activateUri -Method Post -Body $activateBody -ContentType 'application/json' -TimeoutSec 60
                Write-Host "Store activated (free-community): $gateway/store/$cid/register"
            } catch {
                Write-Host "Store activate deferred (re-try POST $gateway/api/meritstore/v1/tenants/$cid/activate): $($_.Exception.Message)"
            }
            # Baseline marketing jumpstart publish (portal/) - required when here.now BYOK is present.
            if (Get-HereNowApiKey) {
                Write-Host 'Phase 8: publishing baseline portal jumpstart to here.now...'
                try {
                    $script:CreatePortalUrls = Invoke-PortalPublish -TargetRoot $TargetRoot -ArgList $ArgList
                } catch {
                    throw "portal publish failed after apps publish OK. Fix here.now/credentials or cfg/portals.json, then: .\merit.ps1 portal --path `"$TargetRoot`". $_"
                }
            } else {
                Write-Host 'here.now: no credentials - portal jumpstart stays in-repo (portal/index.html).'
                Write-Host 'Add HERENOW_API_KEY or ~/.herenow/credentials, then: .\merit.ps1 portal --path <repo>'
            }
        }},
        @{ n = 9; title = 'Success banner'; script = {
            $launch = Get-LaunchPath -TargetRoot $TargetRoot -ArgList $ArgList
            $settings = Get-LaunchSettings -Path $launch
            $cid = Get-Setting -Settings $settings -Name 'consumer_id' -Default (Split-Path -Leaf $TargetRoot)
            $pname = Get-Setting -Settings $settings -Name 'product_name' -Default $cid
            Write-CreateSuccessCelebration -TargetRoot $TargetRoot -ConsumerId $cid -ProductName $pname -AppUrl $script:CreateAppUrl -PortalUrls $script:CreatePortalUrls -OwnHost (-not $scaffoldOnly)
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
            Write-Host "FAILED phase $($phase.n)/9 - $($phase.title)" -ForegroundColor Red
            Write-Host $_.Exception.Message
            Write-Host ""
            Write-CreateRecoveryTips -TargetRoot $TargetRoot -FailedPhase $phase.n
            throw "create stopped at phase $($phase.n)/9"
        }
    }
    Write-Host ""
    Write-Host "create OK: AutoMagic fullstack-consumer finished for $TargetRoot" -ForegroundColor Green
    Write-Host 'Open the SUCCESS box App UI URL above in your browser to validate production.' -ForegroundColor Green
}

$target = Resolve-TargetRoot -ArgList $Rest

switch -Regex ($Command) {
    '^(help|\?)$' { Write-MeritHelp; exit 0 }
    '^version$' { Write-Host "merit $MERIT_VERSION"; exit 0 }
    '^init$' { Invoke-Init -TargetRoot $target -ArgList $Rest; exit 0 }
    '^apply$' { Invoke-Apply -TargetRoot $target -ArgList $Rest; exit 0 }
    '^verify$' {
        if (Test-ArgFlag -ArgList $Rest -Name '--quiet') { $env:MERIT_VERIFY_QUIET = '1' }
        if (-not (Invoke-Verify -TargetRoot $target)) { exit 1 }
        exit 0
    }
    '^e2e$' {
        try { Invoke-ConsumerE2E -TargetRoot $target -Mode 'e2e'; exit 0 }
        catch { Write-Host $_.Exception.Message; exit 1 }
    }
    '^e2e:playwright$' {
        try { Invoke-ConsumerE2E -TargetRoot $target -Mode 'e2e:playwright'; exit 0 }
        catch { Write-Host $_.Exception.Message; exit 1 }
    }
    '^deploy$' { try { Invoke-Deploy -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^vercel$' { try { Invoke-Deploy -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^portal$' { try { Invoke-PortalPublish -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^all$' { try { Invoke-Deploy -TargetRoot $target -ArgList $Rest; Invoke-PortalPublish -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^closeout$' {
        try {
            if (Test-ArgFlag -ArgList $Rest -Name '--validate-only') { Invoke-Closeout -TargetRoot $target } else { Invoke-ReleaseCloseout -TargetRoot $target -ArgList $Rest }
            exit 0
        } catch { Write-Host $_.Exception.Message; exit 1 }
    }
    '^release$' { try { Invoke-ReleaseCloseout -TargetRoot $target -ArgList $Rest; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^law$' { try { Invoke-MeritLaw -ArgList $Rest -RepoRoot $Root; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^vault$' { try { Invoke-MeritVaultCommand -ArgList $Rest -FromRoot $Root; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^skills$' { try { Invoke-MeritSkillsCommand -ArgList $Rest -RepoRoot $Root; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 } }
    '^(where|surface)$' { Invoke-MeritWhere -ArgList $Rest }
    '^apps$' {
        if (-not $Rest -or $Rest.Count -lt 1) { Write-MeritHelp; exit 1 }
        $sub = "$($Rest[0])".ToLowerInvariant()
        try {
            if ($sub -eq 'publish') {
                $cidArg = Get-ArgValue -ArgList $Rest -Name '--consumer-id'
                if (-not $cidArg) { $cidArg = Get-ArgValue -ArgList $Rest -Name '--consumer_id' }
                $cid = $cidArg
                if (-not $cid) {
                    $launch = Get-LaunchPath -TargetRoot $target -ArgList $Rest
                    $settings = Get-LaunchSettings -Path $launch
                    $cid = Require-Setting -Settings $settings -Name 'consumer_id'
                }
                $url = Invoke-AppsPublish -TargetRoot $target -ConsumerId $cid
                Write-Host "apps publish OK: $url"
                exit 0
            }
            if ($sub -eq 'refresh') {
                $launch = Get-LaunchPath -TargetRoot $target -ArgList $Rest
                $settings = Get-LaunchSettings -Path $launch
                $cid = Require-Setting -Settings $settings -Name 'consumer_id'
                Invoke-AppsRefresh -TargetRoot $target -ConsumerId $cid -ArgList $Rest | Out-Null
                exit 0
            }
            if ($sub -eq 'remove') {
                $cidArg = Get-ArgValue -ArgList $Rest -Name '--consumer-id'
                if (-not $cidArg) { $cidArg = Get-ArgValue -ArgList $Rest -Name '--consumer_id' }
                $cid = $cidArg
                $rootForRemove = $null
                $pathArg = Get-ArgValue -ArgList $Rest -Name '--path'
                if ($pathArg) {
                    if (-not (Test-Path -LiteralPath $pathArg)) {
                        throw "apps remove: path not found: $pathArg - after deleting the folder use: .\merit.ps1 apps remove --consumer-id <id> --yes"
                    }
                    $rootForRemove = (Resolve-Path -LiteralPath $pathArg).Path
                    if (-not $cid) {
                        $launch = Get-LaunchPath -TargetRoot $rootForRemove -ArgList $Rest
                        $settings = Get-LaunchSettings -Path $launch
                        $cid = Require-Setting -Settings $settings -Name 'consumer_id'
                    }
                }
                if (-not $cid) {
                    throw 'apps remove: pass --path <repo> (reads consumer_id) or --consumer-id <id>, plus --yes'
                }
                Invoke-AppsRemove -TargetRoot $rootForRemove -ConsumerId $cid -ArgList $Rest | Out-Null
                exit 0
            }
            Write-MeritHelp
            exit 1
        } catch {
            Write-Host $_.Exception.Message
            exit 1
        }
    }
    '^oc$' {
        try {
            $cidArg = Get-ArgValue -ArgList $Rest -Name '--consumer-id'
            if (-not $cidArg) { $cidArg = Get-ArgValue -ArgList $Rest -Name '--consumer_id' }
            if (-not $cidArg) {
                $cidArg = 'oc-' + ([guid]::NewGuid().ToString('n').Substring(0, 10))
            }
            $pnameArg = Get-ArgValue -ArgList $Rest -Name '--product-name'
            if (-not $pnameArg) { $pnameArg = Get-ArgValue -ArgList $Rest -Name '--product_name' }
            $result = Invoke-Oc -TargetRoot $target -ConsumerId $cidArg -ProductName $pnameArg
            Write-Host "oc OK: $($result.playUrl)"
            exit 0
        } catch {
            Write-Host $_.Exception.Message
            exit 1
        }
    }
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
        $parTheme = Get-ArgValue -ArgList $Rest -Name '--theme'
        Invoke-ParScaffold -TargetRoot $target -Variant $variant -Theme $parTheme
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
    '^community$' {
        if (-not $Rest -or $Rest[0] -ne 'scaffold') { Write-MeritHelp; exit 1 }
        Invoke-BaselineCommunityScaffold -TargetRoot $target
        exit 0
    }
    '^(livealpha|baseline)$' {
        Invoke-LiveAlpha -TargetRoot $target -ArgList $Rest
        exit 0
    }
    '^admin$' {
        if ($Rest.Count -ge 2 -and $Rest[0] -eq 'gate' -and $Rest[1] -eq 'demo-init') {
            Invoke-AdminGateDemoInit -TargetRoot $target
            exit 0
        }
        if ($Rest.Count -ge 2 -and $Rest[0] -eq 'ownership' -and $Rest[1] -eq 'status') {
            try { Invoke-AdminOwnershipStatus -TargetRoot $target; exit 0 }
            catch { Write-Host $_.Exception.Message; exit 1 }
        }
        if ($Rest.Count -ge 2 -and $Rest[0] -eq 'ownership' -and $Rest[1] -eq 'repair') {
            try { Invoke-AdminRepairOwnership -TargetRoot $target -ArgList $Rest; exit 0 }
            catch { Write-Host $_.Exception.Message; exit 1 }
        }
        if ($Rest.Count -ge 1 -and $Rest[0] -eq 'repair-ownership') {
            try { Invoke-AdminRepairOwnership -TargetRoot $target -ArgList $Rest; exit 0 }
            catch { Write-Host $_.Exception.Message; exit 1 }
        }
        if ($Rest.Count -ge 3 -and $Rest[0] -eq 'github' -and $Rest[1] -eq 'access') {
            try { Invoke-AdminGithubAccess -ArgList $Rest; exit 0 }
            catch { Write-Host $_.Exception.Message; exit 1 }
        }
        if ($Rest.Count -ge 3 -and $Rest[0] -eq 'github' -and $Rest[1] -eq 'auth') {
            try { Invoke-AdminGithubAuth -ArgList $Rest; exit 0 }
            catch { Write-Host $_.Exception.Message; exit 1 }
        }
        Write-MeritHelp
        exit 1
    }
    '^app$' {
        Write-Host "app scaffold: clone the reference consumer:"
        Write-Host "  git clone https://github.com/Mr-PI-Bala/merit-demo.git <target>"
        exit 0
    }
    default { Write-MeritHelp; exit 1 }
}


