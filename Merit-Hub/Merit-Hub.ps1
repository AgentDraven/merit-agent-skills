#Requires -Version 5.1
<#
.SYNOPSIS
  Merit-Hub - laptop cleanup (Pristine v2), jumpstart OSS/vault, shared tools (MYMERITTOOLS).

.DESCRIPTION
  Standalone script - save as e.g. C:\Tools\Merit-Hub.ps1 (default %MYMERITTOOLS%).
  REQUIRED after download (do not double-click or .\\Merit-Hub.ps1; OS blocks internet scripts):
    pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
  Pins are embedded; no .json or extra launcher required. Run with no args for interactive menu.

  Cleanup:
    -Pristine   backup + full cold-start wipe (~/dev folder, OSS bench, MERIT tools artifacts, env)
    -Soft       backup + wipe bench/status; keep ~/dev clones
    -BackupOnly snapshot only

    Jumpstart:
    -Jumpstart Oss|Vault   clone pinned release; OSS continues as Install OSS (step 2)
    -OssPhase / -InstallOss  clone demo + quiet validate (after a skills clone exists)
    -TryIt                 open local merit-demo play
    -Oc                    OSS in the Cloud (publish + required activate)
    -NewOc                 with -Oc: mint a new oc-* id (do not reuse oss-bench.json)
    -Vc                    Venture Capable (operator grade after local V; not hosted vault)
    -R                     Catalog repo clone (local). Role = consumer|provider
    -Rc                    That catalog repo's production host (usually Vercel; not OC)
    -Role consumer|provider  with -R / -Rc
    -CatalogProject <id>   catalog id (e.g. m4fi). Default consumer pick: m4fi
    -JoinMerit             portal / partners / register links (Hub 6)
    -InstallSkills <host>  copy skills/ to Cursor, Codex, Hermes, ... (needs OSS clone; menu I)
    -Prereqs                 install/check git, gh, pwsh, MYMERITTOOLS Python venv

  Recommended runner: PowerShell 7+ (pwsh). If Windows PowerShell 5.1 starts this file, it prints the pwsh command and re-launches when pwsh is found (menu 1 can install pwsh).

  Env (mirrors BootStrap):
    MYMERITAPP    OSS bench (default C:\MyMeritApp)
    MYMERITTOOLS  laptop tools root (default C:\Tools) - merit-venv, shims
    MERIT_HUB_NO_PERSIST_ENV=1  Process-only MYMERIT* (multi-creator benches; do not SET User)

.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\Merit-Hub.ps1 -Pristine -Force
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\Merit-Hub.ps1 -Jumpstart Oss
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Pristine,
    [switch]$Soft,
    [switch]$BackupOnly,
    [ValidateSet('Oss', 'Vault')]
    [string]$Jumpstart,
    [ValidateSet('Cursor', 'ClaudeCode', 'Claude', 'Codex', 'VSCode', 'Agents', 'Hermes', 'OpenClaw', 'GrokBot', 'Grok', 'Devin', 'Project')]
    [string]$InstallSkills,
    [string]$InstallSkillsPath = '',
    [switch]$Prereqs,
    [switch]$OssPhase,
    [switch]$InstallOss,
    [switch]$TryIt,
    [switch]$Oc,
    [switch]$NewOc,
    [switch]$Vc,
    [switch]$R,
    [switch]$Rc,
    [ValidateSet('consumer', 'provider')]
    [string]$Role = '',
    [string]$CatalogProject = '',
    [switch]$JoinMerit,
    [switch]$Surface,
    [switch]$Force,
    [Alias('?')]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:HubScriptPath = $PSCommandPath
if (-not $Script:HubScriptPath) { $Script:HubScriptPath = $MyInvocation.MyCommand.Path }
$Script:HubRoot = Split-Path -Parent $Script:HubScriptPath
$Script:HubBoundParameters = [hashtable]$PSBoundParameters
$Script:BackupRoot = Join-Path $Script:HubRoot 'backups'
$Script:HistoryLog = Join-Path $Script:BackupRoot 'Merit-Hub-history.log'
$Script:TranscriptStarted = $false
$Script:HubStepFailed = $false
$Script:HubOnWindows = (
    ($PSVersionTable.ContainsKey('PSPlatform') -and $PSVersionTable.PSPlatform -eq 'Win32NT') -or
    ($env:OS -match 'Windows')
)
# After a Bypass -File start, drop Mark of the Web so later local edits are not treated as remote.
if ($Script:HubOnWindows -and $Script:HubScriptPath) {
    try { Unblock-File -LiteralPath $Script:HubScriptPath -ErrorAction SilentlyContinue } catch { }
}

# Embedded release pins (no separate Merit-Hub.json required).
$Script:EmbeddedHubConfigJson = @'
{
  "schemaVersion": 1,
  "skillsPin": "skills-v0.5.44",
  "vaultPin": "vault-v0.5.50",
  "agentCloseoutRequired": true,
  "agentCloseout": "OSS: merit.ps1 closeout + ship (skills-v*) + chat 3-3. Operator when vault on disk: vault scripts/merit.ps1 mXin + git verify. Exception: WIP / no commit / local-only.",
  "skillsUrl": "https://github.com/AgentDraven/merit-agent-skills.git",
  "vaultUrl": "https://github.com/AgentDraven/merit-private-vault.git",
  "vaultOwner": "AgentDraven",
  "vaultRepo": "merit-private-vault",
  "showcaseUrl": "https://github.com/Mr-PI-Bala/merit-demo.git",
  "defaultMyMeritAppWindows": "C:\\MyMeritApp",
  "defaultMyMeritAppUnix": "~/MyMeritApp",
  "defaultMyMeritToolsWindows": "C:\\Tools",
  "defaultMyMeritToolsUnix": "~/Tools",
  "devSubdir": "dev",
  "pwshPortableVersion": "7.5.2",
  "rogueProfileNames": ["HumanBala", "DravenCode.OLD", "Code", "AgentDraven", "Mr-PI-Bala"],
  "rogueProfileGlobs": ["*Merit*", "DravenCode*"],
  "rogueDriveRootNames": ["HumanBala", "MyMeritApp", "AgentDraven", "DravenCode.OLD"]
}
'@

function Get-HubRunHint {
    return "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$($Script:HubScriptPath)`""
}

