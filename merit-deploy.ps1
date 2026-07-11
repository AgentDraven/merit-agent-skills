# MERIT Deploy CLI — public deploy convenience wrapper.
# Keeps MERIT_DEPLOY.md as the human-edited deploy profile and delegates runtime
# deploys to merit-live.ps1.

param()

$ErrorActionPreference = 'Stop'
$DistRoot = $PSScriptRoot
$Live = Join-Path $DistRoot 'merit-live.ps1'

$Command = if ($args.Count -gt 0) { "$($args[0])".ToLowerInvariant() } else { 'help' }
$Rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

function Write-MeritDeployHelp {
    Write-Host @"
merit-deploy.ps1 — public MERIT deploy wrapper

Usage:
  .\merit-deploy.ps1 <command> [options]

Commands:
  help                         Print this help
  sync --path <repo>           Read MERIT_DEPLOY.md and write cfg/flask_deploy.json + cfg/portals.json
  vercel --path <repo>         Sync profile, then run scoped Vercel production deploy
  portal --path <repo> --all   Sync profile, then publish here.now portal surfaces
  all --path <repo> --all      Sync profile, deploy Vercel, then publish here.now portals

Options:
  --path <repo>                Target consumer repo (default: current directory)
  --profile <file>             Deploy profile markdown (default: MERIT_DEPLOY.md)
  --all                        Publish all here.now surfaces from cfg/portals.json
  --surface <id>               Publish one here.now surface

Human-edited profile:
  MERIT_DEPLOY.md contains two machine-readable JSON blocks:
    MERIT_DEPLOY:vercel
    MERIT_DEPLOY:portals

Vercel note:
  Vercel still requires one-time project linking:
    npx vercel link --scope <your-team-scope>
  That creates .vercel/project.json, which is Vercel-owned and should not be committed.

Credentials:
  Vercel deploy uses your authenticated Vercel CLI session.
  here.now publish requires HERENOW_API_KEY or ~/.herenow/credentials.
  App secrets stay in .env.local or provider dashboards; do not put real secrets in MERIT_DEPLOY.md.
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

function Invoke-MeritLive {
    param([string[]]$LiveArgs)
    & $Live @LiveArgs
}

switch -Regex ($Command) {
    '^(help|\?)$' {
        Write-MeritDeployHelp
        exit 0
    }
    '^sync$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Sync-MeritDeployProfile -Root $target -ArgList $Rest
        exit 0
    }
    '^vercel$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Sync-MeritDeployProfile -Root $target -ArgList $Rest
        Invoke-MeritLive -LiveArgs @('deploy', 'vercel', '--path', $target)
        exit 0
    }
    '^portal$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Sync-MeritDeployProfile -Root $target -ArgList $Rest
        $liveArgs = @('portal', 'publish', '--path', $target)
        if ($Rest -contains '--all') { $liveArgs += '--all' }
        $surface = Get-ArgValue -ArgList $Rest -Name '--surface'
        if ($surface) { $liveArgs += @('--surface', $surface) }
        Invoke-MeritLive -LiveArgs $liveArgs
        exit 0
    }
    '^all$' {
        $target = Resolve-TargetRoot -ArgList $Rest
        Sync-MeritDeployProfile -Root $target -ArgList $Rest
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
