# MERIT Deploy CLI â€” public deploy convenience wrapper.
# Preferred UX: .merit_launch.md is the one local user-edited file.

param()

$ErrorActionPreference = 'Stop'
$DistRoot = $PSScriptRoot
$Live = Join-Path $DistRoot 'merit-live.ps1'

$Command = if ($args.Count -gt 0) { "$($args[0])".ToLowerInvariant() } else { 'help' }
$Rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

function Write-MeritDeployHelp {
    Write-Host @"
merit-deploy.ps1 â€” public MERIT deploy wrapper

Usage:
  .\merit-deploy.ps1 <command> [options]

Commands:
  help                         Print this help
  init --path <repo>           Create .merit_launch.md and add it to .gitignore
  apply --path <repo>          Read .merit_launch.md and write cfg + .env.local
  sync --path <repo>           Read MERIT_DEPLOY.md and write cfg/flask_deploy.json + cfg/portals.json
  vercel --path <repo>         Apply/sync profile, then run scoped Vercel production deploy
  portal --path <repo> --all   Apply/sync profile, then publish here.now portal surfaces
  all --path <repo> --all      Apply/sync profile, deploy Vercel, then publish here.now portals

Options:
  --path <repo>                Target consumer repo (default: current directory)
  --profile <file>             Legacy deploy profile markdown (default: MERIT_DEPLOY.md)
  --launch <file>              Launch file markdown (default: .merit_launch.md)
  --all                        Publish all here.now surfaces from cfg/portals.json
  --surface <id>               Publish one here.now surface

Human-edited file:
  .merit_launch.md is local, gitignored, and may contain secrets.
  It generates .env.local, cfg/flask_deploy.json, and cfg/portals.json.

Vercel note:
  Vercel still requires one-time project linking:
    npx vercel link --scope <your-team-scope>
  That creates .vercel/project.json, which is Vercel-owned and should not be committed.

Credentials:
  Vercel deploy uses your authenticated Vercel CLI session.
  here.now publish requires HERENOW_API_KEY or ~/.herenow/credentials.
  App secrets live in .merit_launch.md locally and are generated into .env.local.
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

function Resolve-TargetRoot {
    param([string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--path'
    if ($p) { return (Resolve-Path $p).Path }
    return (Get-Location).Path
}

function Get-ProfilePath {
    param([string]$Root, [string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--profile'
    if (-not $p) { $p = 'MERIT_DEPLOY.md' }
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $Root $p)
}

function Get-LaunchPath {
    param([string]$Root, [string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--launch'
    if (-not $p) { $p = '.merit_launch.md' }
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $Root $p)
}

function Get-ProfileBlock {
    param([string]$ProfileText, [string]$Name)
    $start = "<!-- MERIT_DEPLOY:$Name -->"
    $end = "<!-- /MERIT_DEPLOY:$Name -->"
    $startIndex = $ProfileText.IndexOf($start)
    $endIndex = $ProfileText.IndexOf($end)
    if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex) {
        throw "MERIT_DEPLOY.md missing MERIT_DEPLOY:$Name JSON block"
    }
    $block = $ProfileText.Substring($startIndex + $start.Length, $endIndex - ($startIndex + $start.Length))
    $fence = [regex]::Match($block, '(?s)```\s*json\s*(.*?)\s*```')
    if (-not $fence.Success) {
        throw "MERIT_DEPLOY.md MERIT_DEPLOY:$Name block must contain a json code fence"
    }
    return $fence.Groups[1].Value
}

function Write-Json {
    param([string]$Path, [object]$Object)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Add-GitIgnoreLine {
    param([string]$Root, [string]$Line)
    $path = Join-Path $Root '.gitignore'
    if (Test-Path $path) {
        $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if ($text -match "(?m)^$([regex]::Escape($Line))$") { return }
        $prefix = if ($text.EndsWith("`n")) { '' } else { "`n" }
        [System.IO.File]::AppendAllText($path, "$prefix$Line`n", [System.Text.UTF8Encoding]::new($false))
    } else {
        [System.IO.File]::WriteAllText($path, "$Line`n", [System.Text.UTF8Encoding]::new($false))
    }
}

function New-Secret {
    param([int]$Bytes = 32)
    $data = [byte[]]::new($Bytes)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($data)
    } finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($data).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Get-LaunchSettings {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Launch file not found: $Path. Run merit init --path <repo> first."
    }
    $settings = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trim = $line.Trim()
        if (-not $trim -or $trim.StartsWith('#') -or $trim.StartsWith('```') -or $trim.StartsWith('<!--')) { continue }
        $m = [regex]::Match($trim, '^([A-Za-z0-9_]+)\s*=\s*(.*)$')
        if ($m.Success) {
            $settings[$m.Groups[1].Value.ToLowerInvariant()] = $m.Groups[2].Value.Trim()
        }
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

function Write-EnvLocal {
    param([string]$Root, [System.Collections.IDictionary]$Settings, [string]$ConsumerId)
    $mountPrefix = Get-Setting -Settings $Settings -Name 'meritsubs_mount_prefix' -Default '/api/meritsubs'
    $baseUrl = Get-Setting -Settings $Settings -Name 'meritsubs_public_base_url' -Default 'https://YOUR_DEPLOY.vercel.app/api/meritsubs'
    $jwt = Get-Setting -Settings $Settings -Name 'meritsubs_jwt_secret'
    if (-not $jwt) { $jwt = New-Secret }
    $api = Get-Setting -Settings $Settings -Name 'meritsubs_api_key'
    if (-not $api) { $api = New-Secret }
    $admin = Get-Setting -Settings $Settings -Name 'meritsubs_admin_key'
    if (-not $admin) { $admin = New-Secret }

    $lines = @(
        '# Generated by merit apply from .merit_launch.md. Do not commit.',
        "SUPABASE_URL=$(Require-Setting -Settings $Settings -Name 'supabase_url')",
        "SUPABASE_ANON_KEY=$(Require-Setting -Settings $Settings -Name 'supabase_anon_key')",
        "SUPABASE_SERVICE_ROLE_KEY=$(Require-Setting -Settings $Settings -Name 'supabase_service_role_key')",
        '',
        "MERIT_CONSUMER_ID=$ConsumerId",
        '',
        "MERITSUBS_MOUNT_PREFIX=$mountPrefix",
        "MERITSUBS_PUBLIC_BASE_URL=$baseUrl",
        "MERITSUBS_PROVIDER_BASE_URL=$(Get-Setting -Settings $Settings -Name 'meritsubs_provider_base_url' -Default 'https://meritstore.vercel.app/api/meritsubs')",
        "MERITSTORE_BASE_URL=$(Get-Setting -Settings $Settings -Name 'meritstore_base_url' -Default 'https://meritstore.vercel.app')",
        "MERIT_DEFAULT_PROMOCODE=$(Get-Setting -Settings $Settings -Name 'default_promocode' -Default 'MERITAGENT')",
        "MERIT_INTRO_CREDIT_USD=$(Get-Setting -Settings $Settings -Name 'intro_credit_usd' -Default '25')",
        "MERITSUBS_JWT_SECRET=$jwt",
        "MERITSUBS_API_KEY=$api",
        "MERITSUBS_ADMIN_KEY=$admin"
    )
    $gate = Get-Setting -Settings $Settings -Name 'operator_gate_hash_slot_1'
    if ($gate) {
        $lines += ''
        $lines += "OPERATOR_GATE_HASH_SLOT_1=$gate"
    }
    $here = Get-Setting -Settings $Settings -Name 'herenow_api_key'
    if ($here) {
        $lines += ''
        $lines += "HERENOW_API_KEY=$here"
    }
    [System.IO.File]::WriteAllText((Join-Path $Root '.env.local'), ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Update-Branding {
    param([string]$Root, [System.Collections.IDictionary]$Settings)
    $path = Join-Path $Root 'cfg/branding.json'
    if (-not (Test-Path $path)) { return }
    $branding = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $product = Get-Setting -Settings $Settings -Name 'product_name'
    $email = Get-Setting -Settings $Settings -Name 'operator_email'
    if ($product) { $branding.product_name = $product }
    if ($email -and ($branding.PSObject.Properties.Name -contains 'operator_email')) { $branding.operator_email = $email }
    Write-Json -Path $path -Object $branding
}

function Apply-LaunchFile {
    param([string]$Root, [string[]]$ArgList)
    $launch = Get-LaunchPath -Root $Root -ArgList $ArgList
    $settings = Get-LaunchSettings -Path $launch
    $consumerId = Require-Setting -Settings $settings -Name 'consumer_id'
    $scope = Require-Setting -Settings $settings -Name 'vercel_scope'
    $branch = Get-Setting -Settings $settings -Name 'production_branch' -Default 'main'
    $baseSlug = Get-Setting -Settings $settings -Name 'here_now_slug' -Default $consumerId

    $vercel = [ordered]@{
        project_id        = $consumerId
        vercel_scope      = $scope
        production_branch = $branch
        notes             = "Run npx vercel link --scope $scope once. Vercel creates .vercel/project.json."
    }
    $portals = [ordered]@{
        schema   = 'merit.portals.v1'
        surfaces = @(
            [ordered]@{ id = 'main'; path = 'portal/'; slug = (Get-Setting -Settings $settings -Name 'portal_main_slug' -Default $baseSlug) },
            [ordered]@{ id = 'journal'; path = 'portal/journal/'; slug = (Get-Setting -Settings $settings -Name 'portal_journal_slug' -Default "$baseSlug-journal") },
            [ordered]@{ id = 'ama'; path = 'portal/ama/'; slug = (Get-Setting -Settings $settings -Name 'portal_ama_slug' -Default "$baseSlug-ama") },
            [ordered]@{ id = 'subs'; path = 'portal/subs/'; slug = (Get-Setting -Settings $settings -Name 'portal_subs_slug' -Default "$baseSlug-subs") }
        )
        notes    = 'Generated by merit apply from .merit_launch.md.'
    }

    Write-Json -Path (Join-Path $Root 'cfg/flask_deploy.json') -Object $vercel
    Write-Json -Path (Join-Path $Root 'cfg/portals.json') -Object $portals
    Write-EnvLocal -Root $Root -Settings $settings -ConsumerId $consumerId
    Update-Branding -Root $Root -Settings $settings
    Add-GitIgnoreLine -Root $Root -Line '.merit_launch.md'
    Add-GitIgnoreLine -Root $Root -Line '.env.local'
    Add-GitIgnoreLine -Root $Root -Line '.vercel'

    $here = Get-Setting -Settings $settings -Name 'herenow_api_key'
    if ($here) { $env:HERENOW_API_KEY = $here }

    Write-Host "apply OK: .merit_launch.md -> .env.local, cfg/flask_deploy.json, cfg/portals.json"
    if (-not (Test-Path (Join-Path $Root '.vercel/project.json'))) {
        Write-Host "vercel link needed: npx vercel link --scope $scope"
    }
}

function Init-LaunchFile {
    param([string]$Root, [string[]]$ArgList)
    $launch = Get-LaunchPath -Root $Root -ArgList $ArgList
    $template = Join-Path $DistRoot 'templates/.merit_launch.md'
    if (-not (Test-Path $template)) { throw "missing template: $template" }
    if (Test-Path $launch) {
        Write-Host "init skipped (exists): $launch"
    } else {
        Copy-Item -LiteralPath $template -Destination $launch
        Write-Host "init OK: created $launch"
    }
    Add-GitIgnoreLine -Root $Root -Line '.merit_launch.md'
    Add-GitIgnoreLine -Root $Root -Line '.env.local'
    Add-GitIgnoreLine -Root $Root -Line '.vercel'
}

function Sync-MeritDeployProfile {
    param([string]$Root, [string[]]$ArgList)
    $profile = Get-ProfilePath -Root $Root -ArgList $ArgList
    if (-not (Test-Path $profile)) {
        throw "Deploy profile not found: $profile"
    }

    $text = Get-Content -LiteralPath $profile -Raw -Encoding UTF8
    $vercel = Get-ProfileBlock -ProfileText $text -Name 'vercel' | ConvertFrom-Json
    $portals = Get-ProfileBlock -ProfileText $text -Name 'portals' | ConvertFrom-Json

    Write-Json -Path (Join-Path $Root 'cfg/flask_deploy.json') -Object $vercel
    Write-Json -Path (Join-Path $Root 'cfg/portals.json') -Object $portals

    Write-Host "sync OK: MERIT_DEPLOY.md -> cfg/flask_deploy.json, cfg/portals.json"
    if (-not (Test-Path (Join-Path $Root '.vercel/project.json'))) {
        Write-Host "vercel link needed: npx vercel link --scope $($vercel.vercel_scope)"
    }
}

function Apply-Or-Sync {
    param([string]$Root, [string[]]$ArgList)
    $launch = Get-LaunchPath -Root $Root -ArgList $ArgList
    if (Test-Path $launch) {
        Apply-LaunchFile -Root $Root -ArgList $ArgList
    } else {
        Sync-MeritDeployProfile -Root $Root -ArgList $ArgList
    }
}

function Invoke-MeritLive {
    param([string[]]$LiveArgs)
    & $Live @LiveArgs
}

switch -Regex ($Command) {
    '^(help|\?)$' {
        Write-MeritDeployHelp
        exit 0
    }
    '^init$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Init-LaunchFile -Root $target -ArgList $Rest
        exit 0
    }
    '^apply$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Apply-LaunchFile -Root $target -ArgList $Rest
        exit 0
    }
    '^sync$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Apply-Or-Sync -Root $target -ArgList $Rest
        exit 0
    }
    '^vercel$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Apply-Or-Sync -Root $target -ArgList $Rest
        Invoke-MeritLive -LiveArgs @('deploy', 'vercel', '--path', $target)
        exit 0
    }
    '^portal$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Apply-Or-Sync -Root $target -ArgList $Rest
        $liveArgs = @('portal', 'publish', '--path', $target)
        if ($Rest -contains '--all') { $liveArgs += '--all' }
        $surface = Get-ArgValue -ArgList $Rest -Name '--surface'
        if ($surface) { $liveArgs += @('--surface', $surface) }
        Invoke-MeritLive -LiveArgs $liveArgs
        exit 0
    }
    '^all$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Apply-Or-Sync -Root $target -ArgList $Rest
        Invoke-MeritLive -LiveArgs @('deploy', 'vercel', '--path', $target)
        $liveArgs = @('portal', 'publish', '--path', $target)
        if ($Rest -contains '--all') { $liveArgs += '--all' }
        $surface = Get-ArgValue -ArgList $Rest -Name '--surface'
        if ($surface) { $liveArgs += @('--surface', $surface) }
        Invoke-MeritLive -LiveArgs $liveArgs
        exit 0
    }
    default {
        Write-MeritDeployHelp
        exit 1
    }
}