function Write-Ok([string]$t) { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Write-Fail([string]$t) { Write-Host "  [FAIL] $t" -ForegroundColor Red }
function Write-Warn([string]$t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
function Write-Note([string]$t) { Write-Host "  NOTE:  $t" -ForegroundColor DarkYellow }
function Write-Info([string]$t) { Write-Host "  $t" }
function Write-Header([string]$t) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  Merit-Hub  |  $t" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
}

function Get-HubConfig {
    return ($Script:EmbeddedHubConfigJson | ConvertFrom-Json)
}

function Import-HubMeritResolve {
    if (Get-Command Get-MeritSurface -ErrorAction SilentlyContinue) { return $true }
    $candidates = [System.Collections.Generic.List[string]]::new()
    $benchSkills = Join-Path (Get-MyMeritAppRoot) 'merit-agent-skills\BootStrap\_resolve.ps1'
    [void]$candidates.Add($benchSkills)
    if ($env:MERIT_SKILLS_ROOT) {
        [void]$candidates.Add((Join-Path $env:MERIT_SKILLS_ROOT 'BootStrap\_resolve.ps1'))
    }
    foreach ($bench in @(Get-AllKnownMeritEnvPaths -Name 'MYMERITAPP')) {
        [void]$candidates.Add((Join-Path $bench 'merit-agent-skills\BootStrap\_resolve.ps1'))
    }
    foreach ($path in @('C:\DevApps\merit-agent-skills', 'C:\MyMeritApp\merit-agent-skills')) {
        [void]$candidates.Add((Join-Path $path 'BootStrap\_resolve.ps1'))
    }
    foreach ($resolve in $candidates) {
        if (-not (Test-Path -LiteralPath $resolve)) { continue }
        try {
            $Script:MeritResolveRepoRoot = Split-Path -Parent (Split-Path -Parent $resolve)
            $Script:MeritResolveHubScript = $Script:HubScriptPath
            $cfg = Get-HubConfig
            $Script:MeritResolveHubPin = [string]$cfg.skillsPin
            . $resolve
            return $true
        }
        catch { }
    }
    Initialize-HubMeritSurfaceEmbed
    return [bool](Get-Command Get-MeritSurface -ErrorAction SilentlyContinue)
}

function Initialize-HubMeritSurfaceEmbed {
    if (Get-Command Get-MeritSurface -ErrorAction SilentlyContinue) { return }
    function script:Expand-HubMeritPath {
        param([string]$Path)
        if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
        $p = $Path.Trim()
        if ($p -match '^%([A-Za-z_][A-Za-z0-9_]*)%\\?(.*)$') {
            $val = [Environment]::GetEnvironmentVariable($Matches[1], 'Process')
            if ([string]::IsNullOrWhiteSpace($val)) { $val = [Environment]::GetEnvironmentVariable($Matches[1], 'User') }
            if ([string]::IsNullOrWhiteSpace($val)) { $val = [Environment]::GetEnvironmentVariable($Matches[1], 'Machine') }
            if ([string]::IsNullOrWhiteSpace($val)) { return $null }
            $p = if ($Matches[2]) { Join-Path $val $Matches[2] } else { $val }
        }
        if ($p.StartsWith('~/') -or $p -eq '~') {
            $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
            if (-not $homeRoot) { return $null }
            $p = Join-Path $homeRoot ($p.TrimStart([char[]]@('~', '/', '\')))
        }
        try { return [IO.Path]::GetFullPath($p) } catch { return $null }
    }
    function script:Test-HubSkillsRoot {
        param([string]$Path)
        $full = Expand-HubMeritPath $Path
        if (-not $full) { return $false }
        return ((Test-Path -LiteralPath (Join-Path $full 'merit.ps1')) -and (Test-Path -LiteralPath (Join-Path $full 'skills')))
    }
    function script:Test-HubVaultRoot {
        param([string]$Path)
        $full = Expand-HubMeritPath $Path
        if (-not $full) { return $false }
        return (Test-Path -LiteralPath (Join-Path $full 'scripts\merit.ps1'))
    }
    function Get-MeritSurface {
        param([switch]$NoWrite, [string]$HubPin = '', [string]$HubScript = '')
        if ($HubScript) { $Script:MeritResolveHubScript = $HubScript }
        $skillsSearch = [System.Collections.Generic.List[string]]::new()
        if ($env:MERIT_SKILLS_ROOT) { [void]$skillsSearch.Add($env:MERIT_SKILLS_ROOT) }
        foreach ($scope in @('Process', 'User', 'Machine')) {
            $app = [Environment]::GetEnvironmentVariable('MYMERITAPP', $scope)
            if ($app) { [void]$skillsSearch.Add((Join-Path $app 'merit-agent-skills')) }
        }
        foreach ($p in @('C:\DevApps\merit-agent-skills', 'C:\MyMeritApp\merit-agent-skills')) { [void]$skillsSearch.Add($p) }
        $benchJson = $null
        foreach ($scope in @('Process', 'User', 'Machine')) {
            $app = [Environment]::GetEnvironmentVariable('MYMERITAPP', $scope)
            if (-not $app) { continue }
            $bj = Join-Path $app 'oss-bench.json'
            if (Test-Path -LiteralPath $bj) {
                $benchJson = $bj
                try {
                    $raw = Get-Content -LiteralPath $bj -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($raw.skillsFolder) { [void]$skillsSearch.Add([string]$raw.skillsFolder) }
                }
                catch { }
                break
            }
        }
        $skillsRoot = $null
        foreach ($c in $skillsSearch) {
            if (Test-HubSkillsRoot $c) { $skillsRoot = Expand-HubMeritPath $c; break }
        }
        $vaultSearch = [System.Collections.Generic.List[string]]::new()
        if ($env:MERIT_VAULT_ROOT) { [void]$vaultSearch.Add($env:MERIT_VAULT_ROOT) }
        $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        if ($homeRoot) { [void]$vaultSearch.Add((Join-Path (Join-Path (Join-Path $homeRoot 'dev') 'AgentDraven') 'merit-private-vault')) }
        $vaultRoot = $null
        foreach ($c in $vaultSearch) {
            if (Test-HubVaultRoot $c) { $vaultRoot = Expand-HubMeritPath $c; break }
        }
        $ideHosts = [System.Collections.Generic.List[string]]::new()
        $staleIdeMarker = $false
        $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        foreach ($pair in @(
                @{ id = 'cursor'; dest = (Join-Path $homeRoot '.cursor\skills') },
                @{ id = 'claude'; dest = (Join-Path $homeRoot '.claude\skills') },
                @{ id = 'codex'; dest = (Join-Path (if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeRoot '.codex' }) 'skills') },
                @{ id = 'vscode'; dest = (Join-Path $homeRoot '.agents\skills') }
            )) {
            if (-not (Test-Path -LiteralPath $pair.dest)) { continue }
            $meritDirs = @(Get-ChildItem -LiteralPath $pair.dest -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'merit-*' })
            if ($meritDirs.Count -lt 1) { continue }
            [void]$ideHosts.Add($pair.id)
            $marker = Join-Path $pair.dest '.merit-surface.json'
            if (Test-Path -LiteralPath $marker) {
                try {
                    $m = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($m.skillsRepoRoot -and -not (Test-HubSkillsRoot ([string]$m.skillsRepoRoot))) { $staleIdeMarker = $true }
                }
                catch { }
            }
        }
        $hasA = ($ideHosts.Count -gt 0)
        $hasB = [bool]$skillsRoot
        $hasC = [bool]$vaultRoot
        $edition = 'none'
        if ($hasA -and $hasB -and $hasC) { $edition = 'full' }
        elseif ($hasB -and $hasC) { $edition = 'oss+vault' }
        elseif ($hasA -and $hasC) { $edition = 'vault+ide' }
        elseif ($hasA -and $hasB) { $edition = 'oss+ide' }
        elseif ($hasB) { $edition = 'oss' }
        elseif ($hasA) { $edition = 'ide-only' }
        elseif ($hasC) { $edition = 'vault-only' }
        $demoFolder = $null
        if ($skillsRoot) {
            foreach ($scope in @('Process', 'User', 'Machine')) {
                $app = [Environment]::GetEnvironmentVariable('MYMERITAPP', $scope)
                if ($app) { $demoFolder = Join-Path $app 'merit-demo'; break }
            }
        }
        $hubScript = if ($Script:MeritResolveHubScript) { $Script:MeritResolveHubScript } else { $null }
        if (-not $hubScript) {
            foreach ($scope in @('Process', 'User', 'Machine')) {
                $tools = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', $scope)
                if ($tools) {
                    $cand = Join-Path $tools 'Merit-Hub.ps1'
                    if (Test-Path -LiteralPath $cand) { $hubScript = $cand; break }
                }
            }
        }
        $skillsVersion = ''
        if ($skillsRoot) {
            $verFile = Join-Path $skillsRoot 'VERSION'
            if (Test-Path -LiteralPath $verFile) {
                $skillsVersion = ((Get-Content -LiteralPath $verFile -Raw) -split '\r?\n')[0].Trim()
            }
        }
        $hubPinVal = if ($HubPin) { $HubPin } elseif ($Script:MeritResolveHubPin) { $Script:MeritResolveHubPin } else { '' }
        $pinMismatch = $false
        if ($hubPinVal -and $skillsVersion -and ($hubPinVal -ne "skills-v$skillsVersion")) { $pinMismatch = $true }
        $hints = [System.Collections.Generic.List[string]]::new()
        switch ($edition) {
            'none' { [void]$hints.Add('Download Merit-Hub.ps1 Raw to %MYMERITTOOLS%'); [void]$hints.Add('Run Hub 1 then 2') }
            'ide-only' {
                [void]$hints.Add('Hub 2 clones merit-agent-skills to %MYMERITAPP%')
                if ($staleIdeMarker) { [void]$hints.Add('IDE .merit-surface.json is stale — re-run Hub 2 after Pristine') }
            }
            default { [void]$hints.Add('Run Hub 2 when B missing; merit.ps1 where when B present') }
        }
        return [pscustomobject]@{
            edition          = $edition
            skillsRepoRoot   = $skillsRoot
            publicMeritCli   = if ($skillsRoot) { Join-Path $skillsRoot 'merit.ps1' } else { $null }
            demoFolder       = $demoFolder
            vaultRoot        = $vaultRoot
            operatorMeritCli = if ($vaultRoot) { Join-Path $vaultRoot 'scripts\merit.ps1' } else { $null }
            hubScript        = $hubScript
            ossBenchJson     = $benchJson
            ideHosts         = @($ideHosts)
            staleIdeMarker   = $staleIdeMarker
            hubPin           = $hubPinVal
            skillsVersion    = $skillsVersion
            pinMismatch      = $pinMismatch
            resolvedFrom     = @{ skills = 'hub-embed'; vault = 'hub-embed' }
            recoveryHints    = @($hints)
        }
    }
    function Write-MeritSurfaceReport {
        param($Surface, [switch]$AsJson)
        if ($AsJson) { $Surface | ConvertTo-Json -Depth 5; return }
        Write-Host ''
        Write-Host '  MERIT SURFACE (Hub embed — run Hub 2 for full resolver)' -ForegroundColor Cyan
        Write-Host ('  edition:       {0}' -f $Surface.edition)
        Write-Host ('  A IDE skills:  {0}' -f $(if ($Surface.ideHosts.Count) { $Surface.ideHosts -join ', ' } else { '(none)' }))
        Write-Host ('  B OSS bench:   {0}' -f $(if ($Surface.skillsRepoRoot) { $Surface.skillsRepoRoot } else { '(missing)' }))
        Write-Host ('  C vault:       {0}' -f $(if ($Surface.vaultRoot) { $Surface.vaultRoot } else { '(missing)' }))
        Write-Host ('  D merit-demo:  {0}' -f $(if ($Surface.demoFolder -and (Test-Path -LiteralPath $Surface.demoFolder)) { $Surface.demoFolder } else { '(missing)' }))
        Write-Host ('  H Hub:         {0}' -f $(if ($Surface.hubScript) { $Surface.hubScript } else { '(missing)' }))
        if ($Surface.publicMeritCli) {
            Write-Host ('  merit.ps1:     {0}' -f $Surface.publicMeritCli) -ForegroundColor Green
            Write-Host ('  run:           pwsh -NoProfile -File "{0}" where' -f $Surface.publicMeritCli) -ForegroundColor DarkGray
        }
        if ($Surface.pinMismatch) {
            Write-Host ('  WARN pin:      Hub {0} != B VERSION {1}' -f $Surface.hubPin, $Surface.skillsVersion) -ForegroundColor Yellow
        }
        if ($Surface.staleIdeMarker) {
            Write-Host '  WARN:          stale IDE .merit-surface.json (B path gone) — Hub 2 to re-clone' -ForegroundColor Yellow
        }
        if ($Surface.recoveryHints.Count -gt 0) {
            Write-Host '  recovery:' -ForegroundColor DarkYellow
            foreach ($h in $Surface.recoveryHints) { Write-Host "    - $h" }
        }
        Write-Host ''
    }
}

function Write-MeritSurfaceReceipt {
    [void](Import-HubMeritResolve)
    if (-not (Get-Command Get-MeritSurface -ErrorAction SilentlyContinue)) {
        Write-Warn 'Merit Surface resolver unavailable.'
        return
    }
    $cfg = Get-HubConfig
    $surf = Get-MeritSurface -HubPin ([string]$cfg.skillsPin) -HubScript $Script:HubScriptPath
    if (Get-Command Write-MeritSurfaceReport -ErrorAction SilentlyContinue) {
        Write-MeritSurfaceReport -Surface $surf
    }
}

function Invoke-HubSurface {
    Write-Header 'Merit Surface (W)'
    Write-MeritSurfaceReceipt
}

function Test-HubDemoReady {
    $demo = Join-Path (Get-MyMeritAppRoot) 'merit-demo'
    $play = Join-Path $demo 'play\index.html'
    if (Test-Path -LiteralPath $play) { return $true }
    $state = $null
    if (Get-Command Get-OssState -ErrorAction SilentlyContinue) { $state = Get-OssState }
    if ($state -and $state.demoFolder) {
        $play = Join-Path ([string]$state.demoFolder) 'play\index.html'
        return (Test-Path -LiteralPath $play)
    }
    return $false
}

function Expand-HomePath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $Path }
    $p = $Path.Trim()
    if ($p.StartsWith('~/') -or $p -eq '~') {
        $p = Join-Path $HOME ($p.TrimStart('~', '/\'))
    }
    return [IO.Path]::GetFullPath($p)
}

function Get-DefaultMyMeritTools {
    $cfg = Get-HubConfig
    if ($Script:HubOnWindows) {
        return Expand-HomePath ([string]$cfg.defaultMyMeritToolsWindows)
    }
    return Expand-HomePath ([string]$cfg.defaultMyMeritToolsUnix)
}

function Get-DefaultMyMeritApp {
    $cfg = Get-HubConfig
    if ($Script:HubOnWindows) {
        return Expand-HomePath ([string]$cfg.defaultMyMeritAppWindows)
    }
    return Expand-HomePath ([string]$cfg.defaultMyMeritAppUnix)
}

function Get-MyMeritToolsRoot {
    foreach ($scope in @('Process', 'User', 'Machine')) {
        $v = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', $scope)
        if (-not [string]::IsNullOrWhiteSpace($v)) {
            return Expand-HomePath $v
        }
    }
    return Get-DefaultMyMeritTools
}

function Get-MyMeritAppRoot {
    foreach ($scope in @('Process', 'User', 'Machine')) {
        $v = [Environment]::GetEnvironmentVariable('MYMERITAPP', $scope)
        if (-not [string]::IsNullOrWhiteSpace($v)) {
            return Expand-HomePath $v
        }
    }
    return Get-DefaultMyMeritApp
}

function Get-DevRoot {
    $cfg = Get-HubConfig
    $sub = if ($cfg.devSubdir) { [string]$cfg.devSubdir } else { 'dev' }
    return Expand-HomePath (Join-Path $HOME $sub)
}

function Add-HubKnownPath {
    param(
        [System.Collections.Generic.HashSet[string]]$Seen,
        [string]$Path
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    try {
        $full = Expand-HomePath $Path
        [void]$Seen.Add($full)
    }
    catch { }
}

function Get-AllKnownMeritEnvPaths {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('MYMERITAPP', 'MYMERITTOOLS')]
        [string]$Name,
        [string]$BackupDir = ''
    )
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($scope in @('Process', 'User', 'Machine')) {
        Add-HubKnownPath -Seen $seen -Path ([Environment]::GetEnvironmentVariable($Name, $scope))
    }
    if ($Name -eq 'MYMERITAPP') {
        Add-HubKnownPath -Seen $seen -Path (Get-DefaultMyMeritApp)
    }
    else {
        Add-HubKnownPath -Seen $seen -Path (Get-DefaultMyMeritTools)
    }
    $snapDirs = New-Object System.Collections.Generic.List[string]
    if ($BackupDir) { [void]$snapDirs.Add($BackupDir) }
    if ($Script:BackupRoot -and (Test-Path -LiteralPath $Script:BackupRoot)) {
        Get-ChildItem -LiteralPath $Script:BackupRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 5 |
            ForEach-Object { [void]$snapDirs.Add($_.FullName) }
    }
    foreach ($dir in $snapDirs) {
        $snap = Join-Path $dir 'env-snapshot.json'
        if (-not (Test-Path -LiteralPath $snap)) { continue }
        try {
            $meta = Get-Content -LiteralPath $snap -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($Name -eq 'MYMERITAPP') {
                Add-HubKnownPath -Seen $seen -Path ([string]$meta.ossBench)
                Add-HubKnownPath -Seen $seen -Path ([string]$meta.myMeritAppUser)
                Add-HubKnownPath -Seen $seen -Path ([string]$meta.myMeritAppProc)
            }
            else {
                Add-HubKnownPath -Seen $seen -Path ([string]$meta.myMeritTools)
                Add-HubKnownPath -Seen $seen -Path ([string]$meta.myMeritToolsUser)
            }
        }
        catch { }
    }
    return @($seen)
}

function Sync-HubMeritEnvFromUser {
    if (Test-HubProcessBenchMode) { return }
    foreach ($name in @('MYMERITTOOLS', 'MYMERITAPP')) {
        $user = [Environment]::GetEnvironmentVariable($name, 'User')
        $proc = [Environment]::GetEnvironmentVariable($name, 'Process')
        if (-not [string]::IsNullOrWhiteSpace($user)) {
            if ($proc -ne $user) {
                Set-Item -Path "Env:$name" -Value $user
                if ($proc) {
                    Write-Note "Synced Process $name to User ($user); was $proc"
                }
            }
        }
        elseif (-not [string]::IsNullOrWhiteSpace($proc)) {
            Remove-Item "Env:$name" -ErrorAction SilentlyContinue
            Write-Note "Dropped stale Process $name ($proc) — User is empty"
        }
    }
}

function Test-HubAdmin {
    if (-not $Script:HubOnWindows) { return $true }
    try {
        return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch { return $false }
}

function Write-HubEnvScopes {
    foreach ($name in @('MYMERITTOOLS', 'MYMERITAPP')) {
        $p = [Environment]::GetEnvironmentVariable($name, 'Process')
        $u = [Environment]::GetEnvironmentVariable($name, 'User')
        $m = [Environment]::GetEnvironmentVariable($name, 'Machine')
        Write-Info ("{0}  Process={1}  User={2}  Machine={3}" -f $name,
            $(if ($p) { $p } else { '(empty)' }),
            $(if ($u) { $u } else { '(empty)' }),
            $(if ($m) { $m } else { '(empty)' }))
    }
}

function Get-HubRelaunchArgumentList {
    $list = [System.Collections.Generic.List[string]]::new()
    $list.Add('-NoProfile')
    $list.Add('-ExecutionPolicy')
    $list.Add('Bypass')
    $list.Add('-File')
    $list.Add($Script:HubScriptPath)
    $bound = if ($Script:HubBoundParameters) { $Script:HubBoundParameters } else { $PSBoundParameters }
    foreach ($key in @($bound.Keys)) {
        $val = $bound[$key]
        if ($val -is [switch]) {
            if ($val.IsPresent) { $list.Add("-$key") }
            continue
        }
        if ($val -eq $true) { $list.Add("-$key"); continue }
        $list.Add("-$key")
        $list.Add([string]$val)
    }
    return @($list)
}

function Start-HubTranscript {
    New-Item -ItemType Directory -Force -Path $Script:BackupRoot | Out-Null
    $Script:HistoryLog = Join-Path $Script:BackupRoot 'Merit-Hub-history.log'
    try {
        Start-Transcript -Path $Script:HistoryLog -Append -ErrorAction Stop | Out-Null
        $Script:TranscriptStarted = $true
    }
    catch {
        Write-Warn "Could not start transcript: $($_.Exception.Message)"
        $Script:TranscriptStarted = $false
    }
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor DarkGray
    Write-Host ("  Merit-Hub run  {0}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host ("  user={0}  machine={1}  elevated={2}" -f $env:USERNAME, $env:COMPUTERNAME, (Test-HubAdmin))
    Write-Host ("  script={0}" -f $Script:HubScriptPath)
    Write-Host ("  log (append)={0}" -f $Script:HistoryLog)
    Write-Host ('=' * 72) -ForegroundColor DarkGray
}

function Stop-HubTranscript {
    if (-not $Script:TranscriptStarted) { return }
    try { Stop-Transcript | Out-Null } catch { }
    $Script:TranscriptStarted = $false
    Write-Note "Run log appended: $Script:HistoryLog"
}

function Wait-HubWindow {
    param([string]$Reason = 'Merit-Hub finished')
    if ($env:MERIT_HUB_NO_ELEVATE -eq '1') { return }
    if (-not [Environment]::UserInteractive) { return }
    Write-Host ''
    Write-Note $Reason
    if ($Script:HistoryLog) { Write-Info "History: $Script:HistoryLog" }
    try { [void](Read-Host 'Press Enter to close') } catch { }
}

function Complete-HubSession {
    param([string]$Reason = 'Merit-Hub finished')
    Stop-HubTranscript
    Wait-HubWindow -Reason $Reason
}

function Ensure-HubElevated {
    if (-not $Script:HubOnWindows) { return }
    if ($Help) { return }
    if ($env:MERIT_HUB_NO_ELEVATE -eq '1') { return }
    if (Test-HubAdmin) {
        Write-Ok 'Running elevated (Administrator)'
        return
    }
    $exe = (Get-Process -Id $PID).Path
    $argList = Get-HubRelaunchArgumentList
    Write-Note 'Not elevated. Opening an Administrator window (UAC).'
    Write-Info ("{0} {1}" -f $exe, ($argList -join ' '))
    New-Item -ItemType Directory -Force -Path $Script:BackupRoot | Out-Null
    $Script:HistoryLog = Join-Path $Script:BackupRoot 'Merit-Hub-history.log'
    $line = '{0} relaunch-elevated user={1} script={2}' -f (Get-Date).ToString('o'), $env:USERNAME, $Script:HubScriptPath
    try { Add-Content -LiteralPath $Script:HistoryLog -Value $line -Encoding UTF8 } catch { }
    try {
        Start-Process -FilePath $exe -Verb RunAs -ArgumentList $argList
    }
    catch {
        Write-Fail "UAC relaunch failed: $($_.Exception.Message)"
        Write-Info 'Continue without admin - deletes may fail on locked / protected folders.'
        return
    }
    Wait-HubWindow -Reason 'Elevated Merit-Hub is running in the other window. Press Enter to close this one.'
    exit 0
}

function Test-HubIsPwsh7 {
    return ($PSVersionTable.PSVersion.Major -ge 7)
}

function Ensure-HubPwshHost {
    if (Test-HubIsPwsh7) { return }
    if ($env:MERIT_HUB_NO_PWSH_RELAUNCH -eq '1') { return }

    $hint = Get-HubRunHint
    Write-Header 'Use pwsh (PowerShell 7+)'
    Write-Note 'Windows PowerShell 5.1 started this file. Daily use is pwsh -- this host is only a bootstrap.'
    Write-Host ''
    Write-Host "  $hint" -ForegroundColor Cyan
    Write-Host ''

    $pwshExe = Resolve-MeritPwshExe
    if ($pwshExe) {
        Write-Ok "pwsh found: $pwshExe"
        Write-Note 'Re-launching with that command (same arguments).'
        $argList = Get-HubRelaunchArgumentList
        & $pwshExe @argList
        exit $LASTEXITCODE
    }

    Write-Warn 'pwsh is not installed (or not on PATH).'
    Show-PwshInstallGuide
    Write-Note 'Continuing in Windows PowerShell 5.1 so menu 1 can install pwsh. After that, run the command above.'
}

function Test-HubProcessBenchMode {
    return ($env:MERIT_HUB_NO_PERSIST_ENV -eq '1')
}

function Set-UserEnvVar {
    param([string]$Name, [string]$Value)
    if (Test-HubProcessBenchMode) {
        Set-Item -Path "Env:$Name" -Value $Value
        Write-Note "$Name Process-only (MERIT_HUB_NO_PERSIST_ENV=1). User env not changed - other terminals keep their bench."
        return
    }
    $existing = [Environment]::GetEnvironmentVariable($Name, 'User')
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
    if ($existing -eq $Value) {
        Write-Ok "$Name User env already set = $Value"
        return
    }
    Write-Ok "SET User env $Name = $Value (was $(if ($existing) { $existing } else { 'empty' }))"
    Write-Note 'Open a NEW terminal to see User env in other windows. This process already has it.'
    if ($Name -eq 'MYMERITAPP') {
        [void](Import-HubOssHelpers)
    }
}

function Clear-EnvVarAllScopes {
    param([string]$Name)
    foreach ($scope in @('Process', 'User', 'Machine')) {
        try {
            if ($scope -eq 'Process') {
                Remove-Item "Env:$Name" -ErrorAction SilentlyContinue
                continue
            }
            $existing = [Environment]::GetEnvironmentVariable($Name, $scope)
            if ([string]::IsNullOrWhiteSpace($existing)) { continue }
            if ($scope -eq 'Machine') {
                if (-not (Test-HubAdmin)) {
                    Write-Warn "Cannot clear Machine:$Name without admin (was $existing)"
                    continue
                }
            }
            [Environment]::SetEnvironmentVariable($Name, $null, $scope)
            Write-Ok "cleared $scope`:$Name (was $existing)"
        }
        catch {
            Write-Warn "Could not clear $scope`:$Name - $($_.Exception.Message)"
        }
    }
}

function Remove-PathFromUserEnvPath {
    param([string[]]$PathsToRemove)
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrWhiteSpace($userPath)) { return }
    $normRemove = @()
    foreach ($p in $PathsToRemove) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        try { $normRemove += [IO.Path]::GetFullPath($p.Trim().TrimEnd('\', '/')) } catch { }
    }
    $parts = $userPath -split ';' | Where-Object {
        $seg = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($seg)) { return $false }
        try {
            $full = [IO.Path]::GetFullPath($seg)
            return ($normRemove -notcontains $full)
        }
        catch { return $true }
    }
    $newPath = ($parts -join ';').Trim(';')
    if ($newPath -ne $userPath.Trim(';')) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Ok "removed from User Path: $($normRemove -join ', ')"
    }
}

function Refresh-ProcessPath {
    if ($Script:HubOnWindows) {
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')
    }
}

function Invoke-HubNativeQuiet {
    param([string]$FilePath, [string[]]$NativeArgs)
    if (-not (Test-Path -LiteralPath $FilePath)) { return }
    try {
        $p = Start-Process -FilePath $FilePath -ArgumentList $NativeArgs -Wait -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        return $p.ExitCode
    }
    catch { return $null }
}

function Clear-HubPathAttributes {
    param([string]$Path)
    if (-not $Script:HubOnWindows) { return }
    $attrib = Join-Path $env:SystemRoot 'System32\attrib.exe'
    Write-Info "clearing R/A/S/H attributes under $Path"
    [void](Invoke-HubNativeQuiet -FilePath $attrib -NativeArgs @('-R', '-A', '-S', '-H', $Path, '/S', '/D'))
}

function Repair-HubPathAcl {
    param([string]$Path)
    if (-not $Script:HubOnWindows) { return }
    if (-not (Test-HubAdmin)) {
        Write-Info 'skip takeown/icacls (not elevated)'
        return
    }
    $takeown = Join-Path $env:SystemRoot 'System32\takeown.exe'
    $icacls = Join-Path $env:SystemRoot 'System32\icacls.exe'
    Write-Info "takeown / icacls grant for $Path"
    [void](Invoke-HubNativeQuiet -FilePath $takeown -NativeArgs @('/F', $Path, '/R', '/D', 'Y'))
    [void](Invoke-HubNativeQuiet -FilePath $icacls -NativeArgs @($Path, '/grant', "${env:USERNAME}:(OI)(CI)F", '/T', '/C', '/Q'))
}

function Get-HubLockingProcesses {
    param([string]$Path)
    $norm = $Path.TrimEnd('\', '/')
    $hits = @()
    try {
        $hits += @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
                ($_.ExecutablePath -and $_.ExecutablePath.StartsWith($norm, [StringComparison]::OrdinalIgnoreCase)) -or
                ($_.CommandLine -and $_.CommandLine.IndexOf($norm, [StringComparison]::OrdinalIgnoreCase) -ge 0)
            } | Select-Object ProcessId, Name, ExecutablePath)
    }
    catch { }
    return @($hits)
}

function Write-HubDeleteInsight {
    param([string]$Path, [string]$Label)
    Write-Info "delete insight: $Label"
    Write-Info "  path   = $Path"
    Write-Info "  admin  = $(Test-HubAdmin)"
    $lock = @(Get-HubLockingProcesses -Path $Path)
    if ($lock.Count -eq 0) {
        Write-Info '  no Win32_Process image/command line matched this path (Cursor/Explorer can still lock files)'
    }
    else {
        Write-Warn '  processes that look related (close these, then retry):'
        foreach ($p in $lock | Select-Object -First 12) {
            Write-Info ("    pid={0} name={1} exe={2}" -f $p.ProcessId, $p.Name, $p.ExecutablePath)
        }
    }
    if (Test-Path -LiteralPath $Path -PathType Container) {
        $kids = @(Get-ChildItem -LiteralPath $Path -Force -Recurse -ErrorAction SilentlyContinue | Select-Object -First 15)
        Write-Info ("  remaining entries (first {0}):" -f $kids.Count)
        foreach ($k in $kids) { Write-Info ("    {0}" -f $k.FullName) }
    }
}

function Remove-PathSafe {
    param([string]$Path, [string]$Label)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Info "skip (missing): $Label -> $Path"
        return
    }
    if (-not $PSCmdlet.ShouldProcess($Path, "Remove $Label")) { return }
    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        Write-Ok "removed $Label -> $Path"
        return
    }
    catch {
        Write-Warn "first delete failed $Label : $($_.Exception.Message)"
    }
    Write-HubDeleteInsight -Path $Path -Label $Label
    Clear-HubPathAttributes -Path $Path
    Repair-HubPathAcl -Path $Path
    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        Write-Ok "removed $Label after attrib/acl -> $Path"
        return
    }
    catch {
        Write-Warn "retry delete failed $Label : $($_.Exception.Message)"
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return }
    $parent = Split-Path -Parent $Path
    $leaf = Split-Path -Leaf $Path
    $aside = Join-Path $parent ("{0}.pristine-aside-{1}" -f $leaf, (Get-Date -Format 'yyyyMMdd-HHmmss'))
    try {
        Move-Item -LiteralPath $Path -Destination $aside -Force -ErrorAction Stop
        Write-Warn "moved aside: $aside"
        Write-Ok "cleared path for cold-start: $Path"
    }
    catch {
        Write-Fail "could not remove or move $Label -> $Path"
        Write-Info 'Close locking apps (Cursor, Explorer preview, git, terminals with that cwd) and re-run Pristine elevated.'
    }
}

