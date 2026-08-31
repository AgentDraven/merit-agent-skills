# Merit Surface resolver — OSS / IDE skills / vault discovery.
# Dot-source from merit.ps1, _oss.ps1, or Merit-Hub.ps1 (when B exists).
#Requires -Version 5.1

if (-not $Script:MeritResolveLoaded) {
    $Script:MeritResolveLoaded = $true
}

function Expand-MeritPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $p = $Path.Trim()
  if ($p -match '^%([A-Za-z_][A-Za-z0-9_]*)%\\?(.*)$') {
        $varName = $Matches[1]
        $rest = $Matches[2]
        $val = [Environment]::GetEnvironmentVariable($varName, 'Process')
        if ([string]::IsNullOrWhiteSpace($val)) {
            $val = [Environment]::GetEnvironmentVariable($varName, 'User')
        }
        if ([string]::IsNullOrWhiteSpace($val)) {
            $val = [Environment]::GetEnvironmentVariable($varName, 'Machine')
        }
        if ([string]::IsNullOrWhiteSpace($val)) { return $null }
        $p = if ($rest) { Join-Path $val $rest } else { $val }
    }
    if ($p.StartsWith('~/') -or $p -eq '~') {
        $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        if (-not $homeRoot) { return $null }
        $p = Join-Path $homeRoot ($p.TrimStart([char[]]@('~', '/', '\')))
    }
    try { return [IO.Path]::GetFullPath($p) }
    catch { return $null }
}

function Get-MeritEnvScoped {
    param([string]$Name)
    foreach ($scope in @('Process', 'User', 'Machine')) {
        $v = [Environment]::GetEnvironmentVariable($Name, $scope)
        if (-not [string]::IsNullOrWhiteSpace($v)) { return Expand-MeritPath $v }
    }
    return $null
}

function Get-MeritResolveConfigRoot {
    if ($Script:MeritResolveRepoRoot -and (Test-Path -LiteralPath (Join-Path $Script:MeritResolveRepoRoot 'cfg\merit_surface.json'))) {
        return $Script:MeritResolveRepoRoot
    }
    $here = $PSScriptRoot
    if ($here -match '[\\/]BootStrap$') {
        $root = Split-Path -Parent $here
        if (Test-Path -LiteralPath (Join-Path $root 'cfg\merit_surface.json')) { return $root }
    }
    $cwd = (Get-Location).Path
    if (Test-Path -LiteralPath (Join-Path $cwd 'cfg\merit_surface.json')) { return $cwd }
    return $null
}

function Get-MeritSurfaceConfig {
    $root = Get-MeritResolveConfigRoot
    if (-not $root) { return $null }
    $path = Join-Path $root 'cfg\merit_surface.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Test-MeritSkillsRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $full = Expand-MeritPath $Path
    if (-not $full) { return $false }
    $cli = Join-Path $full 'merit.ps1'
    $skills = Join-Path $full 'skills'
    return ((Test-Path -LiteralPath $cli) -and (Test-Path -LiteralPath $skills))
}

function Test-MeritVaultRoot {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $full = Expand-MeritPath $Path
    if (-not $full) { return $false }
    return (Test-Path -LiteralPath (Join-Path $full 'scripts\merit.ps1'))
}

function Get-MeritOssBenchPath {
    $bench = Get-MeritEnvScoped -Name 'MYMERITAPP'
    if (-not $bench) {
        $cfg = Get-MeritSurfaceConfig
        $bench = if ($env:OS -match 'Windows') { 'C:\MyMeritApp' } else { (Join-Path $HOME 'MyMeritApp') }
    }
    return Join-Path $bench 'oss-bench.json'
}

function Read-MeritOssBenchJson {
    $path = Get-MeritOssBenchPath
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try {
        return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch { return $null }
}

function Initialize-OssBenchJson {
    param(
        [string]$SkillsFolder,
        [string]$BenchFolder,
        [switch]$NoWrite
    )
    if ($NoWrite) { return $null }
    $bench = if ($BenchFolder) { Expand-MeritPath $BenchFolder } else { Get-MeritEnvScoped -Name 'MYMERITAPP' }
    if (-not $bench) { return $null }
    $jsonPath = Join-Path $bench 'oss-bench.json'
    if (Test-Path -LiteralPath $jsonPath) { return $jsonPath }
    $tpl = Join-Path (Get-MeritResolveConfigRoot) 'BootStrap\oss-bench.json'
    if (-not (Test-Path -LiteralPath $tpl)) { return $null }
    New-Item -ItemType Directory -Force -Path $bench | Out-Null
    $content = Get-Content -LiteralPath $tpl -Raw -Encoding UTF8
    $obj = $content | ConvertFrom-Json
    $obj.schemaVersion = 3
    $obj.benchFolder = $bench
    $obj.skillsFolder = if ($SkillsFolder) { Expand-MeritPath $SkillsFolder } else { Join-Path $bench 'merit-agent-skills' }
    $obj.demoFolder = Join-Path $bench 'merit-demo'
    $obj.updatedAt = (Get-Date).ToString('o')
    if ($Script:MeritResolveHubScript) { $obj.hubScript = $Script:MeritResolveHubScript }
    ($obj | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $jsonPath -Encoding UTF8
    return $jsonPath
}

function Get-MeritIdeHosts {
    $cfgPath = Join-Path (Get-MeritResolveConfigRoot) 'cfg\agent_hosts.json'
    $hosts = @()
    $staleMarker = $false
    if (-not (Test-Path -LiteralPath $cfgPath)) { return @{ Hosts = @(); StaleMarker = $false } }
    try {
        $reg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
        foreach ($h in @($reg.hosts)) {
            if ([string]$h.status -ne 'supported') { continue }
            $destTpl = if ($env:OS -match 'Windows') { [string]$h.destSkills.windows } else { [string]$h.destSkills.posix }
            if ($destTpl -match '<repo>') { continue }
            $dest = $destTpl -replace '%USERPROFILE%', $homeRoot -replace '%CODEX_HOME%', $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeRoot '.codex' })
            $dest = $dest -replace ' or .*', ''
            $dest = $dest.Split(' ')[0].Trim()
            if ($dest.StartsWith('~/')) { $dest = Join-Path $homeRoot ($dest.TrimStart([char[]]@('~', '/', '\'))) }
            if (-not (Test-Path -LiteralPath $dest)) { continue }
            $meritDirs = @(Get-ChildItem -LiteralPath $dest -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'merit-*' })
            if ($meritDirs.Count -lt 1) { continue }
            $hosts += [string]$h.id
            $marker = Join-Path $dest '.merit-surface.json'
            if ((Test-Path -LiteralPath $marker)) {
                try {
                    $m = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($m.skillsRepoRoot -and -not (Test-MeritSkillsRoot ([string]$m.skillsRepoRoot))) {
                        $staleMarker = $true
                    }
                }
                catch { }
            }
        }
    }
    catch { }
    return @{ Hosts = $hosts; StaleMarker = $staleMarker }
}

function Resolve-MeritSkillsRepoRoot {
  param([switch]$AllowIdeMarker)
    $resolvedFrom = $null
    $candidates = [System.Collections.Generic.List[string]]::new()

    if ($env:MERIT_SKILLS_ROOT) { [void]$candidates.Add($env:MERIT_SKILLS_ROOT) }

    $bench = Read-MeritOssBenchJson
    if ($bench -and $bench.skillsFolder) { [void]$candidates.Add([string]$bench.skillsFolder) }

    $app = Get-MeritEnvScoped -Name 'MYMERITAPP'
    if ($app) { [void]$candidates.Add((Join-Path $app 'merit-agent-skills')) }

    $surf = Get-MeritSurfaceConfig
    if ($surf) {
        foreach ($p in @($surf.skillsSearchPaths)) { [void]$candidates.Add([string]$p) }
    }

    foreach ($raw in $candidates) {
        $full = Expand-MeritPath $raw
        if (Test-MeritSkillsRoot $full) {
            if (-not $resolvedFrom) {
                if ($env:MERIT_SKILLS_ROOT -and (Expand-MeritPath $env:MERIT_SKILLS_ROOT) -eq $full) { $resolvedFrom = 'MERIT_SKILLS_ROOT' }
                elseif ($bench -and $bench.skillsFolder -and (Expand-MeritPath ([string]$bench.skillsFolder)) -eq $full) { $resolvedFrom = 'oss-bench' }
                elseif ($app -and (Expand-MeritPath (Join-Path $app 'merit-agent-skills')) -eq $full) { $resolvedFrom = 'MYMERITAPP' }
                else { $resolvedFrom = 'skillsSearchPaths' }
            }
            return @{ Root = $full; From = $resolvedFrom }
        }
    }

    if ($AllowIdeMarker) {
        $cfgPath = Join-Path (Get-MeritResolveConfigRoot) 'cfg\agent_hosts.json'
        if (Test-Path -LiteralPath $cfgPath) {
            $reg = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
            foreach ($h in @($reg.hosts)) {
                $destTpl = if ($env:OS -match 'Windows') { [string]$h.destSkills.windows } else { [string]$h.destSkills.posix }
                if ($destTpl -match '<repo>') { continue }
                $dest = ($destTpl -replace '%USERPROFILE%', $homeRoot).Split(' ')[0].Trim()
                if ($dest.StartsWith('~/')) { $dest = Join-Path $homeRoot ($dest.TrimStart([char[]]@('~', '/', '\'))) }
                $marker = Join-Path $dest '.merit-surface.json'
                if (-not (Test-Path -LiteralPath $marker)) { continue }
                try {
                    $m = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
                    $hint = Expand-MeritPath ([string]$m.skillsRepoRoot)
                    if (Test-MeritSkillsRoot $hint) {
                        return @{ Root = $hint; From = 'ide-marker' }
                    }
                }
                catch { }
            }
        }
    }
    return @{ Root = $null; From = $null }
}

function Resolve-MeritVaultRoot {
    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($env:MERIT_VAULT_ROOT) { [void]$candidates.Add($env:MERIT_VAULT_ROOT) }
    $bench = Read-MeritOssBenchJson
    if ($bench -and $bench.vaultFolder) { [void]$candidates.Add([string]$bench.vaultFolder) }
    $surf = Get-MeritSurfaceConfig
    $owner = if ($surf) { [string]$surf.vaultOwner } else { 'AgentDraven' }
    $repo = if ($surf) { [string]$surf.vaultRepo } else { 'merit-private-vault' }
    $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
    if ($homeRoot) { [void]$candidates.Add((Join-Path (Join-Path (Join-Path $homeRoot 'dev') $owner) $repo)) }
    if ($surf) {
        foreach ($p in @($surf.vaultSearchPaths)) { [void]$candidates.Add([string]$p) }
    }
    $from = $null
    foreach ($raw in $candidates) {
        $full = Expand-MeritPath $raw
        if (Test-MeritVaultRoot $full) {
            if (-not $from) {
                if ($env:MERIT_VAULT_ROOT -and (Expand-MeritPath $env:MERIT_VAULT_ROOT) -eq $full) { $from = 'MERIT_VAULT_ROOT' }
                elseif ($bench -and $bench.vaultFolder) { $from = 'oss-bench' }
                else { $from = 'vaultSearchPaths' }
            }
            return @{ Root = $full; From = $from }
        }
    }
    return @{ Root = $null; From = $null }
}

function Resolve-MeritHubScript {
    if ($Script:MeritResolveHubScript -and (Test-Path -LiteralPath $Script:MeritResolveHubScript)) {
        return $Script:MeritResolveHubScript
    }
    $tools = Get-MeritEnvScoped -Name 'MYMERITTOOLS'
    if ($tools) {
        $p = Join-Path $tools 'Merit-Hub.ps1'
        if (Test-Path -LiteralPath $p) { return $p }
    }
    $bench = Read-MeritOssBenchJson
    if ($bench -and $bench.hubScript -and (Test-Path -LiteralPath ([string]$bench.hubScript))) {
        return [string]$bench.hubScript
    }
    $surf = Get-MeritSurfaceConfig
    if ($surf) {
        foreach ($raw in @($surf.hubSearchPaths)) {
            $p = Expand-MeritPath ([string]$raw)
            if ($p -and (Test-Path -LiteralPath $p)) { return $p }
        }
    }
    return $null
}

function Get-MeritEdition {
    param(
        [bool]$HasA,
        [bool]$HasB,
        [bool]$HasC
    )
    if ($HasA -and $HasB -and $HasC) { return 'full' }
    if ($HasB -and $HasC) { return 'oss+vault' }
    if ($HasA -and $HasC) { return 'vault+ide' }
    if ($HasA -and $HasB) { return 'oss+ide' }
    if ($HasB) { return 'oss' }
    if ($HasA) { return 'ide-only' }
    if ($HasC) { return 'vault-only' }
    return 'none'
}

function Get-MeritRecoveryHints {
    param(
        [string]$Edition,
        [bool]$StaleIdeMarker
    )
    $hints = [System.Collections.Generic.List[string]]::new()
    switch ($Edition) {
        'none' {
            [void]$hints.Add('Download Merit-Hub.ps1 Raw to %MYMERITTOOLS%')
            [void]$hints.Add('Run Hub 1 then 2 to seed OSS bench')
        }
        'ide-only' {
            [void]$hints.Add('Hub 2 clones merit-agent-skills to %MYMERITAPP%')
            if ($StaleIdeMarker) { [void]$hints.Add('IDE .merit-surface.json is stale — re-run Hub 2 after Pristine') }
        }
        'oss' {
            [void]$hints.Add('.\merit.ps1 where — or Hub menu W')
            [void]$hints.Add('Hub 3/OC need merit-demo (D) — run Hub 2 Install OSS')
        }
        'vault-only' {
            [void]$hints.Add('Hub 2 for OSS/OC; vault scripts\merit.ps1 for operator')
        }
        default {
            [void]$hints.Add('.\merit.ps1 where for full surface map')
        }
    }
    return @($hints)
}

function Get-MeritSurface {
    param(
        [switch]$NoWrite,
        [string]$HubPin = '',
        [string]$HubScript = ''
    )
    if ($HubScript) { $Script:MeritResolveHubScript = $HubScript }
    if (-not $Script:MeritResolveRepoRoot) {
        $tryRoot = Resolve-MeritSkillsRepoRoot
        if ($tryRoot.Root) { $Script:MeritResolveRepoRoot = $tryRoot.Root }
    }

    $skills = Resolve-MeritSkillsRepoRoot -AllowIdeMarker
    $skillsRoot = $skills.Root
    $skillsFrom = $skills.From

    if ($skillsRoot -and -not $NoWrite) {
        $bench = Get-MeritEnvScoped -Name 'MYMERITAPP'
        if (-not $bench) { $bench = Split-Path -Parent $skillsRoot }
        Initialize-OssBenchJson -SkillsFolder $skillsRoot -BenchFolder $bench
    }

    $vault = Resolve-MeritVaultRoot
    $vaultRoot = $vault.Root
    $vaultFrom = $vault.From

    $ide = Get-MeritIdeHosts
    $hasA = ($ide.Hosts.Count -gt 0)
    $hasB = [bool]$skillsRoot
    $hasC = [bool]$vaultRoot
    $edition = Get-MeritEdition -HasA $hasA -HasB $hasB -HasC $hasC

    $publicCli = if ($skillsRoot) { Join-Path $skillsRoot 'merit.ps1' } else { $null }
    $operatorCli = if ($vaultRoot) { Join-Path $vaultRoot 'scripts\merit.ps1' } else { $null }
    $hubScript = Resolve-MeritHubScript
    $benchJson = Get-MeritOssBenchPath
    if (-not (Test-Path -LiteralPath $benchJson)) { $benchJson = $null }

    $demoFolder = $null
    if ($skillsRoot) {
        $app = Get-MeritEnvScoped -Name 'MYMERITAPP'
        if ($app) { $demoFolder = Join-Path $app 'merit-demo' }
        if (-not $demoFolder -or -not (Test-Path -LiteralPath $demoFolder)) {
            $bench = Read-MeritOssBenchJson
            if ($bench -and $bench.demoFolder) { $demoFolder = Expand-MeritPath ([string]$bench.demoFolder) }
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
    if ($hubPinVal -and $skillsVersion) {
        $expected = "skills-v$skillsVersion"
        if ($hubPinVal -ne $expected) { $pinMismatch = $true }
    }

    $staleIdeMarker = [bool]$ide.StaleMarker
    if (-not $hasB -and $hasA -and $staleIdeMarker) { $staleIdeMarker = $true }

    return [pscustomobject]@{
        edition          = $edition
        skillsRepoRoot   = $skillsRoot
        publicMeritCli   = $publicCli
        demoFolder       = $demoFolder
        vaultRoot        = $vaultRoot
        operatorMeritCli = $operatorCli
        hubScript        = $hubScript
        ossBenchJson     = $benchJson
        ideHosts         = @($ide.Hosts)
        staleIdeMarker   = $staleIdeMarker
        hubPin           = $hubPinVal
        skillsVersion    = $skillsVersion
        pinMismatch      = $pinMismatch
        resolvedFrom     = @{
            skills = $skillsFrom
            vault  = $vaultFrom
        }
        recoveryHints    = @(Get-MeritRecoveryHints -Edition $edition -StaleIdeMarker $staleIdeMarker)
    }
}

function Write-MeritSurfaceReport {
    param(
        [Parameter(Mandatory = $true)]
        $Surface,
        [switch]$AsJson
    )
    if ($AsJson) {
        $Surface | ConvertTo-Json -Depth 5
        return
    }
    Write-Host ''
    Write-Host '  MERIT SURFACE' -ForegroundColor Cyan
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
    if ($Surface.operatorMeritCli) {
        Write-Host ('  vault CLI:     {0}' -f $Surface.operatorMeritCli)
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
