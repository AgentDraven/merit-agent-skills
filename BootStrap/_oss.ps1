# Internal OSS bench (PHASE 2). Not a user entry.
# Merit-Hub.ps1 dotsources this after the skills clone. Do not double-click.
#Requires -Version 5.1

if (-not (Get-Command Write-Ok -ErrorAction SilentlyContinue)) {
    function Write-Ok([string]$t) { Write-Host "  [OK]   $t" -ForegroundColor Green }
    function Write-Fail([string]$t) { Write-Host "  [FAIL] $t" -ForegroundColor Red }
    function Write-Warn([string]$t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
    function Write-Note([string]$t) { Write-Host "  NOTE: $t" -ForegroundColor DarkYellow }
    function Write-Info([string]$t) { Write-Host "  $t" }
}

function Write-OssPhaseHeader([string]$Title) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Green
    Write-Host '  Merit-Hub  |  Install OSS' -ForegroundColor Green
    Write-Host "  $Title" -ForegroundColor Green
    Write-Host ('=' * 72) -ForegroundColor Green
}

function Write-VaultPhaseHeader([string]$Title) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Magenta
    Write-Host '  Merit-Hub  |  Vault (local)' -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host ('=' * 72) -ForegroundColor Magenta
}

function Get-OssBenchFolder {
    if (Get-Command Get-MyMeritAppRoot -ErrorAction SilentlyContinue) {
        return Get-MyMeritAppRoot
    }
    $v = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'Process')
    if ([string]::IsNullOrWhiteSpace($v)) {
        $v = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
    }
    if ([string]::IsNullOrWhiteSpace($v)) { $v = 'C:\MyMeritApp' }
    return [IO.Path]::GetFullPath($v.Trim().TrimEnd('\', '/'))
}

function Get-OssJsonPath {
    return Join-Path (Get-OssBenchFolder) 'oss-bench.json'
}

function Get-OssSkillsPin {
    if (Get-Command Get-HubConfig -ErrorAction SilentlyContinue) {
        $p = [string](Get-HubConfig).skillsPin
        if ($p) { return $p }
    }
    $verFile = Join-Path (Get-OssBenchFolder) 'merit-agent-skills\VERSION'
    if (Test-Path -LiteralPath $verFile) {
        $v = ((Get-Content -LiteralPath $verFile -Raw) -split '\r?\n')[0].Trim()
        if ($v -match '^\d+\.\d+') { return "skills-v$v" }
    }
    return 'skills-v0.5.21'
}

function Get-OssVaultPin {
    if (Get-Command Get-HubConfig -ErrorAction SilentlyContinue) {
        $p = [string](Get-HubConfig).vaultPin
        if ($p) { return $p }
    }
    return 'vault-v0.5.8'
}

function New-OssBenchState {
    $bench = Get-OssBenchFolder
    return [pscustomobject]@{
        schemaVersion       = 2
        whatThisFileIs      = 'Local OSS bench status on this laptop. No secrets. Not the merit CLI.'
        edition             = 'oss'
        updatedAt           = (Get-Date).ToString('o')
        benchFolder         = $bench
        skillsFolder        = Join-Path $bench 'merit-agent-skills'
        demoFolder          = Join-Path $bench 'merit-demo'
        skillsPin           = Get-OssSkillsPin
        skillsGitUrl        = 'https://github.com/AgentDraven/merit-agent-skills.git'
        demoGitUrl          = 'https://github.com/Mr-PI-Bala/merit-demo.git'
        vaultPin            = Get-OssVaultPin
        vaultGitUrl         = 'https://github.com/AgentDraven/merit-private-vault.git'
        lastPrereqCheckAt   = ''
        lastValidateAt      = ''
        lastValidatePin     = ''
        lastValidateOk      = $false
        lastValidateDetail  = ''
        ocConsumerId        = ''
        ocPlayUrl           = ''
        ocRegisterUrl       = ''
        ocPortalUrl         = ''
        ocHereNowUrl        = ''
        ocProductName       = ''
    }
}

function ConvertFrom-LegacyMeritJson($old) {
    $s = New-OssBenchState
    try {
        if ($old.testBench.path) { $s.benchFolder = [string]$old.testBench.path }
        if ($old.testBench.skillsPath) { $s.skillsFolder = [string]$old.testBench.skillsPath }
        if ($old.testBench.demoPath) { $s.demoFolder = [string]$old.testBench.demoPath }
    }
    catch { }
    try {
        if ($old.publicSeeds.skills.url) { $s.skillsGitUrl = [string]$old.publicSeeds.skills.url }
        if ($old.publicSeeds.skills.pinTag) { $s.skillsPin = [string]$old.publicSeeds.skills.pinTag }
        if ($old.publicSeeds.showcase.url) { $s.demoGitUrl = [string]$old.publicSeeds.showcase.url }
    }
    catch { }
    try {
        if ($old.vaultTeaser.vaultPinTag) { $s.vaultPin = [string]$old.vaultTeaser.vaultPinTag }
        if ($old.vaultTeaser.vaultUrl) { $s.vaultGitUrl = [string]$old.vaultTeaser.vaultUrl }
    }
    catch { }
    try { if ($old.prerequisitesLastCheck) { $s.lastPrereqCheckAt = [string]$old.prerequisitesLastCheck } }
    catch { }
    try {
        $v = $old.ossValidationLastCheck
        if ($v) {
            $s.lastValidateAt = [string]$v.at
            $s.lastValidatePin = [string]$v.pin
            $bits = @()
            $ok = $true
            foreach ($r in @($v.results)) {
                $bits += "$($r.Step) exit $($r.Exit)"
                if ([int]$r.Exit -ne 0) { $ok = $false }
            }
            $s.lastValidateOk = $ok -and ($bits.Count -gt 0)
            $s.lastValidateDetail = ($bits -join '; ')
        }
    }
    catch { }
    return $s
}

function Merge-OssStateDefaults($State) {
    # Bench files written by an older Hub predate newer fields, and StrictMode makes
    # assigning a missing property fatal. Backfill defaults before any step writes.
    $defaults = New-OssBenchState
    foreach ($prop in $defaults.PSObject.Properties) {
        if (-not $State.PSObject.Properties[$prop.Name]) {
            $State | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
        }
    }
    return $State
}

function Get-OssState {
    $path = Get-OssJsonPath
    if (Test-Path -LiteralPath $path) {
        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        $ver = 1
        try { $ver = [int]$raw.schemaVersion } catch { }
        if ($ver -ge 2 -and $raw.benchFolder) {
            return (Merge-OssStateDefaults $raw)
        }
        return ConvertFrom-LegacyMeritJson $raw
    }
    $bench = Get-OssBenchFolder
    foreach ($legacy in @(
            (Join-Path $bench 'BootStrap\MERIT.json'),
            (Join-Path $bench 'merit-agent-skills\BootStrap\MERIT.json')
        )) {
        if (Test-Path -LiteralPath $legacy) {
            $old = Get-Content -LiteralPath $legacy -Raw -Encoding UTF8 | ConvertFrom-Json
            return ConvertFrom-LegacyMeritJson $old
        }
    }
    return New-OssBenchState
}

function Save-OssState($State) {
    $State.schemaVersion = 2
    $State.whatThisFileIs = 'Local OSS bench status on this laptop. No secrets. Not the merit CLI.'
    $State.edition = 'oss'
    $State.updatedAt = (Get-Date).ToString('o')
    $State.benchFolder = Get-OssBenchFolder
    $State.skillsFolder = Join-Path $State.benchFolder 'merit-agent-skills'
    $State.demoFolder = Join-Path $State.benchFolder 'merit-demo'
    $State.skillsPin = Get-OssSkillsPin
    $State.vaultPin = Get-OssVaultPin
    $path = Get-OssJsonPath
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    ($State | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $path -Encoding UTF8
}

function Get-OssRunner {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return [pscustomobject]@{ Exe = $pwsh.Source; Label = 'pwsh' } }
    $ps = Get-Command powershell -ErrorAction SilentlyContinue
    if ($ps) { return [pscustomobject]@{ Exe = $ps.Source; Label = 'powershell' } }
    throw 'Need pwsh or powershell on PATH'
}

function Invoke-OssEnsureDemo {
    Write-OssPhaseHeader 'Seed merit-demo'
    $state = Get-OssState
    $url = [string]$state.demoGitUrl
    if ([string]::IsNullOrWhiteSpace($url)) { $url = 'https://github.com/Mr-PI-Bala/merit-demo.git' }
    $dest = [string]$state.demoFolder
    New-Item -ItemType Directory -Force -Path (Get-OssBenchFolder) | Out-Null
    $gitDir = Join-Path $dest '.git'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH. Hub menu 1 first.'
        return
    }
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok ('Already cloned: ' + $dest)
        Write-Info 'Pulling latest...'
        & git -C $dest pull --ff-only 2>&1 | Out-Host
    }
    elseif (Test-Path -LiteralPath $dest) {
        Write-Fail ($dest + ' exists but is not a git clone. Move it aside and retry Install OSS.')
        return
    }
    else {
        Write-Info ('Cloning ' + $url + ' ...')
        & git clone $url $dest
        if ($LASTEXITCODE -ne 0) {
            Write-Fail ('git clone failed (exit ' + $LASTEXITCODE + ').')
            return
        }
        Write-Ok ('Cloned ' + $dest)
    }
    Save-OssState $state
}