function Copy-IfExists {
    param([string]$Source, [string]$DestDir, [string]$DestName = $null)
    if (-not (Test-Path -LiteralPath $Source)) { return $false }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    $leaf = if ($DestName) { $DestName } else { Split-Path -Leaf $Source }
    $dest = Join-Path $DestDir $leaf
    if (Test-Path -LiteralPath $Source -PathType Container) {
        Copy-Item -LiteralPath $Source -Destination $dest -Recurse -Force
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $dest -Force
    }
    return $true
}

function New-MeritBackup {
    $cfg = Get-HubConfig
    $tools = Get-MyMeritToolsRoot
    $oss = Get-MyMeritAppRoot
    $dev = Get-DevRoot
    New-Item -ItemType Directory -Force -Path $Script:BackupRoot | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $dir = Join-Path $Script:BackupRoot $stamp
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Write-Header "Backup -> $dir"

    $meta = [ordered]@{
        backedUpAt       = (Get-Date).ToString('o')
        machine          = $env:COMPUTERNAME
        user             = $env:USERNAME
        home             = $HOME
        hubRoot          = $Script:HubRoot
        myMeritTools     = $tools
        myMeritToolsUser = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'User')
        devRoot          = $dev
        ossBench         = $oss
        myMeritAppUser   = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
        myMeritAppProc   = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'Process')
        skillsPin        = [string]$cfg.skillsPin
        vaultPin         = [string]$cfg.vaultPin
        userPath         = [Environment]::GetEnvironmentVariable('Path', 'User')
    }
    ($meta | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath (Join-Path $dir 'env-snapshot.json') -Encoding UTF8
    Write-Ok 'env-snapshot.json'

    foreach ($pair in @(
            @{ Src = (Join-Path $dev 'MERIT.json'); Sub = 'dev'; Name = 'MERIT.json' }
            @{ Src = (Join-Path $oss 'BootStrap\MERIT.json'); Sub = 'oss-bootstrap'; Name = 'MERIT.json' }
            @{ Src = $Script:HubScriptPath; Sub = 'hub'; Name = (Split-Path -Leaf $Script:HubScriptPath) }
        )) {
        if (Copy-IfExists -Source $pair.Src -DestDir (Join-Path $dir $pair.Sub) -DestName $pair.Name) {
            Write-Ok "$($pair.Sub)/$($pair.Name)"
        }
    }

    $runHint = Get-HubRunHint
    $readme = @'
# Merit-Hub backup {0}

After **Pristine**, cold-start from the hub (no prior clone required):

```powershell
{1}
# J = Jumpstart OSS  |  V = Jumpstart Vault  |  1 = Prereqs only
```

Pins: skills={2} vault={3}
'@ -f $stamp, $runHint, [string]$cfg.skillsPin, [string]$cfg.vaultPin
    Set-Content -LiteralPath (Join-Path $dir 'README.md') -Value $readme -Encoding UTF8
    Write-Ok 'README.md'
    return $dir
}

