# MERIT OSS BootStrap Ã¢â‚¬â€ public freeware BootStrap (Apache-2.0 with merit-agent-skills).
#
# This is the PUBLIC edition. It does NOT include Private-Vault operator tooling,
# L1 governance files, or cert/registry internals.
#
# Private-Vault / full operator BootStrap lives separately (operators only).
# Teaser only below Ã¢â‚¬â€ subscription / entitlement = FUTURE.
#
# Usage (from this folder):
#   .\MERIT_BootStrap.cmd
#   .\MERIT_BootStrap.ps1
#   ./MERIT_BootStrap.sh
#
# Does not replace the MERIT CLI at repo root (../merit.ps1).

#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:BootStrapRoot = $PSScriptRoot
if (-not $Script:BootStrapRoot) {
    $Script:BootStrapRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$Script:SkillsRoot = [System.IO.Path]::GetFullPath((Join-Path $Script:BootStrapRoot '..'))
$Script:JsonPath = Join-Path $Script:BootStrapRoot 'MERIT.json'
$Script:DefaultBench = 'C:\MyMeritApp'
$Script:Edition = 'oss'

function Get-MyMeritAppRoot {
    # Prefer process env, then User env MYMERITAPP, else default.
    $fromProc = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'Process')
    if (-not [string]::IsNullOrWhiteSpace($fromProc)) {
        return [IO.Path]::GetFullPath($fromProc.Trim().TrimEnd('\', '/'))
    }
    $fromUser = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
    if (-not [string]::IsNullOrWhiteSpace($fromUser)) {
        $env:MYMERITAPP = $fromUser
        return [IO.Path]::GetFullPath($fromUser.Trim().TrimEnd('\', '/'))
    }
    return $Script:DefaultBench
}

function Set-MyMeritAppRoot {
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path.Trim().TrimEnd('\', '/'))
    [Environment]::SetEnvironmentVariable('MYMERITAPP', $full, 'User')
    $env:MYMERITAPP = $full
    $Script:BenchRoot = $full
    Write-Ok "MYMERITAPP (User) = $full"
    Write-Note 'New terminals pick this up automatically. This session is updated too.'
    return $full
}

function Ensure-MyMeritAppRoot {
    param([switch]$ForcePrompt)
    $current = Get-MyMeritAppRoot
    $userSet = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
    if ($ForcePrompt -or [string]::IsNullOrWhiteSpace($userSet)) {
        Write-Host ''
        Write-Note "OSS bench folder (skills + demo + live BootStrap). Default: $($Script:DefaultBench)"
        $ans = Read-Host "MYMERITAPP path [$current]"
        if (-not [string]::IsNullOrWhiteSpace($ans)) {
            $current = Set-MyMeritAppRoot -Path $ans
        }
        else {
            $current = Set-MyMeritAppRoot -Path $current
        }
    }
    else {
        $Script:BenchRoot = $current
        Write-Ok "MYMERITAPP = $current"
    }
    return $current
}

$Script:BenchRoot = Get-MyMeritAppRoot

function Test-BootOnWindows {
    return [bool]($env:OS -match 'Windows')
}

function Get-DefaultMyMeritTools {
    if (Test-BootOnWindows) { return 'C:\Tools' }
    return [IO.Path]::GetFullPath((Join-Path $HOME 'Tools'))
}

function Get-MyMeritToolsRoot {
    foreach ($scope in @('Process', 'User', 'Machine')) {
        $v = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', $scope)
        if (-not [string]::IsNullOrWhiteSpace($v)) {
            return [IO.Path]::GetFullPath($v.Trim().TrimEnd('\', '/'))
        }
    }
    return Get-DefaultMyMeritTools
}

function Get-MeritVenvPython {
    $tools = Get-MyMeritToolsRoot
    if (Test-BootOnWindows) { return Join-Path $tools 'merit-venv\Scripts\python.exe' }
    return Join-Path $tools 'merit-venv/bin/python3'
}

function Resolve-SkillsPinTag {
    $candidates = @(
        (Join-Path $Script:SkillsRoot 'VERSION'),
        (Join-Path (Get-MyMeritAppRoot) 'merit-agent-skills\VERSION')
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) {
            $v = ((Get-Content -LiteralPath $p -Raw) -split '\r?\n')[0].Trim()
            if ($v -match '^\d+\.\d+') { return "skills-v$v" }
        }
    }
    return 'skills-v0.5.10'
}

function Write-Header([string]$Title) {
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host "  MERIT OSS BootStrap  |  $Title" -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
}
function Write-Ok([string]$t) { Write-Host "  [OK]   $t" -ForegroundColor Green }
function Write-Fail([string]$t) { Write-Host "  [FAIL] $t" -ForegroundColor Red }
function Write-Warn([string]$t) { Write-Host "  [WARN] $t" -ForegroundColor Yellow }
function Write-Note([string]$t) { Write-Host "  NOTE: $t" -ForegroundColor DarkYellow }
function Write-Info([string]$t) { Write-Host "  $t" }
function Pause-Go { Write-Host ''; Read-Host 'Press Enter to continue' | Out-Null }

function Get-State {
    if (-not (Test-Path -LiteralPath $Script:JsonPath)) {
        throw "MERIT.json missing at $($Script:JsonPath)"
    }
    return (Get-Content -LiteralPath $Script:JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Save-State($State) {
    $State.updatedAt = (Get-Date).ToString('o')
    $State.edition = 'oss'
    $State.skillsRoot = $Script:SkillsRoot
    $State.BootStrapRoot = $Script:BootStrapRoot
    ($State | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $Script:JsonPath -Encoding UTF8
}

function Get-Bench($State) {
    $path = Get-MyMeritAppRoot
    if ($State.testBench -and $State.testBench.path) {
        # Prefer env/user MYMERITAPP over stale JSON when env is set
        $userSet = [Environment]::GetEnvironmentVariable('MYMERITAPP', 'User')
        if ([string]::IsNullOrWhiteSpace($userSet) -and [string]::IsNullOrWhiteSpace($env:MYMERITAPP)) {
            $path = [string]$State.testBench.path
        }
    }
    return [pscustomobject]@{
        Path       = $path
        SkillsPath = Join-Path $path 'merit-agent-skills'
        DemoPath   = Join-Path $path 'merit-demo'
        AppPath    = Join-Path $path 'my-app'
        CliPath    = Join-Path (Join-Path $path 'merit-agent-skills') 'merit.ps1'
    }
}

function Get-Runner {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        return [pscustomobject]@{ Exe = $pwsh.Source; Label = 'pwsh' }
    }
    $ps = Get-Command powershell -ErrorAction SilentlyContinue
    if ($ps) {
        return [pscustomobject]@{ Exe = $ps.Source; Label = 'powershell' }
    }
    throw 'Need pwsh or powershell on PATH'
}

function Test-Winget { return [bool](Get-Command winget -ErrorAction SilentlyContinue) }

function Install-WingetPkg([string]$Id, [string]$Name) {
    if (-not (Test-Winget)) {
        Write-Fail "winget missing; install $Name manually"
        return $false
    }
    Write-Info "Installing $Name ($Id) ..."
    & winget install --id $Id -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {
        Write-Ok "$Name ok (exit $LASTEXITCODE)"
        return $true
    }
    Write-Fail "$Name failed (exit $LASTEXITCODE)"
    return $false
}

function Refresh-ProcessPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
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
    foreach ($c in @(
            (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
            (Join-Path $env:ProgramFiles 'Python312\python.exe')
        )) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

function Install-ToolsMeritPython {
    <#
      Laptop-shared MYMERITTOOLS\merit-venv (default C:\Tools). Menu 1 installs like git/gh.
      Public merit.ps1 is PowerShell-first; Python still helps merit-demo / Flask / local tooling.
    #>
    $tools = Get-MyMeritToolsRoot
    Write-Header "Creating MERIT Python venv under MYMERITTOOLS ($tools)"
    Write-Note 'Not git-tracked. Same path Private-Vault uses when MYMERITTOOLS is set.'
    $venvDir = Join-Path $tools 'merit-venv'
    $venvPy = Get-MeritVenvPython
    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    if (Test-Path -LiteralPath $venvPy) {
        Write-Ok "Already present: $venvPy"
        Set-Content -LiteralPath (Join-Path $tools 'merit-python.cmd') -Value "@echo off`r`n`"$venvPy`" %*`r`n" -Encoding ASCII
        return $true
    }
    $base = Resolve-BasePythonExe
    if (-not $base) {
        Write-Info 'Base Python missing — winget Python.Python.3.12 ...'
        if (-not (Install-WingetPkg -Id 'Python.Python.3.12' -Name 'Python 3.12')) { return $false }
        Refresh-ProcessPath
        $base = Resolve-BasePythonExe
        if (-not $base) {
            Write-Fail 'Python installed but not on PATH — open a NEW terminal, re-run menu 1.'
            return $false
        }
    }
    else {
        Write-Ok "Base Python: $base"
    }
    Write-Info "Creating $venvDir ..."
    & $base -m venv $venvDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $venvPy)) {
        Write-Fail "venv create failed at $venvDir"
        return $false
    }
    Set-Content -LiteralPath (Join-Path $tools 'merit-python.cmd') -Value "@echo off`r`n`"$venvPy`" %*`r`n" -Encoding ASCII
    Write-Ok "MERIT laptop Python: $venvPy"
    return $true
}

$Script:SkillsPinTag = Resolve-SkillsPinTag

function Invoke-Prereqs {
    Write-Header 'Prerequisites - check tools, Python venv, and MYMERIT* env'
    Write-Note 'Safe to re-run. Lists what is missing before asking. y only installs those items.'
    Write-Host ''
    $needGit = $false
    $needPwsh = $false
    $needGh = $false
    $needToolsPy = $false
    $tools = Get-MyMeritToolsRoot
    $toolsUser = [Environment]::GetEnvironmentVariable('MYMERITTOOLS', 'User')
    $needPersistTools = [string]::IsNullOrWhiteSpace($toolsUser)

    Write-Info '--- Environment ---'
    Write-Ok "MYMERITTOOLS resolved = $tools"
    if ($needPersistTools) { Write-Warn "MYMERITTOOLS User env - not persisted (will SET to $tools)" }
    else { Write-Ok "MYMERITTOOLS User env already set = $toolsUser" }
    Write-Host ''
    Write-Info '--- Tools ---'

    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) { Write-Ok ("Git - " + ((& git --version 2>&1 | Out-String).Trim())) }
    else { $needGit = $true; Write-Fail 'Git - not on PATH' }

    Write-Ok ("Host PSVersion - $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)")
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) { Write-Ok "pwsh - $($pwshCmd.Source)" }
    else { $needPwsh = $true; Write-Warn 'pwsh - missing (Windows PowerShell 5.1 still works for this BootStrap)' }

    if (Test-Winget) { Write-Ok "winget - $((Get-Command winget).Source)" }
    else { Write-Warn 'winget - missing; cannot auto-install' }

    $ghExe = $null
    foreach ($c in @(
            (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'GitHub CLI\gh.exe')
        )) {
        if ($c -and (Test-Path -LiteralPath $c)) { $ghExe = $c; break }
    }
    if (-not $ghExe) {
        $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
        $toolsPrefix = [regex]::Escape($tools.TrimEnd('\') + '\')
        if ($ghCmd -and $ghCmd.Source -and $ghCmd.Source -notmatch "(?i)^$toolsPrefix" -and $ghCmd.Source -notmatch '(?i)^C:\\Tools\\') {
            $ghExe = $ghCmd.Source
        }
    }
    if ($ghExe) {
        # Avoid hanging on a broken C:\Tools\gh shim (self-recursion) — prefer real exe + short timeout.
        $p = Start-Process -FilePath $ghExe -ArgumentList '--version' -NoNewWindow -PassThru `
            -RedirectStandardOutput "$env:TEMP\merit-oss-gh-ver.txt" -RedirectStandardError "$env:TEMP\merit-oss-gh-ver-err.txt"
        if (-not $p.WaitForExit(10000)) {
            try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch { }
            Write-Warn "gh - timed out (10s) at $ghExe — skip or fix Tools shim; optional for OSS"
        }
        else {
            $line = (Get-Content -LiteralPath "$env:TEMP\merit-oss-gh-ver.txt" -TotalCount 1 -ErrorAction SilentlyContinue)
            Write-Ok ("gh - " + $(if ($line) { $line.Trim() } else { $ghExe }))
        }
        Remove-Item -LiteralPath "$env:TEMP\merit-oss-gh-ver.txt", "$env:TEMP\merit-oss-gh-ver-err.txt" -Force -ErrorAction SilentlyContinue
    }
    else {
        $needGh = $true
        Write-Warn 'gh - optional (PRs); can install via winget'
    }

    try {
        $resp = Invoke-WebRequest -Uri 'https://github.com' -Method Head -UseBasicParsing -TimeoutSec 10
        Write-Ok "GitHub reachability - HTTP $($resp.StatusCode)"
    }
    catch {
        Write-Warn "GitHub reachability - $($_.Exception.Message)"
    }

    $bench = Get-Bench (Get-State)
    if (Test-Path -LiteralPath $bench.Path) { Write-Ok "MYMERITAPP bench - $($bench.Path)" }
    else { Write-Warn "MYMERITAPP bench missing - $($bench.Path) (created on first run / menu M)" }
    if (Test-Path -LiteralPath $bench.SkillsPath) { Write-Ok "Bench skills - $($bench.SkillsPath)" }
    else { Write-Warn "Bench skills missing - use menu 2 (pin $($Script:SkillsPinTag))" }
    if (Test-Path -LiteralPath $bench.DemoPath) { Write-Ok "Bench demo - $($bench.DemoPath)" }
    else { Write-Warn 'Bench demo missing - use menu 3' }

    $toolsPy = Get-MeritVenvPython
    $basePy = Resolve-BasePythonExe
    if (Test-Path -LiteralPath $toolsPy) {
        try {
            $ver = & $toolsPy -c "import sys; print(sys.version.split()[0])" 2>&1
            Write-Ok "MERIT Python venv - $ver ($toolsPy)"
        }
        catch {
            Write-Ok "MERIT Python venv - $toolsPy"
        }
    }
    else {
        $needToolsPy = $true
        Write-Warn "MERIT Python venv - MISSING at $toolsPy"
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
    if ($needGh) { $missingTools.Add('GitHub CLI (gh) — optional') }
    if ($needToolsPy) { $missingTools.Add("MERIT Python venv ($toolsPy)") }
    $needAnyTool = $needGit -or $needPwsh -or $needGh -or $needToolsPy

    if (-not $needAnyTool -and -not $needPersistTools) {
        Write-Ok 'Nothing missing. Tools and User env are already set.'
        $state = Get-State
        $state.prerequisitesLastCheck = (Get-Date).ToString('o')
        Save-State $state
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
    if ($needPersistTools) {
        Write-Note 'Set User environment variables:'
        Write-Info "    - MYMERITTOOLS = $tools"
    }

    $prompt = if ($needAnyTool -and $needPersistTools) {
        'Install missing items and set User env listed above? [y/N]'
    }
    elseif ($needAnyTool) {
        'Install / create the missing items listed above? [y/N]'
    }
    else {
        'Set the User environment variables listed above? [y/N]'
    }
    $ans = Read-Host $prompt
    if ($ans -notmatch '^[Yy]') {
        Write-Warn 'Skipped installs.'
        return
    }
    if ($needPersistTools) {
        [Environment]::SetEnvironmentVariable('MYMERITTOOLS', $tools, 'User')
        $env:MYMERITTOOLS = $tools
        Write-Ok "SET User env MYMERITTOOLS = $tools"
        Write-Note 'Open a NEW terminal to see User env in other windows. This process already has it.'
    }
    if ($needGit) { [void](Install-WingetPkg -Id 'Git.Git' -Name 'Git') }
    if ($needPwsh) { [void](Install-WingetPkg -Id 'Microsoft.PowerShell' -Name 'PowerShell 7+') }
    if ($needGh) { [void](Install-WingetPkg -Id 'GitHub.cli' -Name 'GitHub CLI') }
    if ($needToolsPy) { [void](Install-ToolsMeritPython) }
    $state = Get-State
    $state.prerequisitesLastCheck = (Get-Date).ToString('o')
    Save-State $state
}

function Invoke-EnsureBenchSkills {
    Write-Header "Ensure bench merit-agent-skills @ $($Script:SkillsPinTag)"
    $state = Get-State
    $bench = Get-Bench $state
    $url = [string]$state.publicSeeds.skills.url
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = 'https://github.com/AgentDraven/merit-agent-skills.git'
    }
    New-Item -ItemType Directory -Force -Path $bench.Path | Out-Null
    $dest = $bench.SkillsPath
    $gitDir = Join-Path $dest '.git'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH. Use menu 1 first.'
        return
    }

    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok "Already cloned: $dest"
        Write-Info "Fetching / checking out pin $($Script:SkillsPinTag) ..."
        & git -C $dest fetch --tags origin 2>&1 | Out-Host
        & git -C $dest checkout --detach "refs/tags/$($Script:SkillsPinTag)" 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Tag checkout failed; staying on current tip. Tag $($Script:SkillsPinTag) may not exist yet."
        }
        else {
            Write-Ok "Detached at $($Script:SkillsPinTag)"
        }
    }
    elseif (Test-Path -LiteralPath $dest) {
        Write-Fail "$dest exists but is not a git clone. Move it aside and re-run."
        return
    }
    else {
        Write-Info "Cloning $url --branch $($Script:SkillsPinTag) ..."
        & git clone --branch $Script:SkillsPinTag $url $dest
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "git clone failed (exit $LASTEXITCODE)."
            return
        }
        Write-Ok "Cloned $dest @ $($Script:SkillsPinTag)"
    }

    if (-not $state.testBench) {
        $state | Add-Member -NotePropertyName testBench -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $state.testBench.path = $bench.Path
    $state.testBench.skillsPath = $dest
    Save-State $state
}

function Invoke-EnsureDemo {
    Write-Header 'Seed clone merit-demo under MYMERITAPP'
    $state = Get-State
    $bench = Get-Bench $state
    $url = [string]$state.publicSeeds.showcase.url
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = 'https://github.com/Mr-PI-Bala/merit-demo.git'
    }
    New-Item -ItemType Directory -Force -Path $bench.Path | Out-Null
    $dest = $bench.DemoPath
    $gitDir = Join-Path $dest '.git'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH. Use menu 1 first.'
        return
    }
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok "Already cloned: $dest"
        Write-Info 'Pulling latest...'
        & git -C $dest pull --ff-only 2>&1 | Out-Host
    }
    elseif (Test-Path -LiteralPath $dest) {
        Write-Fail "$dest exists but is not a git clone. Move it aside and re-run."
        return
    }
    else {
        Write-Info "Cloning $url ..."
        & git clone $url $dest
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "git clone failed (exit $LASTEXITCODE)."
            return
        }
        Write-Ok "Cloned $dest"
    }
    if (-not $state.testBench) {
        $state | Add-Member -NotePropertyName testBench -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $state.testBench.path = $bench.Path
    $state.testBench.demoPath = $dest
    Save-State $state
}

function Invoke-OssValidate {
    Write-Header 'OSS validate (closeout + smoke)'
    $state = Get-State
    $bench = Get-Bench $state
    if (-not (Test-Path -LiteralPath $bench.CliPath)) {
        Write-Fail "merit.ps1 missing at $($bench.CliPath)"
        Write-Note 'Run menu 2 first (skills pin clone under MYMERITAPP).'
        return
    }
    $runner = Get-Runner
    Write-Info "Runner: $($runner.Label) -> $($runner.Exe)"
    Write-Info "CLI:    $($bench.CliPath)"
    Write-Host ''
    Write-Info 'Running closeout ...'
    & $runner.Exe -NoProfile -File $bench.CliPath 'closeout' '--path' $bench.SkillsPath
    $code1 = $LASTEXITCODE
    if ($code1 -eq 0) { Write-Ok 'closeout exit 0' } else { Write-Fail "closeout exit $code1" }

    $smoke = Join-Path $bench.SkillsPath 'scripts\smoke-freemium.ps1'
    $code2 = -1
    if (Test-Path -LiteralPath $smoke) {
        Write-Info 'Running smoke-freemium.ps1 ...'
        & $runner.Exe -NoProfile -File $smoke
        $code2 = $LASTEXITCODE
        if ($code2 -eq 0) { Write-Ok 'smoke-freemium exit 0' } else { Write-Fail "smoke-freemium exit $code2" }
    }
    else {
        Write-Warn "smoke script missing: $smoke"
    }

    $state.ossValidationLastCheck = [pscustomobject]@{
        at      = (Get-Date).ToString('o')
        bench   = $bench.Path
        pin     = $Script:SkillsPinTag
        results = @(
            [pscustomobject]@{ Step = 'closeout'; Exit = $code1 }
            [pscustomobject]@{ Step = 'smoke-freemium'; Exit = $code2 }
        )
    }
    Save-State $state
}

function Show-VaultTeaser {
    Write-Header 'Private-Vault teaser'
    Write-Note 'OSS stays free: skills, CLI, demo, local validate.'
    Write-Host ''
    Write-Info 'Operators with vault access can seed a full device under ~/dev.'
    Write-Info 'Public facts only (no product law / no secrets):'
    Write-Info '  (a) AgentDraven hosts the private MERIT ecosystem account'
    Write-Info '  (b) Repo: merit-private-vault (private on GitHub)'
    Write-Info '  (c) That repo has BootStrap/MERIT_BootStrap to install into ~/dev'
    Write-Host ''
    Write-Info 'Subscription / design-partner access for everyone else = FUTURE.'
    Write-Note 'Menu  P  runs the seed (clone vault + launch its BootStrap) when you have access.'
}

function Invoke-SeedPrivateVaultDev {
    Write-Header 'Seed Private-Vault BootStrap into ~/dev'
    Write-Note 'One step instead of three: ensure folder, clone vault, run its BootStrap.'
    Write-Note 'Needs GitHub access to AgentDraven/merit-private-vault (GCM prompts on clone).'
    Write-Host ''
    Write-Info 'Does not put vault product law into this public skills repo.'
    Write-Host ''

    $confirm = Read-Host 'Continue? [y/N]'
    if ($confirm -notmatch '^[Yy]') {
        Write-Warn 'Cancelled.'
        return
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Fail 'git not on PATH. Use menu 1 to install Git first.'
        return
    }

    $devRoot = [IO.Path]::GetFullPath((Join-Path $HOME 'dev'))
    $ownerDir = Join-Path $devRoot 'AgentDraven'
    $vaultDir = Join-Path $ownerDir 'merit-private-vault'
    $vaultUrl = 'https://github.com/AgentDraven/merit-private-vault.git'
    $vaultPinTag = 'vault-v0.5.0'
    $bootCmd = Join-Path $vaultDir 'BootStrap\MERIT_BootStrap.cmd'
    $seedCmd = Join-Path $vaultDir 'BootStrap\seed-private-dev.cmd'

    New-Item -ItemType Directory -Force -Path $ownerDir | Out-Null

    $gitDir = Join-Path $vaultDir '.git'
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok "Vault already cloned: $vaultDir"
        Write-Info "Fetching / checking out pin $vaultPinTag ..."
        & git -C $vaultDir fetch --tags origin 2>&1 | Out-Host
        & git -C $vaultDir checkout --detach "refs/tags/$vaultPinTag" 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Tag checkout failed; pulling main tip instead."
            & git -C $vaultDir checkout main 2>&1 | Out-Host
            & git -C $vaultDir pull --ff-only 2>&1 | Out-Host
        }
        else {
            Write-Ok "Detached at $vaultPinTag"
        }
    }
    elseif (Test-Path -LiteralPath $vaultDir) {
        Write-Warn "$vaultDir exists but is not a git clone."
        $ans = Read-Host 'Move it aside and clone fresh from GitHub? [Y/n]'
        if ($ans -match '^[Nn]') {
            Write-Warn 'Aborted.'
            return
        }
        $bak = Join-Path $ownerDir ("merit-private-vault.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        Move-Item -LiteralPath $vaultDir -Destination $bak
        Write-Ok "Moved aside -> $bak"
        Write-Info "Cloning $vaultUrl --branch $vaultPinTag ..."
        & git clone --branch $vaultPinTag $vaultUrl $vaultDir
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "git clone failed (exit $LASTEXITCODE). Use an account that can read the private vault."
            return
        }
    }
    else {
        Write-Info "Cloning $vaultUrl --branch $vaultPinTag ..."
        Write-Note 'HTTPS uses Git Credential Manager â€” sign in with vault access (AgentDraven).'
        & git clone --branch $vaultPinTag $vaultUrl $vaultDir
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "git clone failed (exit $LASTEXITCODE)."
            return
        }
    }

    if (Test-Path -LiteralPath $seedCmd) {
        Write-Ok 'Launching vault seed-private-dev.cmd ...'
        & $seedCmd
        return
    }
    if (-not (Test-Path -LiteralPath $bootCmd)) {
        Write-Fail "BootStrap not on vault tip yet: $bootCmd"
        Write-Note 'Commit BootStrap/ to merit-private-vault on GitHub, then re-run P.'
        return
    }
    Write-Ok "Launching $bootCmd ..."
    & $bootCmd
}

function Show-Guidelines {
    Write-Header 'OSS guidelines'
    Write-Info '1) Clone merit-agent-skills (public).'
    Write-Info '2) Run BootStrap\MERIT_BootStrap.cmd  (copies live BootStrap under %MYMERITAPP%, default C:\MyMeritApp).'
    Write-Info '3) Menus 1-4: prereqs, demo, validate. Menu M changes MYMERITAPP.'
    Write-Info 'CLI stays repo-root merit.ps1 (init / apply / verify / create).'
    Write-Info 'Showcase: Mr-PI-Bala/merit-demo. Proof: Mr-PI-Bala/merit-test.'
    Write-Host ''
    Write-Note 'Private-Vault optional. Menu P seeds ~/dev if you have vault GitHub access.'
    Write-Note 'This BootStrap never ships Private-Vault product law or cert internals.'
}

function Show-Status {
    Write-Header 'MERIT.json (OSS BootStrap)'
    $state = Get-State
    Save-State $state
    Write-Host ($state | ConvertTo-Json -Depth 8)
}

function Show-Menu {
    Write-Header 'OSS BootStrap menu'
    Write-Note 'Public freeware path. Start with: MERIT_BootStrap.cmd'
    Write-Note "Skills: $($Script:SkillsRoot)"
    Write-Host ''
    Write-Host '  1) Prerequisites - check tools, Python venv, and MYMERIT* env'
    Write-Host '  2) Ensure %MYMERITAPP%\merit-agent-skills (clone if needed)'
    Write-Host '  3) Seed clone merit-demo under %MYMERITAPP%'
    Write-Host '  4) OSS validate (closeout + smoke)'
    Write-Host '  5) Guidelines'
    Write-Host '  6) Show MERIT.json status'
    Write-Host '  M) Set / change MYMERITAPP bench folder'
    Write-Host '  T) Private-Vault teaser (public facts only)'
    Write-Host '  P) Seed Private-Vault BootStrap into ~/dev (needs vault access)'
    Write-Host '  0) Exit'
    Write-Host ''
}

function Install-BootStrapToOssRoot {
    # Repo: merit-agent-skills/BootStrap  ->  live: $MYMERITAPP\BootStrap (+ launcher)
    $src = $Script:BootStrapRoot
    $destRoot = Get-MyMeritAppRoot
    $dest = Join-Path $destRoot 'BootStrap'
    if (-not (Test-Path -LiteralPath $dest)) {
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
    }
    foreach ($f in @('MERIT_BootStrap.ps1', 'MERIT_BootStrap.cmd', 'MERIT_BootStrap.sh', 'MERIT.json', 'README.md')) {
        $from = Join-Path $src $f
        if (Test-Path -LiteralPath $from) {
            if ($f -eq 'MERIT.json' -and (Test-Path -LiteralPath (Join-Path $dest $f))) {
                continue  # keep local status JSON
            }
            Copy-Item -LiteralPath $from -Destination (Join-Path $dest $f) -Force
        }
    }
    $launcher = @"
@echo off
setlocal
if defined MYMERITAPP (set "ROOT=%MYMERITAPP%") else (set "ROOT=%~dp0")
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "PS1=%ROOT%\BootStrap\MERIT_BootStrap.ps1"
if not exist "%PS1%" set "PS1=%~dp0BootStrap\MERIT_BootStrap.ps1"
if not exist "%PS1%" (echo BootStrap missing. Set MYMERITAPP or run from bench root. & exit /b 1)
where pwsh >nul 2>&1 && (pwsh -NoProfile -File "%PS1%" %* & exit /b %ERRORLEVEL%)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
exit /b %ERRORLEVEL%
"@
    Set-Content -LiteralPath (Join-Path $destRoot 'MERIT_BootStrap.cmd') -Value $launcher -Encoding ASCII
    Write-Ok "OSS BootStrap installed/refreshed at $dest"
    Write-Note "Shortcut: $destRoot\MERIT_BootStrap.cmd  (MYMERITAPP=$destRoot)"
}

function Main {
    if (-not (Test-Path -LiteralPath $Script:JsonPath)) {
        Write-Fail "Missing $($Script:JsonPath)"
        exit 1
    }

    Write-Header 'MERIT OSS BootStrap'
    Write-Note 'Repo source: merit-agent-skills/BootStrap  ->  installs live copy under MYMERITAPP'
    [void](Ensure-MyMeritAppRoot)
    $Script:SkillsPinTag = Resolve-SkillsPinTag
    $leaf = Split-Path -Leaf $Script:BootStrapRoot
    # Install when running from a BootStrap folder
    if ($leaf -eq 'BootStrap') {
        Install-BootStrapToOssRoot
    }

    $state = Get-State
    Save-State $state

    while ($true) {
        Show-Menu
        $c = (Read-Host 'Select').Trim()
        switch ($c) {
            '1' { Invoke-Prereqs; Pause-Go }
            '2' { Invoke-EnsureBenchSkills; Pause-Go }
            '3' { Invoke-EnsureDemo; Pause-Go }
            '4' { Invoke-OssValidate; Pause-Go }
            '5' { Show-Guidelines; Pause-Go }
            '6' { Show-Status; Pause-Go }
            { $_ -in @('M', 'm') } { [void](Ensure-MyMeritAppRoot -ForcePrompt); Install-BootStrapToOssRoot; Pause-Go }
            { $_ -in @('T', 't') } { Show-VaultTeaser; Pause-Go }
            { $_ -in @('P', 'p') } { Invoke-SeedPrivateVaultDev; Pause-Go }
            '0' { Write-Info 'Bye.'; return }
            default { Write-Warn 'Unknown selection.'; Pause-Go }
        }
    }
}

Main