function Invoke-OssValidate {
    Write-OssPhaseHeader 'Validate OSS (quiet smoke)'
    $env:MERIT_VERIFY_QUIET = '1'
    $state = Get-OssState
    $cli = Join-Path $state.skillsFolder 'merit.ps1'
    if (-not (Test-Path -LiteralPath $cli)) {
        Write-Fail ('merit.ps1 missing at ' + $cli + ' - Hub J / skills clone first.')
        return
    }
    $runner = Get-OssRunner
    Write-Info ('Runner: ' + $runner.Label + ' -> ' + $runner.Exe)
    Write-Info ('CLI:    ' + $cli)
    Write-Host ''
    Write-Info 'Running closeout ...'
    & $runner.Exe -NoProfile -File $cli 'closeout' '--path' $state.skillsFolder
    $code1 = $LASTEXITCODE
    if ($code1 -eq 0) { Write-Ok 'closeout exit 0' } else { Write-Fail ('closeout exit ' + $code1) }

    $smoke = Join-Path $state.skillsFolder 'scripts\smoke-freemium.ps1'
    $code2 = -1
    if (Test-Path -LiteralPath $smoke) {
        Write-Info 'Running smoke-freemium.ps1 ...'
        & $runner.Exe -NoProfile -File $smoke
        $code2 = $LASTEXITCODE
        if ($code2 -eq 0) { Write-Ok 'smoke-freemium exit 0' } else { Write-Fail ('smoke-freemium exit ' + $code2) }
    }
    else {
        Write-Warn ('smoke script missing: ' + $smoke)
    }

    $state.lastValidateAt = (Get-Date).ToString('o')
    $state.lastValidatePin = Get-OssSkillsPin
    $state.lastValidateOk = ($code1 -eq 0) -and ($code2 -eq 0)
    $state.lastValidateDetail = ('closeout exit ' + $code1 + '; smoke-freemium exit ' + $code2)
    Save-OssState $state
}