function Test-HubSafeWipeTarget {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $full = Expand-HomePath $Path
    $homeRoot = Expand-HomePath $HOME
    $dev = Get-DevRoot
    $roots = @($homeRoot)
    if ($Script:HubOnWindows) {
        $roots += [IO.Path]::GetFullPath('C:\')
    }
    if ($full -in $roots) { return $false }
    if ($full -eq (Expand-HomePath $dev)) { return $false }
    return $true
}

function Invoke-WipeLegacyMeritHubFolder {
    $tools = Get-MyMeritToolsRoot
    $legacy = Join-Path $tools 'Merit-Hub'
    if (-not (Test-Path -LiteralPath $legacy -PathType Container)) { return }
    $hubNorm = Expand-HomePath $Script:HubScriptPath
    $legacyNorm = Expand-HomePath $legacy
    $inside = $hubNorm.StartsWith(($legacyNorm.TrimEnd('\', '/') + '\'), [StringComparison]::OrdinalIgnoreCase)
    if ($inside) {
        Write-Warn "Hub is still inside leftover $legacy - removing other files; save hub as $(Join-Path $tools 'Merit-Hub.ps1')"
        Get-ChildItem -LiteralPath $legacy -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -ne $hubNorm } |
            ForEach-Object { Remove-PathSafe -Path $_.FullName -Label "legacy hub $($_.Name)" }
        return
    }
    Remove-PathSafe -Path $legacy -Label 'leftover Tools\Merit-Hub folder (retired layout)'
}

function Invoke-WipeOssBenches {
    param(
        [string]$ConfiguredOss,
        [string]$BackupDir = ''
    )
    $targets = @(Get-AllKnownMeritEnvPaths -Name 'MYMERITAPP' -BackupDir $BackupDir)
    if (-not [string]::IsNullOrWhiteSpace($ConfiguredOss)) {
        $full = Expand-HomePath $ConfiguredOss
        if ($targets -notcontains $full) { $targets += $full }
    }
    $hubDir = Expand-HomePath $Script:HubRoot
    foreach ($fullOss in $targets) {
        if (-not (Test-HubSafeWipeTarget $fullOss)) {
            Write-Fail "Refusing to wipe unsafe OSS path: $fullOss"
            continue
        }
        if ($fullOss -eq $hubDir) {
            Write-Warn "OSS bench equals hub directory $fullOss - not deleting Tools root"
            Invoke-WipeLegacyMeritHubFolder
            continue
        }
        Remove-PathSafe -Path $fullOss -Label 'OSS bench (MYMERITAPP)'
    }
}

function Remove-RetiredOssLiveBootStrap {
    # Old OSS BootStrap copied a second product to %MYMERITAPP%\BootStrap plus a
    # bench-root MERIT_BootStrap.cmd. Hub never creates those. Git source stays at
    # %MYMERITAPP%\merit-agent-skills\BootStrap\_oss.ps1.
    $benches = [System.Collections.Generic.List[string]]::new()
    foreach ($p in @(Get-AllKnownMeritEnvPaths -Name 'MYMERITAPP')) {
        if (-not $benches.Contains($p)) { [void]$benches.Add($p) }
    }
    foreach ($bench in $benches) {
        if (-not (Test-Path -LiteralPath $bench)) { continue }
        $gitBoot = Join-Path $bench 'merit-agent-skills\BootStrap'
        $liveBoot = Join-Path $bench 'BootStrap'
        $gitFull = $null
        if (Test-Path -LiteralPath $gitBoot) {
            $gitFull = [IO.Path]::GetFullPath($gitBoot)
        }
        if (Test-Path -LiteralPath $liveBoot) {
            $liveFull = [IO.Path]::GetFullPath($liveBoot)
            if ($gitFull -and ($liveFull -eq $gitFull)) {
                Write-Info 'skip retired live BootStrap wipe - path is the git clone BootStrap'
            }
            else {
                Remove-PathSafe -Path $liveFull -Label 'retired live OSS BootStrap copy (not the git clone)'
            }
        }
        $legacyCmd = Join-Path $bench 'MERIT_BootStrap.cmd'
        if (Test-Path -LiteralPath $legacyCmd) {
            Remove-PathSafe -Path $legacyCmd -Label 'retired bench-root MERIT_BootStrap.cmd'
        }
    }
}

function Test-HubProtectedScanPath {
    param([string]$Path)
    $full = Expand-HomePath $Path
    $hubDir = Expand-HomePath $Script:HubRoot
    $tools = Get-MyMeritToolsRoot
    $blocked = @(
        $hubDir,
        $tools,
        (Join-Path $env:SystemRoot ''),
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        (Join-Path $env:SystemDrive 'Windows')
    )
    foreach ($b in $blocked) {
        if ([string]::IsNullOrWhiteSpace($b)) { continue }
        $bn = Expand-HomePath $b
        if ($full -eq $bn) { return $true }
    }
    if ($Script:HubOnWindows -and $full -eq [IO.Path]::GetFullPath('C:\')) { return $true }
    return $false
}

function Get-HubRogueFolderCandidates {
    $cfg = Get-HubConfig
    $names = @($cfg.rogueProfileNames)
    $globs = @($cfg.rogueProfileGlobs)
    $driveNames = @($cfg.rogueDriveRootNames)
    $found = New-Object System.Collections.Generic.List[string]
    $skipUser = @('Public', 'Default', 'Default User', 'All Users', 'DefaultAppPool')

    $roots = New-Object System.Collections.Generic.List[string]
    if ($Script:HubOnWindows -and $env:SystemDrive) {
        $driveRoot = $env:SystemDrive + '\'
        $roots.Add($driveRoot)
        $usersRoot = Join-Path $env:SystemDrive 'Users'
        if (Test-Path -LiteralPath $usersRoot) {
            Get-ChildItem -LiteralPath $usersRoot -Directory -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notin $skipUser } |
                ForEach-Object { $roots.Add($_.FullName) }
        }
    }
    $dev = Get-DevRoot
    if (Test-Path -LiteralPath $dev) { $roots.Add($dev) }

    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $isDrive = ($Script:HubOnWindows -and ($root.TrimEnd('\') + '\').ToLower() -eq (($env:SystemDrive + '\').ToLower()))
        $checkNames = if ($isDrive) { $driveNames } else { $names }
        foreach ($n in $checkNames) {
            $p = Join-Path $root $n
            if ((Test-Path -LiteralPath $p) -and -not (Test-HubProtectedScanPath $p) -and -not $found.Contains((Expand-HomePath $p))) {
                $found.Add((Expand-HomePath $p))
            }
        }
        if (-not $isDrive) {
            foreach ($g in $globs) {
                Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like $g } |
                    ForEach-Object {
                        $fp = Expand-HomePath $_.FullName
                        if (-not (Test-HubProtectedScanPath $fp) -and -not $found.Contains($fp)) { $found.Add($fp) }
                    }
            }
        }
    }
    return @($found | Sort-Object -Unique)
}

function Invoke-RogueFolderReview {
    $cands = @(Get-HubRogueFolderCandidates)
    Write-Header 'Leftover folder scan'
    if ($cands.Count -eq 0) {
        Write-Ok 'No catalog leftovers (HumanBala, DravenCode.OLD, Code, *Merit*, ...)'
        return
    }
    Write-Note 'These are NOT deleted automatically. Known leftover names under C:\, each C:\Users\<name>, and ~/dev.'
    $i = 1
    foreach ($p in $cands) {
        Write-Info ("  {0}) {1}" -f $i, $p)
        $i++
    }
    if ($Force) {
        Write-Warn '-Force skips leftover deletes (too dangerous). Re-run without -Force to review.'
        return
    }
    $go = Read-Host 'Review leftovers for possible delete? [y/N]'
    if ($go -notmatch '^[Yy]') { Write-Info 'Skipped leftover review.'; return }
    foreach ($p in $cands) {
        Write-Host ''
        Write-Warn "Candidate: $p"
        $d = Read-Host 'Delete this folder? [y/N]'
        if ($d -notmatch '^[Yy]') { Write-Info "kept $p"; continue }
        $ok = Read-Host "Type DELETE to confirm removal of $p"
        if ($ok -ne 'DELETE') { Write-Warn "not confirmed - kept $p"; continue }
        Remove-PathSafe -Path $p -Label "leftover $p"
    }
}

function Invoke-WipeMeritToolsArtifacts {
    param(
        [bool]$IncludeGhShims = $true,
        [string]$BackupDir = ''
    )
    $toolsPaths = @(Get-AllKnownMeritEnvPaths -Name 'MYMERITTOOLS' -BackupDir $BackupDir)
    if ($toolsPaths.Count -eq 0) {
        $toolsPaths = @(Get-MyMeritToolsRoot)
    }
    Write-Info ("MYMERITTOOLS wipe targets: " + ($toolsPaths -join '; '))
    Invoke-WipeLegacyMeritHubFolder
    foreach ($tools in $toolsPaths) {
        Remove-PathSafe -Path (Join-Path $tools 'merit-venv') -Label "merit-venv @ $tools"
        foreach ($f in @('merit-python.cmd', 'merit-python', 'merit-python.ps1', 'pwsh.cmd')) {
            Remove-PathSafe -Path (Join-Path $tools $f) -Label "$f @ $tools"
        }
        if ($IncludeGhShims) {
            foreach ($f in @('gh.cmd', 'gh')) {
                $p = Join-Path $tools $f
                if (Test-Path -LiteralPath $p -PathType Leaf) {
                    $size = (Get-Item -LiteralPath $p).Length
                    if ($size -lt 2048) {
                        Remove-PathSafe -Path $p -Label "Tools shim $f @ $tools"
                    }
                    else {
                        Write-Info ('skip large ' + $p + ' (' + $size + ' bytes) - not assumed MERIT shim')
                    }
                }
            }
        }
    }
}

function Invoke-MeritCleanup {
    param(
        [string]$BackupDir,
        [string]$ModeName,
        [string]$ConfirmWord,
        [bool]$DoWipeOss,
        [bool]$DoWipeDevTree,
        [bool]$DoWipeToolsArtifacts
    )
    $cfg = Get-HubConfig
    $oss = Get-MyMeritAppRoot
    $dev = Get-DevRoot
    $tools = Get-MyMeritToolsRoot

    Write-Header "Cleanup plan ($ModeName)"
    Write-Info "Backup:     $BackupDir"
    $benchList = @(Get-AllKnownMeritEnvPaths -Name 'MYMERITAPP' -BackupDir $BackupDir)
    $toolsList = @(Get-AllKnownMeritEnvPaths -Name 'MYMERITTOOLS' -BackupDir $BackupDir)
    Write-Info ("MYMERITAPP benches to wipe ($($benchList.Count)): " + ($benchList -join '; '))
    Write-Info ("MYMERITTOOLS trees to wipe ($($toolsList.Count)): " + ($toolsList -join '; '))
    Write-Info "~/dev:      $dev (wipe tree=$DoWipeDevTree)"
    Write-Info 'Will clear MYMERITAPP + MYMERITTOOLS (User/Machine/Process where allowed)'
    Write-Info 'That is why a later hub run has empty MYMERIT* until you answer the prompts again (Enter = defaults).'
    Write-Info 'Will remove ~/dev from User Path if present'
    Write-HubEnvScopes

    if (-not $Force -and -not $WhatIfPreference) {
        Write-Host ''
        Write-Warn "Type $ConfirmWord to proceed (or -Force)."
        $ans = Read-Host 'Confirm'
        if ($ans -ne $ConfirmWord) {
            Write-Warn 'Aborted - backup kept.'
            return
        }
    }

    Write-Header "Cleanup ($ModeName)"
    Remove-RetiredOssLiveBootStrap

    $liveFiles = @(
        'MERIT.json', 'MERIT_BootStrap.ps1', 'MERIT_BootStrap.cmd', 'MERIT_BootStrap.sh',
        'merit.cmd', 'MERIT.sh', 'MERIT.ps1', 'MERIT.cmd'
    )
    foreach ($n in $liveFiles) {
        Remove-PathSafe -Path (Join-Path $dev $n) -Label "dev live $n"
    }
    Remove-PathSafe -Path (Join-Path $dev '.merit') -Label 'dev/.merit'

    if ($DoWipeDevTree) {
        foreach ($owner in @('AgentDraven', 'Mr-PI-Bala')) {
            Remove-PathSafe -Path (Join-Path $dev $owner) -Label "clone owner $owner"
        }
        if (Test-Path -LiteralPath $dev) {
            Get-ChildItem -LiteralPath $dev -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like 'merit-private-vault.*bak-*' -or $_.Name -like '*.pristine-aside-*' } |
                ForEach-Object { Remove-PathSafe -Path $_.FullName -Label $_.Name }
            $remaining = @(Get-ChildItem -LiteralPath $dev -Force -ErrorAction SilentlyContinue)
            if ($remaining.Count -eq 0) {
                Remove-PathSafe -Path $dev -Label '~/dev folder'
            }
            else {
                Write-Warn "~/dev not empty after clone wipe - remaining: $($remaining.Name -join ', ')"
                Write-Info 'Remove manually or close handles, then re-run Pristine.'
            }
        }
    }

    if ($DoWipeOss) {
        Invoke-WipeOssBenches -ConfiguredOss $oss -BackupDir $BackupDir
    }
    if ($DoWipeToolsArtifacts) {
        Invoke-WipeMeritToolsArtifacts -BackupDir $BackupDir
    }

    Clear-EnvVarAllScopes -Name 'MYMERITAPP'
    if ($DoWipeToolsArtifacts) {
        Clear-EnvVarAllScopes -Name 'MYMERITTOOLS'
    }
    Write-Note 'MYMERITAPP / MYMERITTOOLS cleared. Next interactive run will prompt (Enter = defaults).'
    Write-HubEnvScopes

    Remove-PathFromUserEnvPath -PathsToRemove @($dev)

    if ($ModeName -eq 'Pristine') {
        Invoke-RogueFolderReview
    }

    Write-Host ''
    Write-Ok "Cleanup finished ($ModeName)."
    Write-Info "Backup: $BackupDir"
    Write-Info "Cold start: $(Get-HubRunHint)  ->  J Jumpstart OSS"
}

function Invoke-Mode {
    param([ValidateSet('Pristine', 'Soft', 'BackupOnly')]$Mode)
    switch ($Mode) {
        'Pristine' {
            Write-Header 'Mode: PRISTINE v2 (brand-new laptop)'
            Write-Info 'Wipes every known MYMERITAPP bench (Process/User/Machine, defaults, backup history) and MYMERITTOOLS merit-venv/shims, ~/dev tree, MYMERIT* env.'
            Write-Info "Keeps this hub script only: $Script:HubScriptPath"
            $backup = New-MeritBackup
            Invoke-MeritCleanup -BackupDir $backup -ModeName $Mode -ConfirmWord 'PRISTINE' `
                -DoWipeOss $true -DoWipeDevTree $true -DoWipeToolsArtifacts $true
        }
        'Soft' {
            Write-Header 'Mode: SOFT (keep ~/dev clones)'
            $backup = New-MeritBackup
            Invoke-MeritCleanup -BackupDir $backup -ModeName $Mode -ConfirmWord 'CLEAN' `
                -DoWipeOss $true -DoWipeDevTree $false -DoWipeToolsArtifacts $false
        }
        'BackupOnly' {
            Write-Header 'Mode: BACKUP ONLY'
            $backup = New-MeritBackup
            Write-Ok "Backup-only: $backup"
        }
    }
}

function Show-PwshInstallGuide {
    Write-Header 'PowerShell 7+ (pwsh)  -  recommended runner'
    Write-Info 'Merit-Hub and merit.ps1 work best with pwsh. Hub runs on Windows PowerShell 5.1 only for bootstrapping.'
    Write-Host ''
    Write-Host '  Download / install by platform:' -ForegroundColor White
    Write-Host '  Windows (winget):     winget install Microsoft.PowerShell'
    Write-Host '  Windows (MSI/docs):   https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows'
    Write-Host '  All releases (zip):   https://github.com/PowerShell/PowerShell/releases'
    Write-Host '  macOS:                brew install powershell/tap/powershell'
    Write-Host '  Linux:                https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux'
    Write-Host ''
    Write-Note 'winget / MSI install to Program Files (system-wide)  -  normal and supported.'
    Write-Note 'Optional laptop-local copy: menu 1 can extract portable pwsh to %MYMERITTOOLS%\pwsh + pwsh.cmd shim (stays under Tools).'
}

function Resolve-MeritPwshExe {
    $tools = Get-MyMeritToolsRoot
    foreach ($candidate in @(
            (Join-Path $tools 'pwsh\pwsh.exe'),
            (Join-Path $tools 'pwsh\PowerShell\pwsh.exe')
        )) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    if ($Script:HubOnWindows) {
        foreach ($c in @(
                (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'PowerShell\7\pwsh.exe')
            )) {
            if ($c -and (Test-Path -LiteralPath $c)) { return $c }
        }
    }
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) {
        return $cmd.Source
    }
    if ($cmd) { return 'pwsh' }
    return $null
}

function Install-MeritToolsPwshPortable {
    if (-not $Script:HubOnWindows) {
        Show-PwshInstallGuide
        return $false
    }
    $cfg = Get-HubConfig
    $ver = if ($cfg.pwshPortableVersion) { [string]$cfg.pwshPortableVersion } else { '7.5.2' }
    $tools = Get-MyMeritToolsRoot
    $destRoot = Join-Path $tools 'pwsh'
    $url = "https://github.com/PowerShell/PowerShell/releases/download/v$ver/PowerShell-$ver-win-x64.zip"
    $zip = Join-Path $env:TEMP "PowerShell-$ver-win-x64.zip"
    Write-Header "Portable pwsh -> $destRoot"
    Write-Info "Download: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    }
    catch {
        Write-Fail "Download failed: $($_.Exception.Message)"
        Show-PwshInstallGuide
        return $false
    }
    if (Test-Path -LiteralPath $destRoot) {
        Remove-Item -LiteralPath $destRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $destRoot -Force
    Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    $pwshExe = Get-ChildItem -LiteralPath $destRoot -Recurse -Filter 'pwsh.exe' -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $pwshExe) {
        Write-Fail 'pwsh.exe not found after extract'
        return $false
    }
    $shim = Join-Path $tools 'pwsh.cmd'
    Set-Content -LiteralPath $shim -Value "@echo off`r`n`"$pwshExe`" %*`r`n" -Encoding ASCII
    Write-Ok "Portable pwsh: $pwshExe"
    Write-Ok "Shim: $shim (prepend MYMERITTOOLS to PATH or open new terminal)"
    return $true
}

function Get-SkillsRepoRoot {
    [void](Import-HubMeritResolve)
    if (Get-Command Resolve-MeritSkillsRepoRoot -ErrorAction SilentlyContinue) {
        $resolved = Resolve-MeritSkillsRepoRoot -AllowIdeMarker
        if ($resolved.Root) { return $resolved.Root }
    }
    $bench = Get-MyMeritAppRoot
    return Join-Path $bench 'merit-agent-skills'
}

function Get-HubOssInternalScript {
    return Join-Path (Get-SkillsRepoRoot) 'BootStrap\_oss.ps1'
}

function Import-HubOssHelpers {
    $oss = Get-HubOssInternalScript
    if (-not (Test-Path -LiteralPath $oss)) { return $false }
    . $oss
    return [bool](Get-Command Get-OssState -ErrorAction SilentlyContinue)
}

function Ensure-SkillsRepo {
    $cfg = Get-HubConfig
    $dest = Get-SkillsRepoRoot
    if (Test-Path -LiteralPath (Join-Path $dest 'skills')) {
        Write-Ok "skills repo present: $dest"
        return $dest
    }
    Write-Note 'merit-agent-skills not on bench  -  cloning pinned release ...'
    if (-not (Invoke-GitClonePin -Url ([string]$cfg.skillsUrl) -Pin ([string]$cfg.skillsPin) -Dest $dest -Label 'merit-agent-skills')) {
        return $null
    }
    [void](Import-HubOssHelpers)
    return $dest
}

function Invoke-InstallMeritSkills {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,
        [string]$ProjectPath = ''
    )
    $known = @('Cursor', 'ClaudeCode', 'Claude', 'Codex', 'VSCode', 'Agents', 'Hermes', 'OpenClaw', 'GrokBot', 'Grok', 'Devin', 'Project')
    if ($known -notcontains $Target) {
        Write-Fail "Unknown host '$Target'. Use: $($known -join ', ')"
        return $false
    }
    [void](Invoke-MeritPrereqs)
    $repoRoot = Ensure-SkillsRepo
    if (-not $repoRoot) { return $false }
    $skillsSrc = Join-Path $repoRoot 'skills'
    if (-not (Test-Path -LiteralPath $skillsSrc)) {
        Write-Fail "skills/ missing under $repoRoot"
        return $false
    }
    $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    $resolved = switch ($Target) {
        'Claude' { 'ClaudeCode' }
        'Agents' { 'VSCode' }
        'Grok' { 'GrokBot' }
        default { $Target }
    }
    $destRoot = switch ($resolved) {
        'Cursor' { Join-Path $homeRoot '.cursor\skills' }
        'ClaudeCode' { Join-Path $homeRoot '.claude\skills' }
        'Codex' {
            $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeRoot '.codex' }
            Join-Path $codexHome 'skills'
        }
        'VSCode' { Join-Path $homeRoot '.agents\skills' }
        'Hermes' { Join-Path $homeRoot '.hermes\skills' }
        'OpenClaw' { Join-Path $homeRoot '.openclaw\skills' }
        'GrokBot' { Join-Path $homeRoot '.grok\skills' }
        'Devin' { Join-Path $homeRoot '.devin\skills' }
        'Project' {
            if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
                Write-Fail 'Project install requires -InstallSkillsPath (repo-root)'
                return $false
            }
            Join-Path (Resolve-Path $ProjectPath).Path '.cursor\skills'
        }
    }
    Write-Header "Install MERIT skills -> $destRoot"
    New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
    $count = 0
    Get-ChildItem -LiteralPath $skillsSrc -Directory | ForEach-Object {
        $destSkill = Join-Path $destRoot $_.Name
        if (Test-Path -LiteralPath $destSkill) {
            Remove-Item -LiteralPath $destSkill -Recurse -Force
        }
        Write-Ok "install $($_.Name)"
        Copy-Item -LiteralPath $_.FullName -Destination $destSkill -Recurse -Force
        $count++
    }
    Write-Ok "Installed $count skills (Target=$Target)"
    $pin = ''
    $verFile = Join-Path $repoRoot 'VERSION'
    if (Test-Path -LiteralPath $verFile) {
        $v = ((Get-Content -LiteralPath $verFile -Raw) -split '\r?\n')[0].Trim()
        if ($v) { $pin = "skills-v$v" }
    }
    $marker = @{
        schemaVersion  = 1
        skillsRepoRoot = $repoRoot
        installedAt    = (Get-Date).ToString('o')
        pin            = $pin
        installTarget  = $resolved
    } | ConvertTo-Json -Depth 3
    Set-Content -LiteralPath (Join-Path $destRoot '.merit-surface.json') -Value $marker -Encoding UTF8
    Write-Ok "Surface marker -> $(Join-Path $destRoot '.merit-surface.json')"
    if ($resolved -eq 'OpenClaw') {
        Write-Note 'Tip: openclaw skills install ./skills/<skill> for CLI single-skill installs.'
    }
    if ($resolved -eq 'Hermes') {
        Write-Note 'Tip: hermes skills tap add AgentDraven/merit-agent-skills for tap refresh.'
    }
    return $true
}

function Invoke-InstallSkillsMenu {
    Write-Header 'Install skills to AI host'
    Write-Info 'Same as repo install.ps1  -  built into Merit-Hub (no separate script needed).'
    Write-Host ''
    Write-Host '  1 Cursor   2 Claude Code   3 Codex   4 VS Code/Agents'
    Write-Host '  5 Hermes   6 OpenClaw      7 Grok    8 Devin'
    Write-Host '  9 Project (repo path prompt)'
    Write-Host ''
    $pick = (Read-Host 'Host').Trim()
    $target = switch ($pick) {
        { $_ -in @('1', 'Cursor', 'cursor') } { 'Cursor' }
        { $_ -in @('2', 'Claude', 'ClaudeCode') } { 'ClaudeCode' }
        { $_ -in @('3', 'Codex', 'codex') } { 'Codex' }
        { $_ -in @('4', 'VSCode', 'Agents', 'VS Code') } { 'VSCode' }
        { $_ -in @('5', 'Hermes', 'hermes') } { 'Hermes' }
        { $_ -in @('6', 'OpenClaw', 'openclaw') } { 'OpenClaw' }
        { $_ -in @('7', 'Grok', 'GrokBot') } { 'GrokBot' }
        { $_ -in @('8', 'Devin', 'devin') } { 'Devin' }
        { $_ -in @('9', 'Project', 'project') } { 'Project' }
        default { $null }
    }
    if (-not $target) {
        Write-Warn 'Cancelled or unknown host.'
        return
    }
    $projPath = ''
    if ($target -eq 'Project') {
        $projPath = Read-Host 'Repo root path'
    }
    [void](Invoke-InstallMeritSkills -Target $target -ProjectPath $projPath)
}

function Test-Winget { return $Script:HubOnWindows -and [bool](Get-Command winget -ErrorAction SilentlyContinue) }

function Install-WingetPkg {
    param([string]$Id, [string]$Name)
    if (-not (Test-Winget)) {
        Write-Fail "winget missing; install $Name manually"
        return $false
    }
    Write-Info "Installing $Name ($Id) ..."
    & winget install --id $Id -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Ok "$Name ok"
        return $true
    }
    Write-Fail "$Name failed (exit $LASTEXITCODE)"
    return $false
}

function Resolve-BasePythonExe {
    Refresh-ProcessPath
    foreach ($name in @('python', 'python3', 'py')) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if (-not $cmd) { continue }
        if ($name -eq 'py') {
            try {
                $viaPy = & py -3 -c "import sys; print(sys.executable)" 2>$null
                if ($viaPy -and (Test-Path -LiteralPath $viaPy.Trim())) { return $viaPy.Trim() }
            }
            catch { }
            continue
        }
        if ($cmd.Source -and (Test-Path -LiteralPath $cmd.Source) -and ($cmd.Source -notmatch 'WindowsApps')) {
            return $cmd.Source
        }
    }
    if ($Script:HubOnWindows) {
        foreach ($c in @(
                (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
                (Join-Path $env:ProgramFiles 'Python312\python.exe')
            )) {
            if ($c -and (Test-Path -LiteralPath $c)) { return $c }
        }
    }
    return $null
}

function Get-MeritVenvPython {
    $tools = Get-MyMeritToolsRoot
    if ($Script:HubOnWindows) { return Join-Path $tools 'merit-venv\Scripts\python.exe' }
    return Join-Path $tools 'merit-venv/bin/python3'
}

function Install-MeritToolsPython {
    $tools = Get-MyMeritToolsRoot
    Write-Header "Creating MERIT Python venv under MYMERITTOOLS ($tools)"
    $venvDir = Join-Path $tools 'merit-venv'
    $venvPy = if ($Script:HubOnWindows) { Join-Path $venvDir 'Scripts\python.exe' } else { Join-Path $venvDir 'bin/python3' }
    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    if (Test-Path -LiteralPath $venvPy) {
        Write-Ok "Already present: $venvPy"
        if ($Script:HubOnWindows) {
            Set-Content -LiteralPath (Join-Path $tools 'merit-python.cmd') -Value "@echo off`r`n`"$venvPy`" %*`r`n" -Encoding ASCII
        }
        return $true
    }
    $base = Resolve-BasePythonExe
    if (-not $base) {
        if ($Script:HubOnWindows) {
            if (-not (Install-WingetPkg -Id 'Python.Python.3.12' -Name 'Python 3.12')) { return $false }
        }
        else {
            Write-Fail 'Install python3 via your package manager, then re-run.'
            return $false
        }
        Refresh-ProcessPath
        $base = Resolve-BasePythonExe
        if (-not $base) {
            Write-Fail 'Python not on PATH - open a new terminal and re-run.'
            return $false
        }
    }
    Write-Ok "Base Python: $base"
    & $base -m venv $venvDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $venvPy)) {
        Write-Fail "venv create failed at $venvDir"
        return $false
    }
    if ($Script:HubOnWindows) {
        Set-Content -LiteralPath (Join-Path $tools 'merit-python.cmd') -Value "@echo off`r`n`"$venvPy`" %*`r`n" -Encoding ASCII
    }
    Write-Ok "MERIT laptop Python: $venvPy"
    return $true
}

function Invoke-MeritPrereqs {
    Write-Header 'Prerequisites - check tools, Python venv, and MYMERIT* env'
    $tools = Get-MyMeritToolsRoot
    $app = Get-MyMeritAppRoot
    $toolsUser = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'User')
    $appUser = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
    $needPersistTools = [string]::IsNullOrWhiteSpace($toolsUser)
    $needPersistApp = [string]::IsNullOrWhiteSpace($appUser)

    Write-Info '--- Environment (not the same as git/gh/pwsh) ---'
    Write-Ok "MYMERITTOOLS resolved = $tools"
    Write-Ok "MYMERITAPP    resolved = $app"
    if ($needPersistTools) { Write-Warn "MYMERITTOOLS User env - not persisted (will SET to $tools)" }
    else { Write-Ok "MYMERITTOOLS User env already set = $toolsUser" }
    if ($needPersistApp) { Write-Warn "MYMERITAPP User env - not persisted (will SET to $app)" }
    else { Write-Ok "MYMERITAPP User env already set = $appUser" }

    Write-Host ''
    Write-Info '--- Tools ---'
    $needGit = -not (Get-Command git -ErrorAction SilentlyContinue)
    $pwshExe = Resolve-MeritPwshExe
    $needPwsh = -not $pwshExe
    $needGh = $true
    $ghExe = $null
    if ($Script:HubOnWindows) {
        foreach ($c in @(
                (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'GitHub CLI\gh.exe')
            )) {
            if ($c -and (Test-Path -LiteralPath $c)) { $ghExe = $c; break }
        }
    }
    if (-not $ghExe) {
        $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
        $toolsGh = Join-Path (Get-MyMeritToolsRoot) 'gh'
        $isToolsShim = $ghCmd -and $ghCmd.Source -and (
            $ghCmd.Source.StartsWith($toolsGh, [StringComparison]::OrdinalIgnoreCase) -or
            $ghCmd.Source -match '(?i)[\\/]Tools[\\/]gh'
        )
        if ($ghCmd -and $ghCmd.Source -and -not $isToolsShim) {
            $ghExe = $ghCmd.Source
        }
    }
    if ($ghExe) { Write-Ok "gh - $ghExe"; $needGh = $false }
    else { Write-Warn 'gh - missing (optional; install for PRs / identity)' }

    if (-not $needGit) { Write-Ok ("Git - " + ((& git --version 2>&1 | Out-String).Trim())) }
    else { Write-Fail 'Git - missing' }
    if (-not $needPwsh) { Write-Ok "pwsh - $pwshExe" }
    else {
        Write-Warn 'pwsh - missing (hub runs on Windows PowerShell 5.1 for now; install pwsh for best experience)'
        Show-PwshInstallGuide
    }

    $venvPy = Get-MeritVenvPython
    $needPy = -not (Test-Path -LiteralPath $venvPy)
    $basePy = Resolve-BasePythonExe
    if (-not $needPy) {
        Write-Ok "MERIT Python venv - $venvPy"
    }
    else {
        Write-Warn "MERIT Python venv - MISSING at $venvPy"
        if ($basePy) {
            Write-Note "Base Python is present ($basePy). y will create the venv under MYMERITTOOLS (not a reinstall of Git/gh/pwsh)."
        }
        else {
            Write-Note 'Base Python is also missing. y will install Python 3.12 then create the venv under MYMERITTOOLS.'
        }
    }

    $missingTools = [System.Collections.Generic.List[string]]::new()
    if ($needGit) { $missingTools.Add('Git') }
    if ($needPwsh) { $missingTools.Add('pwsh (PowerShell 7+)') }
    if ($needGh) { $missingTools.Add('GitHub CLI (gh) - optional') }
    if ($needPy) { $missingTools.Add("MERIT Python venv ($venvPy)") }
    $needAnyTool = $needGit -or $needPwsh -or $needGh -or $needPy
    $needAnyEnv = $needPersistTools -or $needPersistApp

    if (-not $needAnyTool -and -not $needAnyEnv) {
        Write-Host ''
        Write-Ok 'Nothing missing. Tools and User env are already set.'
        return
    }

    Write-Host ''
    Write-Info '--- What y will do ---'
    if ($needAnyTool) {
        Write-Note 'Install / create:'
        foreach ($item in $missingTools) { Write-Info "    - $item" }
    }
    else {
        Write-Ok 'No packages to install (Git, gh, pwsh, and MERIT Python venv are present).'
    }
    if ($needAnyEnv) {
        Write-Note 'Set User environment variables:'
        if ($needPersistTools) { Write-Info "    - MYMERITTOOLS = $tools" }
        if ($needPersistApp) { Write-Info "    - MYMERITAPP = $app" }
    }

    if ($Force) {
        if ($needPersistTools) { Set-UserEnvVar -Name 'MYMERITTOOLS' -Value $tools }
        if ($needPersistApp) { Set-UserEnvVar -Name 'MYMERITAPP' -Value $app }
        if ($needGit) { [void](Install-WingetPkg -Id 'Git.Git' -Name 'Git') }
        if ($needPwsh) {
            if ($Script:HubOnWindows -and (Test-Winget)) {
                [void](Install-WingetPkg -Id 'Microsoft.PowerShell' -Name 'PowerShell 7+')
            }
            elseif ($Script:HubOnWindows) {
                [void](Install-MeritToolsPwshPortable)
            }
        }
        if ($needGh) { [void](Install-WingetPkg -Id 'GitHub.cli' -Name 'GitHub CLI') }
        if ($needPy) { [void](Install-MeritToolsPython) }
        return
    }

    $prompt = if ($needAnyTool -and $needAnyEnv) {
        'Install missing items and set User env listed above? [y/N]'
    }
    elseif ($needAnyTool) {
        'Install / create the missing items listed above? [y/N]'
    }
    else {
        'Set the User environment variables listed above? [y/N]'
    }
    $ans = Read-Host $prompt
    if ($ans -notmatch '^[Yy]') { Write-Warn 'Skipped.'; return }
    if ($needPersistTools) { Set-UserEnvVar -Name 'MYMERITTOOLS' -Value $tools }
    if ($needPersistApp) { Set-UserEnvVar -Name 'MYMERITAPP' -Value $app }
    if ($needGit) { [void](Install-WingetPkg -Id 'Git.Git' -Name 'Git') }
    if ($needPwsh) {
        if ($Script:HubOnWindows) {
            $how = Read-Host 'pwsh: [W]inget (Program Files) or [P]ortable to MYMERITTOOLS\pwsh [W/P/skip]'
            switch -Regex ($how) {
                '^[Pp]' { [void](Install-MeritToolsPwshPortable) }
                '^[Ww]' { [void](Install-WingetPkg -Id 'Microsoft.PowerShell' -Name 'PowerShell 7+') }
                default { Show-PwshInstallGuide }
            }
        }
        else {
            Show-PwshInstallGuide
        }
    }
    if ($needGh) { [void](Install-WingetPkg -Id 'GitHub.cli' -Name 'GitHub CLI') }
    if ($needPy) { [void](Install-MeritToolsPython) }
}

function Ensure-MeritHubEnvAtStart {
    if ($Force) { return }
    Write-Header 'MYMERIT* environment'
    Write-HubEnvScopes
    if (Test-HubProcessBenchMode) {
        Write-Note 'MERIT_HUB_NO_PERSIST_ENV=1 -- using Process MYMERIT* only (multi-creator bench). User env not written.'
        Write-Ok "MYMERITTOOLS resolved = $(Get-MyMeritToolsRoot)"
        Write-Ok "MYMERITAPP    resolved = $(Get-MyMeritAppRoot)"
        return
    }
    $toolsUser = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'User')
    $toolsProc = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'Process')
    if ([string]::IsNullOrWhiteSpace($toolsUser)) {
        $def = Get-DefaultMyMeritTools
        Write-Note 'MYMERITTOOLS User is empty (new laptop, or Pristine cleared it).'
        if ($toolsProc) { Write-Info "This process still has MYMERITTOOLS=$toolsProc (not persisted to User)." }
        Write-Info "Default: $def"
        $ans = Read-Host "MYMERITTOOLS path [$def]"
        $path = if ([string]::IsNullOrWhiteSpace($ans)) { $def } else { $ans }
        Set-UserEnvVar -Name 'MYMERITTOOLS' -Value (Expand-HomePath $path)
    }
    $appUser = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
    $appProc = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'Process')
    if ([string]::IsNullOrWhiteSpace($appUser)) {
        $def = Get-DefaultMyMeritApp
        Write-Note 'MYMERITAPP User is empty (new laptop, or Pristine cleared it).'
        if ($appProc) { Write-Info "This process still has MYMERITAPP=$appProc (not persisted to User)." }
        Write-Info "Default: $def"
        $ans = Read-Host "MYMERITAPP path [$def]"
        $path = if ([string]::IsNullOrWhiteSpace($ans)) { $def } else { $ans }
        Set-UserEnvVar -Name 'MYMERITAPP' -Value (Expand-HomePath $path)
    }
    [void](Import-HubOssHelpers)
}

function Ensure-MyMeritAppPrompt {
    $current = Get-MyMeritAppRoot
    $userSet = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
    if (-not [string]::IsNullOrWhiteSpace($userSet) -and -not $Force) {
        Write-Ok "MYMERITAPP = $current"
        return $current
    }
    Write-Note "OSS bench folder (skills + demo). Default: $(Get-DefaultMyMeritApp)"
    $ans = Read-Host "MYMERITAPP path [$current]"
    $path = if ([string]::IsNullOrWhiteSpace($ans)) { $current } else { $ans }
    $full = Expand-HomePath $path
    Set-UserEnvVar -Name 'MYMERITAPP' -Value $full
    return $full
}

function Invoke-GitClonePin {
    param(
        [string]$Url,
        [string]$Pin,
        [string]$Dest,
        [string]$Label
    )
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH - run Prereqs (menu 1) first.'
        return $false
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
    $gitDir = Join-Path $Dest '.git'
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok "$Label already cloned: $Dest"
        Write-Info "Fetching / checking out $Pin ..."
        & git -C $Dest fetch --tags origin 2>&1 | Out-Host
        & git -C $Dest checkout --detach "refs/tags/$Pin" 2>&1 | Out-Host
        if ($Dest -match '[\\/]merit-agent-skills$') { [void](Import-HubOssHelpers) }
        return ($LASTEXITCODE -eq 0)
    }
    if (Test-Path -LiteralPath $Dest) {
        Write-Fail "$Dest exists but is not a git clone - move aside and retry."
        return $false
    }
    Write-Info "Cloning $Url @ $Pin -> $Dest"
    & git clone --branch $Pin $Url $Dest
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "git clone failed (exit $LASTEXITCODE)"
        return $false
    }
    Write-Ok "Cloned $Label @ $Pin"
    if ($Dest -match '[\\/]merit-agent-skills$') { [void](Import-HubOssHelpers) }
    return $true
}

function Write-HubLegend {
    Write-Host ''
    Write-Host '  LEGEND  local letter = clone on this laptop; C suffix = that artifact hosted' -ForegroundColor White
    Write-Host '          OC  OSS demo on merit-prod (freeware DualRail) - not a product repo'
    Write-Host '          VC  operator/tenant grade after V (BootStrap / gates) - vault stays git+local, not merit-prod'
    Write-Host '          RC  this catalog repo on ITS host (usually Vercel) - not OC'
    Write-Host '          6   Join (sign up) - portal + register; after OC or after 4 (not OC-only)'
}

function Write-HubMap {
    param([string]$Here = '')
    $mark = {
        param([string]$Step, [string]$Text)
        if ($Here -and $Step -eq $Here) { return "* $Text" }
        return "  $Text"
    }
    Write-HubLegend
    Write-Host ''
    Write-Host '  MAP (always)   * = you are here' -ForegroundColor White
    Write-Host ('  ' + (& $mark '1' '1 Setup laptop'))
    Write-Host '         |'
    Write-Host '         v'
    Write-Host ('  ' + (& $mark '2' '2 Install OSS  (J)'))
    Write-Host '         |'
    Write-Host ('         +--> ' + (& $mark '3' '3 Try it') + ' --> ' + (& $mark 'OC' 'OC  OSS in the Cloud'))
    Write-Host ('         +--> ' + (& $mark '4' '4 V (local)') + ' --> ' + (& $mark 'VC' 'VC  Venture Capable'))
    Write-Host ('         +--> ' + (& $mark '5' '5 R (local, role C|P)') + ' --> ' + (& $mark 'RC' 'RC  repo in the Cloud'))
    Write-Host ('         +--> ' + (& $mark '6' '6 Join MERIT (sign up)  after OC or 4'))
    Write-Host '         +--> 0 Stop'
}

function Write-HubDrillIn {
    param([string]$Step)
    switch ($Step) {
        '1' { Write-Note 'Drill-in: git / gh / pwsh + MERIT Python venv under MYMERITTOOLS. Persist MYMERIT*. Not hosted.' }
        '2' { Write-Note 'Drill-in: clone skills pin + merit-demo; quiet smoke. Old D+G live here. Not cloud.' }
        '3' { Write-Note 'Drill-in: open local merit-demo\play\index.html. Still not hosted.' }
        'OC' { Write-Note 'Drill-in: publish play+cfg + portal/ marketing site to merit-prod; store activate MUST succeed. here.now is a platform-key upgrade (no laptop key).' }
        '4' { Write-Note 'Drill-in: clone private vault into ~/dev. Still local. Existing working clone is kept (no detach to Hub pin).' }
        'VC' { Write-Note 'Drill-in: operator grade after 4. BootStrap + gates + runtime. Vault stays private git - not hosted on merit-prod. Validate: git remote private, merit git verify, runtime verify.' }
        '5' { Write-Note 'Drill-in: clone a catalog consumer or provider repo to ~/dev/<GitHub user>/<folder>. Requires 4. Not OC.' }
        'R' { Write-Note 'Drill-in: same as 5 - local catalog clone. Pick role consumer|provider. First consumer: m4fi.' }
        'RC' { Write-Note 'Drill-in: deploy THAT repo to its production host (merit.ps1 deploy vercel). Not merit-prod DualRail (that is OC).' }
        '6' { Write-Note 'Drill-in: Join = sign up. Same key after OC (store register) or after 4 (operator/partner). Links only. Affiliate is ?affiliate= on register.' }
        default { }
    }
}

function Get-HubVaultDest {
    $cfg = Get-HubConfig
    $dev = Get-DevRoot
    $owner = [string]$cfg.vaultOwner
    if ([string]::IsNullOrWhiteSpace($owner)) { $owner = 'AgentDraven' }
    $repo = [string]$cfg.vaultRepo
    if ([string]::IsNullOrWhiteSpace($repo)) { $repo = 'merit-private-vault' }
    return Join-Path (Join-Path $dev $owner) $repo
}

function Write-HubReceipt {
    param([string]$Step)
    $tools = Get-MyMeritToolsRoot
    $bench = Get-MyMeritAppRoot
    $venv = Join-Path $tools 'merit-venv'
    $skills = Join-Path $bench 'merit-agent-skills'
    $demo = Join-Path $bench 'merit-demo'
    $status = Join-Path $bench 'oss-bench.json'
    $vault = Get-HubVaultDest
    Write-Host ''
    Write-Host "  RECEIPT - step $Step" -ForegroundColor Cyan
    switch ($Step) {
        '1' {
            Write-Info "Hub script : $Script:HubScriptPath"
            if (Test-Path -LiteralPath $venv) { Write-Ok "Tools venv : $venv" } else { Write-Warn "Tools venv missing: $venv" }
            Write-Info "Bench      : $bench"
            Write-Note 'Not hosted. Cloud starts at OC after Install OSS + Try it.'
        }
        '2' {
            if (Test-Path -LiteralPath (Join-Path $skills 'merit.ps1')) { Write-Ok "Skills : $skills" } else { Write-Warn "Skills missing: $skills" }
            if (Test-Path -LiteralPath (Join-Path $demo '.git')) { Write-Ok "Demo   : $demo" } else { Write-Warn "Demo missing: $demo" }
            Write-Info "Status : $status"
            Write-Note 'Not cloud. Folders on this laptop only.'
        }
        '3' {
            $play = Join-Path $demo 'play\index.html'
            if (Test-Path -LiteralPath $play) { Write-Ok "Local play: $play" } else { Write-Warn "Local play missing: $play (run 2 first)" }
            Write-Note 'Not hosted yet. OC puts this on merit-prod.'
        }
        'OC' {
            $state = $null
            if (Get-Command Get-OssState -ErrorAction SilentlyContinue) { $state = Get-OssState }
            $cid = ''
            try { $cid = [string]$state.ocConsumerId } catch { }
            $playUrl = ''
            try { $playUrl = [string]$state.ocPlayUrl } catch { }
            $regUrl = ''
            try { $regUrl = [string]$state.ocRegisterUrl } catch { }
            $hn = ''
            try { $hn = [string]$state.ocHereNowUrl } catch { }
            $portalUrl = ''
            try { $portalUrl = [string]$state.ocPortalUrl } catch { }
            $pname = ''
            try { $pname = [string]$state.ocProductName } catch { }
            if ($cid) { Write-Ok "consumer_id: $cid" } else { Write-Warn 'No OC consumer_id yet' }
            if ($pname) { Write-Info "product   : $pname" }
            $playLive = $false
            $portalLive = $false
            if ($playUrl -match '^https?://') {
                try {
                    $playHtml = [string](Invoke-WebRequest -Uri $playUrl -UseBasicParsing -TimeoutSec 45).Content
                    $playLive = ($playHtml -match 'createAppShell' -and $playHtml -match 'Register free' -and $playHtml -notmatch 'Play UI not published')
                } catch { $playLive = $false }
            }
            if ($portalUrl -match '^https?://') {
                try {
                    $siteHtml = [string](Invoke-WebRequest -Uri $portalUrl -Headers @{ Accept = 'text/html' } -UseBasicParsing -TimeoutSec 45).Content
                    $portalLive = ($siteHtml.Length -gt 300 -and $siteHtml -notmatch 'Play UI not published' -and $siteHtml -notmatch '"error"\s*:\s*"not_found"')
                } catch { $portalLive = $false }
            }
            if ($playUrl) {
                if ($playLive) { Write-Ok "play      : $playUrl" } else { Write-Fail "play      : $playUrl (not DualRail yet -- unpublished shell)"; $Script:HubStepFailed = $true }
            } else { Write-Warn 'play URL missing' }
            if ($regUrl) { Write-Ok "register  : $regUrl" } else { Write-Warn 'register URL missing (activate required)' }
            if ($portalUrl) {
                if ($portalLive) { Write-Ok "portal    : $portalUrl" } else { Write-Fail "portal    : $portalUrl (marketing site not live)"; $Script:HubStepFailed = $true }
            } else { Write-Warn 'marketing portal missing - OC publishes the demo portal/ tree' }
            if ($hn -match '^https?://') {
                Write-Ok "here.now  : $hn"
            } elseif ($hn) {
                Write-Note "here.now  : not published ($hn). Marketing portal above is MERIT-hosted; no laptop key was ever asked for."
            } else {
                Write-Note 'here.now  : not published (platform-key upgrade).'
            }
            Write-Note 'Subscribers get: guest play, journal/AMA shells, marketing portal, Community Member $0. Not Plus, not payouts, not vault.'
        }
        '4' {
            if (Test-Path -LiteralPath (Join-Path $vault '.git')) { Write-Ok "Vault (local): $vault" } else { Write-Warn "Vault not cloned: $vault" }
            Write-Note 'Still local. VC is operator grade (BootStrap/gates), not a hosted vault.'
        }
        'VC' {
            if (Test-Path -LiteralPath (Join-Path $vault '.git')) { Write-Ok "Vault local: $vault" } else { Write-Warn 'Run 4 first (clone vault).' }
            Write-Note 'OC = freeware Community Member on merit-prod. VC = operator/tenant grade. Vault is not published to merit-prod.'
        }
        '5' {
            Write-Note 'R = local catalog clone under ~/dev/<user>/<folder>. Run 4 first. Pick role consumer or provider.'
        }
        'R' {
            Write-Note 'R = local catalog clone. Next: RC for that repo host, or mXout from the clone.'
        }
        'RC' {
            Write-Note 'RC = this catalog repo on its Vercel/host. Not OC (OSS demo on merit-prod).'
        }
        '6' {
            Write-Info 'https://merit-prod.vercel.app/portal/'
            Write-Info 'https://merit-prod.vercel.app/portal/partners.html'
            Write-Info 'After OC: https://merit-prod.vercel.app/store/{your-oc-id}/register'
            Write-Note 'Join (sign up) after OC or after 4 - same key. Affiliate: ?affiliate= on register. Not a here.now slug.'
        }
    }
}

function Ensure-HubOssHelpers {
    $oss = Get-HubOssInternalScript
    if (-not (Test-Path -LiteralPath $oss)) {
        Write-Fail "Install OSS internals missing: $oss"
        Write-Note 'Run Hub 2 first so merit-agent-skills is cloned under MYMERITAPP.'
        return $false
    }
    if (-not (Import-HubOssHelpers)) {
        Write-Fail "OSS helpers did not load Get-OssState from $oss"
        return $false
    }
    return $true
}

function New-HubOcConsumerId {
    return ('oc-' + [guid]::NewGuid().ToString('n').Substring(0, 10))
}

function Invoke-HubSetupLaptop {
    Write-Header '1 Setup laptop'
    Write-HubMap -Here '1'
    Write-HubDrillIn '1'
    [void](Invoke-MeritPrereqs)
    Write-HubReceipt '1'
}

function Invoke-HubInstallOss {
    param([switch]$SkipPrereqs)
    $cfg = Get-HubConfig
    Write-Header "2 Install OSS @ $($cfg.skillsPin)"
    Write-HubMap -Here '2'
    Write-HubDrillIn '2'
    if (-not $SkipPrereqs) { [void](Invoke-MeritPrereqs) }
    $bench = Ensure-MyMeritAppPrompt
    $skillsDest = Join-Path $bench 'merit-agent-skills'
    $ok = Invoke-GitClonePin -Url ([string]$cfg.skillsUrl) -Pin ([string]$cfg.skillsPin) -Dest $skillsDest -Label 'merit-agent-skills'
    if (-not $ok) { return }

    if (-not $Force) {
        $ins = Read-Host 'Install MERIT skills to an AI host now? [y/N] (menu I later)'
        if ($ins -match '^[Yy]') {
            Invoke-InstallSkillsMenu
        }
    }

    if (-not (Ensure-HubOssHelpers)) { return }
    $env:MERIT_VERIFY_QUIET = '1'
    Invoke-OssEnsureDemo
    Invoke-OssValidate
    Write-HubReceipt '2'
}

function Invoke-HubTryIt {
    Write-Header '3 Try it'
    Write-HubMap -Here '3'
    Write-HubDrillIn '3'
    if (-not (Ensure-HubOssHelpers)) { return }
    if (-not (Test-HubDemoReady)) {
        Write-Fail 'merit-demo play missing (D). Run 2 Install OSS first.'
        Write-Note 'Hub 2 seeds merit-demo under MYMERITAPP.'
        Write-HubReceipt '3'
        return
    }
    $state = Get-OssState
    $play = Join-Path ([string]$state.demoFolder) 'play\index.html'
    if (-not (Test-Path -LiteralPath $play)) {
        Write-Fail "Local play missing: $play"
        Write-Note 'Run 2 Install OSS first.'
        Write-HubReceipt '3'
        return
    }
    Write-Ok "Opening $play"
    try { Start-Process $play } catch { Write-Warn "Could not open browser: $($_.Exception.Message)" }
    Write-HubReceipt '3'
}

function Invoke-HubOc {
    Write-Header 'OC  OSS in the Cloud'
    Write-HubMap -Here 'OC'
    Write-HubDrillIn 'OC'
    if (-not (Ensure-HubOssHelpers)) { return }
    if (-not (Test-HubDemoReady)) {
        Write-Fail 'merit-demo play missing (D). Run 2 Install OSS first.'
        Write-Note 'Hub 2 seeds merit-demo under MYMERITAPP.'
        Write-HubReceipt 'OC'
        return
    }
    $state = Get-OssState
    $cli = Join-Path ([string]$state.skillsFolder) 'merit.ps1'
    $demo = [string]$state.demoFolder
    if (-not (Test-Path -LiteralPath $cli)) {
        Write-Fail "merit.ps1 missing: $cli - run 2 first."
        return
    }
    if (-not (Test-Path -LiteralPath (Join-Path $demo 'play\index.html'))) {
        Write-Fail "Demo play missing under $demo - run 2 then 3."
        return
    }
    $cid = ''
    try { $cid = [string]$state.ocConsumerId } catch { }
    if ($NewOc -or [string]::IsNullOrWhiteSpace($cid) -or $cid -notmatch '^oc-') {
        $cid = New-HubOcConsumerId
        if ($NewOc) { Write-Note " -NewOc: minting $cid (not reusing oss-bench.json)" }
    }
    $defaultName = 'My DualRail app'
    try {
        $bp = Join-Path $demo 'cfg\branding.json'
        if (Test-Path -LiteralPath $bp) {
            $b = Get-Content -LiteralPath $bp -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($b.product_name -and [string]$b.product_name -ne 'MERIT Demo') {
                $defaultName = [string]$b.product_name
            }
        }
    } catch { }
    $pname = [string]$env:MERIT_OC_PRODUCT_NAME
    if ([string]::IsNullOrWhiteSpace($pname)) {
        try { $pname = [string]$state.ocProductName } catch { $pname = '' }
    }
    if ([string]::IsNullOrWhiteSpace($pname)) {
        if ($env:MERIT_HUB_NO_ELEVATE -eq '1') {
            $pname = $defaultName
        } else {
            $ans = Read-Host "Product name (your DualRail face) [$defaultName]"
            $pname = if ([string]::IsNullOrWhiteSpace($ans)) { $defaultName } else { $ans.Trim() }
        }
    }
    Write-Info "consumer_id: $cid"
    Write-Info "product:     $pname"
    $runner = Get-OssRunner
    $env:MERIT_VERIFY_QUIET = '1'
    $ocLines = & $runner.Exe -NoProfile -File $cli 'oc' '--path' $demo '--consumer-id' $cid '--product-name' $pname 6>&1
    foreach ($line in @($ocLines)) {
        $text = [string]$line
        if ($text.Trim()) { Write-Host $text }
    }
    if ($LASTEXITCODE -ne 0) {
        $Script:HubStepFailed = $true
        Write-Fail "OC failed (exit $LASTEXITCODE). Play publish, store activate, and the marketing portal are all required; play-only is not OC-done."
        Write-HubReceipt 'OC'
        return
    }
    $gw = 'https://merit-prod.vercel.app'
    $state.ocConsumerId = $cid
    $state.ocProductName = $pname
    $state.ocPlayUrl = "$gw/apps/$cid/play"
    $state.ocRegisterUrl = "$gw/store/$cid/register"
    $state.ocPortalUrl = "$gw/apps/$cid/play/site"
    $state.ocHereNowUrl = ''
    # Scalar, not array: -match on an array filters and never fills $Matches.
    $receiptLine = [string](@($ocLines | ForEach-Object { "$_" } | Where-Object { $_ -match 'OC_RECEIPT ' } | Select-Object -Last 1))
    if ($receiptLine) {
        if ($receiptLine -match 'play=(\S+)') { $state.ocPlayUrl = $Matches[1] }
        if ($receiptLine -match 'register=(\S+)') { $state.ocRegisterUrl = $Matches[1] }
        if ($receiptLine -match 'portal=(\S+)') { $state.ocPortalUrl = $Matches[1] }
        if ($receiptLine -match 'herenow=(\S+)') { $state.ocHereNowUrl = $Matches[1] }
    } else {
        Write-Warn 'OC receipt line not captured from merit.ps1 - URLs below are the expected shapes, not confirmed output.'
    }
    Save-OssState $state
    Write-HubReceipt 'OC'
}

function Get-HubCatalogRows {
    $vault = Get-HubVaultDest
    $cfgPath = Join-Path $vault 'cfg\merit-config.json'
    if (-not (Test-Path -LiteralPath $cfgPath)) {
        Write-Fail "Vault catalog missing: $cfgPath"
        Write-Note 'Run 4 first so the private vault is on this laptop.'
        return @()
    }
    $cfg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $projects = $cfg.catalog.projects
    $acronyms = $cfg.catalog.repo_acronyms.projects
    $rows = @()
    foreach ($prop in $projects.PSObject.Properties) {
        $id = [string]$prop.Name
        $row = $prop.Value
        $status = ''
        if ($row.PSObject.Properties['lifecycle_status']) { $status = [string]$row.lifecycle_status }
        if ($status -eq 'archived') { continue }
        $explicitRole = ''
        if ($row.PSObject.Properties['role']) { $explicitRole = [string]$row.role }
        if ($explicitRole -eq 'pristine_mirror') { continue }
        $profile = ''
        if ($row.PSObject.Properties['conformance_profile']) { $profile = [string]$row.conformance_profile }
        $hubRole = ''
        if ($profile -match 'provider') { $hubRole = 'provider' }
        elseif ($profile -match 'consumer') { $hubRole = 'consumer' }
        else { continue }
        $folder = $id
        if ($row.PSObject.Properties['folder'] -and $row.folder) { $folder = [string]$row.folder }
        $github = ''
        $acro = $acronyms.PSObject.Properties[$id]
        if ($acro -and $acro.Value.github) {
            $github = [string]$acro.Value.github
        }
        if ([string]::IsNullOrWhiteSpace($github)) {
            if ($id -in @('merit-demo', 'merit-test')) {
                $github = "Mr-PI-Bala/$folder"
            }
            else {
                $github = "AgentDraven/$folder"
            }
        }
        $owner, $repo = $github.Split('/', 2)
        if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($repo)) { continue }
        $dest = Join-Path (Join-Path (Get-DevRoot) $owner) $folder
        $rows += [pscustomobject]@{
            Id       = $id
            Role     = $hubRole
            Folder   = $folder
            Owner    = $owner
            Repo     = $repo
            Github   = $github
            Dest     = $dest
            Cloned   = (Test-Path -LiteralPath (Join-Path $dest '.git'))
        }
    }
    return $rows
}

function Show-HubCatalogPicker {
    param(
        [string]$WantRole,
        [object[]]$Rows
    )
    $i = 1
    foreach ($row in $Rows) {
        $mark = if ($row.Cloned) { 'cloned' } else { 'missing' }
        Write-Host ("    {0,2}. {1,-16} {2,-10} {3,-28} [{4}]" -f $i, $row.Id, $row.Role, $row.Github, $mark)
        $i++
    }
    if ($WantRole -eq 'consumer') {
        Write-Note 'First consumer on this laptop: m4fi (type m4fi or its number).'
    }
}

function Invoke-HubCloneCatalogRow {
    param($Row)
    if (-not $Row) { return $false }
    if ($Row.Cloned) {
        Write-Ok ("Already cloned: {0}" -f $Row.Dest)
        return $true
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH - run 1 first.'
        return $false
    }
    $parent = Split-Path -Parent $Row.Dest
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if ((Test-Path -LiteralPath $Row.Dest) -and -not (Test-Path -LiteralPath (Join-Path $Row.Dest '.git'))) {
        $items = @(Get-ChildItem -LiteralPath $Row.Dest -Force -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) {
            Write-Fail ("{0} exists but is not a git clone - move aside and retry." -f $Row.Dest)
            return $false
        }
        Write-Note ("Empty placeholder OK: {0}" -f $Row.Dest)
    }
    $url = "https://github.com/$($Row.Github).git"
    Write-Info "Cloning $url -> $($Row.Dest)"
    & git clone $url $Row.Dest
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "git clone failed (exit $LASTEXITCODE). Sign in as $($Row.Owner) (GCM) and retry."
        return $false
    }
    Write-Ok ("Cloned {0} -> {1}" -f $Row.Id, $Row.Dest)
    Write-Note "Day-to-day: cd $($Row.Dest) then .\\scripts\\merit.ps1 mXout"
    return $true
}

function Invoke-HubR {
    Write-Header '5 R  catalog repo (local)'
    Write-HubMap -Here '5'
    Write-HubDrillIn '5'
    $vault = Get-HubVaultDest
    if (-not (Test-Path -LiteralPath (Join-Path $vault '.git'))) {
        Write-Fail 'Vault not cloned yet. Run 4 first (still local).'
        Write-HubReceipt '5'
        return
    }
    $rows = @(Get-HubCatalogRows)
    if ($rows.Count -eq 0) { Write-HubReceipt '5'; return }

    $wantRole = $Role
    if ([string]::IsNullOrWhiteSpace($wantRole)) {
        if ($Force -and $CatalogProject) {
            $hit = $rows | Where-Object { $_.Id -eq $CatalogProject } | Select-Object -First 1
            if ($hit) { $wantRole = [string]$hit.Role }
        }
        if ([string]::IsNullOrWhiteSpace($wantRole) -and -not $Force) {
            $ans = Read-Host 'Role [C]onsumer / [P]rovider (default C)'
            if ($ans -match '^[Pp]') { $wantRole = 'provider' } else { $wantRole = 'consumer' }
        }
        if ([string]::IsNullOrWhiteSpace($wantRole)) { $wantRole = 'consumer' }
    }
    $filtered = @($rows | Where-Object { $_.Role -eq $wantRole })
    if ($filtered.Count -eq 0) {
        Write-Fail "No $wantRole catalog repos found."
        Write-HubReceipt '5'
        return
    }
    Write-Info "Role: $wantRole"
    Show-HubCatalogPicker -WantRole $wantRole -Rows $filtered

    $pick = $CatalogProject
    if ([string]::IsNullOrWhiteSpace($pick) -and -not $Force) {
        $pick = Read-Host 'Project id or number (consumer default: m4fi)'
    }
    if ([string]::IsNullOrWhiteSpace($pick) -and $wantRole -eq 'consumer') { $pick = 'm4fi' }
    $row = $null
    if ($pick -match '^\d+$') {
        $idx = [int]$pick
        if ($idx -ge 1 -and $idx -le $filtered.Count) { $row = $filtered[$idx - 1] }
    }
    else {
        $row = $filtered | Where-Object { $_.Id -eq $pick } | Select-Object -First 1
    }
    if (-not $row) {
        Write-Fail "Unknown catalog pick: $pick"
        Write-HubReceipt '5'
        return
    }
    $ok = Invoke-HubCloneCatalogRow -Row $row
    $script:HubLastCatalogRow = $row
    Write-HubReceipt 'R'
    if ($ok) {
        Write-Ok ("R local: {0}" -f $row.Dest)
        if (-not $Force) {
            $next = Read-Host 'Run RC (deploy this repo to its host) now? [y/N]'
            if ($next -match '^[Yy]') { Invoke-HubRc }
        }
    }
}

function Invoke-HubRc {
    Write-Header 'RC  catalog repo in the Cloud'
    Write-HubMap -Here 'RC'
    Write-HubDrillIn 'RC'
    $vault = Get-HubVaultDest
    if (-not (Test-Path -LiteralPath (Join-Path $vault '.git'))) {
        Write-Fail 'Vault not cloned yet. Run 4 then 5 R first.'
        Write-HubReceipt 'RC'
        return
    }
    $row = $null
    if ($script:HubLastCatalogRow) { $row = $script:HubLastCatalogRow }
    $rows = @(Get-HubCatalogRows)
    $pick = $CatalogProject
    if (-not $row -and $pick) {
        $row = $rows | Where-Object { $_.Id -eq $pick } | Select-Object -First 1
    }
    if (-not $row -and -not $Force) {
        $wantRole = $Role
        if ([string]::IsNullOrWhiteSpace($wantRole)) { $wantRole = 'consumer' }
        $filtered = @($rows | Where-Object { $_.Role -eq $wantRole -and $_.Cloned })
        if ($filtered.Count -eq 0) {
            Write-Fail "No cloned $wantRole repos. Run 5 R first."
            Write-HubReceipt 'RC'
            return
        }
        Show-HubCatalogPicker -WantRole $wantRole -Rows $filtered
        $ans = Read-Host 'Project id or number to deploy'
        if ($ans -match '^\d+$') {
            $idx = [int]$ans
            if ($idx -ge 1 -and $idx -le $filtered.Count) { $row = $filtered[$idx - 1] }
        }
        else {
            $row = $filtered | Where-Object { $_.Id -eq $ans } | Select-Object -First 1
        }
    }
    if (-not $row) {
        Write-Fail 'RC needs a catalog project. Pass -CatalogProject m4fi or run 5 R first.'
        Write-HubReceipt 'RC'
        return
    }
    if (-not $row.Cloned) {
        Write-Fail ("Not cloned yet: {0}. Run 5 R first." -f $row.Dest)
        Write-HubReceipt 'RC'
        return
    }
    Write-Ok ("R local: {0}" -f $row.Dest)
    Write-Note 'RC = this repo on its host (Vercel). OC is the OSS demo on merit-prod - different product.'
    $merit = Join-Path $vault 'scripts\merit.ps1'
    Write-Info "From $($row.Dest):"
    Write-Info "  & `"$merit`" deploy vercel -Project $($row.Id)"
    Write-HubReceipt 'RC'
    if ($Force) { return }
    $go = Read-Host "Run deploy vercel -Project $($row.Id) now? [y/N]"
    if ($go -notmatch '^[Yy]') {
        Write-Note 'Skipped deploy. Repo is local; RC when you are ready.'
        return
    }
    $prevCwd = $env:MERIT_OPERATOR_CWD
    $env:MERIT_OPERATOR_CWD = $row.Dest
    Push-Location $row.Dest
    try {
        & $merit deploy vercel -Project $row.Id
    }
    finally {
        Pop-Location
        if ($null -eq $prevCwd -or $prevCwd -eq '') { Remove-Item Env:MERIT_OPERATOR_CWD -ErrorAction SilentlyContinue }
        else { $env:MERIT_OPERATOR_CWD = $prevCwd }
    }
}

function Invoke-HubJoinMerit {
    Write-Header '6 Join MERIT'
    Write-HubMap -Here '6'
    Write-HubDrillIn '6'
    Write-HubReceipt '6'
    $portal = 'https://merit-prod.vercel.app/portal/'
    try { Start-Process $portal } catch { Write-Warn "Could not open $portal" }
}

function Invoke-HubVc {
    Write-Header 'VC  Venture Capable'
    Write-HubMap -Here 'VC'
    Write-HubDrillIn 'VC'
    $vault = Get-HubVaultDest
    if (-not (Test-Path -LiteralPath (Join-Path $vault '.git'))) {
        Write-Fail 'Vault not cloned yet. Run 4 first (still local).'
        Write-HubReceipt 'VC'
        return
    }
    Write-HubReceipt 'VC'
    Write-Note 'OC is freeware on merit-prod (Community Member). VC is the operator path.'
    $launch = Read-Host 'Launch vault operator BootStrap now? [y/N]'
    if ($launch -match '^[Yy]') {
        Invoke-JumpstartVault
    }
}

function Invoke-JumpstartOss {
    Invoke-HubInstallOss
}

function Enter-HubOssPhase {
    param([switch]$Chain)
    Remove-RetiredOssLiveBootStrap
    Invoke-HubInstallOss -SkipPrereqs:$false
}