function Show-OssFlow {
    Write-Host ''
    Write-Info 'One script: Merit-Hub.ps1. Map keys: 1 2 3 OC 4 VC 5 0.'
    if (Get-Command Write-HubMap -ErrorAction SilentlyContinue) {
        Write-HubMap
    }
}

function Get-OssChecklist {
    $state = Get-OssState
    $cli = Join-Path $state.skillsFolder 'merit.ps1'
    $skillsOk = Test-Path -LiteralPath $cli
    $demoOk = Test-Path -LiteralPath (Join-Path $state.demoFolder '.git')
    $valOk = [bool]$state.lastValidateOk
    return [pscustomobject]@{
        State    = $state
        SkillsOk = $skillsOk
        DemoOk   = $demoOk
        ValOk    = $valOk
    }
}

function Write-OssChecklist {
    $c = Get-OssChecklist
    $s = $c.State
    if ($c.SkillsOk) { Write-Ok ('Skills folder - ' + [string]$s.skillsFolder) } else { Write-Warn ('Skills folder missing - Hub J first (' + [string]$s.skillsFolder + ')') }
    if ($c.DemoOk) { Write-Ok ('Demo folder   - ' + [string]$s.demoFolder) } else { Write-Warn 'Demo folder missing - run Hub 2 Install OSS' }
    if ($c.ValOk) {
        Write-Ok ('Last validate PASS - ' + [string]$s.lastValidateDetail + ' at ' + [string]$s.lastValidateAt)
    }
    else {
        Write-Warn 'Last validate not PASS yet - run Hub 2 Install OSS'
    }
    return $c
}