function Invoke-JumpstartVault {
    $cfg = Get-HubConfig
    Write-Header "4 V (local) @ $($cfg.vaultPin)"
    Write-HubMap -Here '4'
    Write-HubDrillIn '4'
    [void](Invoke-MeritPrereqs)
    $vaultDest = Get-HubVaultDest
    $gitDir = Join-Path $vaultDest '.git'
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok "Vault already cloned (working copy preserved): $vaultDest"
        Write-Note 'Cold-start pin is only for a missing clone. Hub will not detach this checkout to vaultPin.'
        Write-HubReceipt '4'
        if ($Force) { return }
        $go = Read-Host 'Launch vault BootStrap now? [y/N] (needed before VC operator menus)'
        if ($go -notmatch '^[Yy]') {
            Write-Note 'Vault is local. Run VC when you want operator grade (BootStrap).'
            return
        }
        $seedCmd = Join-Path $vaultDest 'BootStrap\seed-private-dev.cmd'
        $bootCmd = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.cmd'
        $bootPs1 = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.ps1'
        if (Test-Path -LiteralPath $seedCmd) { Write-Ok 'Launching seed-private-dev.cmd ...'; & $seedCmd; return }
        if (Test-Path -LiteralPath $bootCmd) { Write-Ok 'Launching vault MERIT_BootStrap.cmd ...'; & $bootCmd; return }
        if (Test-Path -LiteralPath $bootPs1) { Write-Ok 'Launching vault MERIT_BootStrap.ps1 ...'; & $bootPs1; return }
        Write-Fail 'Vault BootStrap not found on this clone.'
        return
    }

    $ok = Invoke-GitClonePin -Url ([string]$cfg.vaultUrl) -Pin ([string]$cfg.vaultPin) -Dest $vaultDest -Label 'merit-private-vault'
    if (-not $ok) { return }
    if (Get-Command Save-OssState -ErrorAction SilentlyContinue) {
        $st = Get-OssState
        $st.vaultFolder = $vaultDest
        Save-OssState $st
    }

    Write-HubReceipt '4'
    if ($Force) { return }
    $seedCmd = Join-Path $vaultDest 'BootStrap\seed-private-dev.cmd'
    $bootCmd = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.cmd'
    $bootPs1 = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.ps1'
    $go = Read-Host 'Launch vault BootStrap now? [y/N] (needed before VC operator menus)'
    if ($go -notmatch '^[Yy]') {
        Write-Note 'Vault is local. Run VC when you want operator grade (BootStrap).'
        return
    }
    if (Test-Path -LiteralPath $seedCmd) {
        Write-Ok 'Launching seed-private-dev.cmd ...'
        & $seedCmd
        return
    }
    if (Test-Path -LiteralPath $bootCmd) {
        Write-Ok 'Launching vault MERIT_BootStrap.cmd ...'
        & $bootCmd
        return
    }
    if (Test-Path -LiteralPath $bootPs1) {
        Write-Ok 'Launching vault MERIT_BootStrap.ps1 ...'
        & $bootPs1
        return
    }
    Write-Fail 'Vault BootStrap not found on pinned tag.'
}