function Show-OssHelp {
    Write-OssPhaseHeader 'Help'
    Write-Note 'You are still in Merit-Hub. Not a second product.'
    Write-Info 'CLI for apps stays repo-root merit.ps1 (init / apply / verify / create / oc).'
    Write-Info 'Showcase: Mr-PI-Bala/merit-demo. Proof: Mr-PI-Bala/merit-test.'
    Show-OssFlow
    Write-Host ''
    Write-Note 'Vault (key 4) is optional and still local. OC is freeware cloud. VC is operator grade.'
    Write-Info 'Public facts only (no product law / no secrets):'
    Write-Info '  (a) AgentDraven hosts the private MERIT ecosystem account'
    Write-Info '  (b) Repo: merit-private-vault (private on GitHub)'
    Write-Info '  (c) Key 4 clones that repo into ~/dev'
}

function Show-OssStatus {
    Write-OssPhaseHeader 'U  Status (plain English)'
    $c = Get-OssChecklist
    $s = $c.State
    Write-Info ('What this file is : ' + [string]$s.whatThisFileIs)
    Write-Info ('Status file       : ' + (Get-OssJsonPath))
    Write-Info ('Bench folder      : ' + [string]$s.benchFolder)
    Write-Info ('Skills pin        : ' + [string]$s.skillsPin)
    Write-Info ('Vault pin         : ' + [string]$s.vaultPin + ' (only if you run Hub 4)')
    Write-Host ''
    [void](Write-OssChecklist)
    Write-Host ''
    if ($s.lastPrereqCheckAt) { Write-Info ('Last prereq check : ' + [string]$s.lastPrereqCheckAt) }
    else { Write-Info 'Last prereq check : (Hub menu 1)' }
    if ($s.lastValidateDetail) { Write-Info ('Validate detail   : ' + [string]$s.lastValidateDetail) }
}

function Invoke-OssVaultSeed {
    Write-VaultPhaseHeader '4  Seed Private-Vault into ~/dev'
    Write-Note 'Do this after Hub 2 is green. Vault is still local. VC is later.'
    Write-Note 'Needs GitHub access to AgentDraven/merit-private-vault.'
    Write-Host ''
    Show-OssFlow
    Write-Host ''
    Write-Info 'Your OSS setup right now:'
    $c = Write-OssChecklist
    Write-Host ''
    if (-not $c.SkillsOk -or -not $c.DemoOk -or -not $c.ValOk) {
        Write-Warn 'Install OSS is not fully validated. Prefer Hub 2, then 4.'
        $anyway = Read-Host 'Seed Private-Vault anyway? [y/N]'
        if ($anyway -notmatch '^[Yy]') {
            Write-Warn 'Cancelled. Run Hub 2, then 4.'
            return
        }
    }
    else {
        $confirm = Read-Host 'OSS looks ready. Seed Private-Vault into ~/dev now? [y/N]'
        if ($confirm -notmatch '^[Yy]') {
            Write-Warn 'Cancelled.'
            return
        }
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH. Hub menu 1 first.'
        return
    }

    $state = Get-OssState
    $devRoot = [IO.Path]::GetFullPath((Join-Path $HOME 'dev'))
    $ownerDir = Join-Path $devRoot 'AgentDraven'
    $vaultDir = Join-Path $ownerDir 'merit-private-vault'
    $vaultUrl = [string]$state.vaultGitUrl
    if ([string]::IsNullOrWhiteSpace($vaultUrl)) { $vaultUrl = 'https://github.com/AgentDraven/merit-private-vault.git' }
    $vaultPinTag = Get-OssVaultPin
    $bootCmd = Join-Path $vaultDir 'BootStrap\MERIT_BootStrap.cmd'
    $seedCmd = Join-Path $vaultDir 'BootStrap\seed-private-dev.cmd'

    New-Item -ItemType Directory -Force -Path $ownerDir | Out-Null
    $gitDir = Join-Path $vaultDir '.git'
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok ('Vault already cloned: ' + $vaultDir)
        Write-Info ('Fetching / checking out pin ' + $vaultPinTag + ' ...')
        & git -C $vaultDir fetch --tags origin 2>&1 | Out-Host
        & git -C $vaultDir checkout --detach "refs/tags/$vaultPinTag" 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Warn 'Tag checkout failed; pulling main tip instead.'
            & git -C $vaultDir checkout main 2>&1 | Out-Host
            & git -C $vaultDir pull --ff-only 2>&1 | Out-Host
        }
        else {
            Write-Ok ('Detached at ' + $vaultPinTag)
        }
    }
    elseif (Test-Path -LiteralPath $vaultDir) {
        Write-Warn ($vaultDir + ' exists but is not a git clone.')
        return
    }
    else {
        Write-Info ('Cloning ' + $vaultUrl + ' --branch ' + $vaultPinTag + ' ...')
        & git clone --branch $vaultPinTag $vaultUrl $vaultDir
        if ($LASTEXITCODE -ne 0) {
            Write-Fail ('git clone failed (exit ' + $LASTEXITCODE + '). Use an account that can read the private vault.')
            return
        }
    }

    if (Test-Path -LiteralPath $seedCmd) {
        Write-Ok 'Launching vault seed-private-dev.cmd ...'
        & $seedCmd
        return
    }
    if (Test-Path -LiteralPath $bootCmd) {
        Write-Ok ('Launching ' + $bootCmd + ' ...')
        & $bootCmd
        return
    }
    Write-Fail ('Vault BootStrap not found under ' + $vaultDir)
}