function Show-MeritHubHelp {
    $cfg = Get-HubConfig
    Write-Header 'Merit-Hub'
    Write-Info "Location: $Script:HubScriptPath"
    Write-Info "Elevated: $(Test-HubAdmin)"
    Write-HubEnvScopes
    Write-Info "Resolved MYMERITTOOLS=$(Get-MyMeritToolsRoot)  MYMERITAPP=$(Get-MyMeritAppRoot)"
    Write-Info "Pins: skills=$($cfg.skillsPin)  vault=$($cfg.vaultPin)"
    Write-Info "History log (append): $Script:HistoryLog"
    Write-HubMap
    Write-Host ''
    Write-Host '  KEYS' -ForegroundColor White
    Write-Host '  1) Setup laptop     prereqs + MYMERIT* + merit-venv'
    Write-Host '  2) Install OSS      skills pin + merit-demo + quiet smoke   (alias J)'
    Write-Host '  3) Try it           open local play/index.html'
    Write-Host '  OC) OSS in the Cloud  DualRail play + register + your marketing site'
    Write-Host '      -NewOc with -Oc mints a new oc-* id (second creator on this bench)'
    Write-Host '  4) V (local)        clone private vault (working clone kept) (alias V)'
    Write-Host '  VC) Venture Capable operator/tenant grade vs freeware OC (not hosted vault)'
    Write-Host '  5) R (local)        catalog clone; role consumer|provider   (alias R)'
    Write-Host '  RC) repo in Cloud   that repo on its host (Vercel) - not OC'
    Write-Host '  6) Join MERIT (sign up)  after OC or after 4; portal + register'
    Write-Host '  0) Stop'
    Write-Host ''
    Write-Host '  ALSO' -ForegroundColor White
    Write-Host '  P) Pristine v2   full cold-start wipe'
    Write-Host '  S) Soft          bench + status; keep ~/dev clones'
    Write-Host '  B) Backup only'
    Write-Host '  I) Install skills   Cursor, Codex, Hermes, ...'
    Write-Host '  M) Set MYMERITAPP bench path'
    Write-Host '  T) Set MYMERITTOOLS root'
    Write-Host '  W) Where / Surface   A+B+C+D+H diagnostic map'
    Write-Host '  H) Help'
    Write-Host ''
    Write-Note 'Cold start: 1 then 2. 6 Join (sign up) after OC or after 4. Do not double-click this file.'
}