function Pause-Oss {
    Write-Host ''
    $n = Read-Host 'Press Enter for Hub map, or type next key (2 / 3 / OC / 4 / VC / 5 / 0)'
    if ($null -eq $n) { return '' }
    return $n.Trim()
}

function Show-OssPhaseMenu {
    Write-OssPhaseHeader 'OSS helpers (Hub map is the menu)'
    $bench = Get-OssBenchFolder
    Write-Note ('Still Merit-Hub. Bench: ' + $bench)
    Write-Note 'Use Hub keys 1 2 3 OC 4 VC 5 0. Nested D/G menu is retired.'
    if (Get-Command Write-HubMap -ErrorAction SilentlyContinue) { Write-HubMap }
}

function Invoke-OssPhaseChoice([string]$c) {
    switch -Regex ($c) {
        '^(D|d|2)$' { Invoke-OssEnsureDemo; return Pause-Oss }
        '^(G|g)$' { Invoke-OssValidate; return Pause-Oss }
        '^(U|u|S|s)$' { Show-OssStatus; return Pause-Oss }
        '^(F|f|H|h)$' { Show-OssHelp; return Pause-Oss }
        '^(3|4)$' { Invoke-OssVaultSeed; return Pause-Oss }
        '^(0|Q|q)$' { return '__BACK__' }
        default { Write-Warn 'Unknown key. Prefer Hub 1 2 3 OC 4 VC 5 0.'; return Pause-Oss }
    }
}

function Invoke-OssPhaseMenu {
    Save-OssState (Get-OssState)
    $pending = ''
    while ($true) {
        if ([string]::IsNullOrWhiteSpace($pending)) {
            Show-OssPhaseMenu
            $c = (Read-Host 'PHASE 2 Select').Trim()
        }
        else {
            $c = $pending
            $pending = ''
            Write-Note ('Continuing with ' + $c + ' from previous pause')
        }
        $pending = Invoke-OssPhaseChoice $c
        if ($pending -eq '__BACK__') {
            Write-Note 'Back to Hub map.'
            return
        }
    }
}

function Invoke-OssChainThenMenu {
    Write-OssPhaseHeader 'Install OSS'
    Write-Note 'Skills clone is done. Next: demo, then quiet validate - same script.'
    Invoke-OssEnsureDemo
    Invoke-OssValidate
    Write-Ok 'Install OSS finished (demo + quiet smoke). Hub map is next (3 Try it, OC, 4 Vault).'
}