function Set-MyMeritToolsPrompt {
    $current = Get-MyMeritToolsRoot
    Write-Note "Laptop tools root (merit-venv, shims). Default: $(Get-DefaultMyMeritTools)"
    $ans = Read-Host "MYMERITTOOLS path [$current]"
    $path = if ([string]::IsNullOrWhiteSpace($ans)) { $current } else { $ans }
    Set-UserEnvVar -Name 'MYMERITTOOLS' -Value (Expand-HomePath $path)
}

function Show-InteractiveMenu {
    Ensure-MeritHubEnvAtStart
    Remove-RetiredOssLiveBootStrap
    Write-MeritSurfaceReceipt
    while ($true) {
        Show-MeritHubHelp
        Write-Host '  Recommended cold start:  1 then 2' -ForegroundColor Yellow
        Write-Host ''
        $c = (Read-Host 'Select').Trim()
        switch -Regex ($c) {
            '^(P|p|Pristine)$' { Invoke-Mode -Mode Pristine; return }
            '^(S|s|Soft)$' { Invoke-Mode -Mode Soft; return }
            '^(B|b|BackupOnly)$' { Invoke-Mode -Mode BackupOnly; return }
            '^1$' { Invoke-HubSetupLaptop; Read-Host 'Press Enter' | Out-Null }
            '^(2|J|j|Jumpstart|Oss)$' { Invoke-HubInstallOss }
            '^3$' { Invoke-HubTryIt; Read-Host 'Press Enter' | Out-Null }
            '^(OC|oc|Oc)$' { Invoke-HubOc; Read-Host 'Press Enter' | Out-Null }
            '^(4|V|v|Vault)$' { Invoke-JumpstartVault }
            '^(VC|vc|Vc)$' { Invoke-HubVc; Read-Host 'Press Enter' | Out-Null }
            '^(5|R)$' { Invoke-HubR; Read-Host 'Press Enter' | Out-Null }
            '^(RC|rc|Rc)$' { Invoke-HubRc; Read-Host 'Press Enter' | Out-Null }
            '^6$' { Invoke-HubJoinMerit; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('I', 'i', 'Install', 'InstallSkills') } { Invoke-InstallSkillsMenu; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('M', 'm') } { Ensure-MyMeritAppPrompt | Out-Null; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('T', 't') } { Set-MyMeritToolsPrompt; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('W', 'w', 'Where', 'Surface') } { Invoke-HubSurface; Read-Host 'Press Enter' | Out-Null }
            '^(H|h|\?|Help)$' { continue }
            '^(0|Q|q|Exit)$' { Write-Info 'Bye.'; return }
            default { Write-Warn 'Unknown - choose 1, 2, 3, OC, 4, VC, 5, R, RC, 6, 0 (or P S B I M T W H).' }
        }
    }
}

# --- main ---
Ensure-HubPwshHost
if ($Help) {
    Show-MeritHubHelp
    return
}
Ensure-HubElevated
Sync-HubMeritEnvFromUser
[void](Import-HubMeritResolve)
[void](Import-HubOssHelpers)
New-Item -ItemType Directory -Force -Path $Script:BackupRoot | Out-Null
Start-HubTranscript
try {
    if ($Pristine) { Invoke-Mode -Mode Pristine; return }
    if ($Soft) { Invoke-Mode -Mode Soft; return }
    if ($BackupOnly) { Invoke-Mode -Mode BackupOnly; return }
    if ($Surface) { Invoke-HubSurface; return }
    if ($Prereqs) { Invoke-HubSetupLaptop; return }
    if ($InstallSkills) {
        [void](Invoke-InstallMeritSkills -Target $InstallSkills -ProjectPath $InstallSkillsPath)
        return
    }
    if ($OssPhase -or $InstallOss) { Invoke-HubInstallOss; return }
    if ($TryIt) { Invoke-HubTryIt; return }
    if ($Oc -or $NewOc) { Invoke-HubOc; if ($Script:HubStepFailed) { exit 1 }; return }
    if ($Vc) { Invoke-HubVc; return }
    if ($R) { Invoke-HubR; return }
    if ($Rc) { Invoke-HubRc; return }
    if ($JoinMerit) { Invoke-HubJoinMerit; return }
    if ($Jumpstart -eq 'Oss') { Invoke-HubInstallOss; return }
    if ($Jumpstart -eq 'Vault') { Invoke-JumpstartVault; return }

    $bound = $PSBoundParameters.Keys
    $hasAction = @('Pristine', 'Soft', 'BackupOnly', 'Prereqs', 'Jumpstart', 'InstallSkills', 'Help', 'OssPhase', 'InstallOss', 'TryIt', 'Oc', 'NewOc', 'Vc', 'R', 'Rc', 'JoinMerit', 'Surface') | Where-Object { $bound -contains $_ }
    if (-not $hasAction) {
        Show-InteractiveMenu
    }
}
finally {
    Complete-HubSession
}

