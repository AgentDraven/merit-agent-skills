#Requires -Version 5.1
<#
.SYNOPSIS
  Merit-Hub â€” laptop cleanup (Pristine v2), jumpstart OSS/vault, shared tools (MYMERITTOOLS).

.DESCRIPTION
  Single standalone script — save as e.g. C:\Tools\Merit-Hub.ps1 (default %MYMERITTOOLS%). Pins are embedded; no .json or install helper required.
  Run with no args for interactive menu.

  Cleanup:
    -Pristine   backup + full cold-start wipe (~/dev folder, OSS bench, MERIT tools artifacts, env)
    -Soft       backup + wipe bench/status; keep ~/dev clones
    -BackupOnly snapshot only

  Jumpstart:
    -Jumpstart Oss|Vault   clone pinned release + launch repo BootStrap
    -Prereqs                 install/check git, gh, pwsh, MYMERITTOOLS Python venv

  Env (mirrors BootStrap):
    MYMERITAPP    OSS bench (default C:\MyMeritApp)
    MYMERITTOOLS  laptop tools root (default C:\Tools) â€” merit-venv, shims

.EXAMPLE
  pwsh -NoProfile -ExecutionPolicy Bypass -File .\Merit-Hub.ps1
  pwsh -File .\Merit-Hub.ps1 -Pristine -Force
  pwsh -File .\Merit-Hub.ps1 -Jumpstart Oss
  pwsh -File .\Merit-Hub.ps1 -Jumpstart Vault
  pwsh -File .\Merit-Hub.ps1 -Prereqs
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Pristine,
    [switch]$Soft,
    [switch]$BackupOnly,
    [ValidateSet('Oss', 'Vault')]
    [string]$Jumpstart,
    [switch]$Prereqs,
    [switch]$Force,
    [Alias('?')]
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:HubScriptPath = $PSCommandPath
if (-not $Script:HubScriptPath) { $Script:HubScriptPath = $MyInvocation.MyCommand.Path }
$Script:HubRoot = Split-Path -Parent $Script:HubScriptPath
$Script:BackupRoot = Join-Path $Script:HubRoot 'backups'
$Script:IsWindows = ($PSVersionTable.PSPlatform -eq 'Win32NT') -or ($env:OS -match 'Windows')

# Embedded release pins (no separate Merit-Hub.json required).
$Script:EmbeddedHubConfigJson = @'
{
  "schemaVersion": 1,
  "skillsPin": "skills-v0.5.2",
  "vaultPin": "vault-v0.5.3",
  "skillsUrl": "https://github.com/AgentDraven/merit-agent-skills.git",
  "vaultUrl": "https://github.com/AgentDraven/merit-private-vault.git",
  "vaultOwner": "AgentDraven",
  "vaultRepo": "merit-private-vault",
  "showcaseUrl": "https://github.com/Mr-PI-Bala/merit-demo.git",
  "defaultMyMeritAppWindows": "C:\\MyMeritApp",
  "defaultMyMeritAppUnix": "~/MyMeritApp",
  "defaultMyMeritToolsWindows": "C:\\Tools",
  "defaultMyMeritToolsUnix": "~/Tools",
  "devSubdir": "dev"
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
    if ($Script:IsWindows) {
        return Expand-HomePath ([string]$cfg.defaultMyMeritToolsWindows)
    }
    return Expand-HomePath ([string]$cfg.defaultMyMeritToolsUnix)
}

function Get-DefaultMyMeritApp {
    $cfg = Get-HubConfig
    if ($Script:IsWindows) {
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

function Set-UserEnvVar {
    param([string]$Name, [string]$Value)
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
    Write-Ok "$Name (User) = $Value"
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
                $isAdmin = $false
                if ($Script:IsWindows) {
                    try {
                        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                    }
                    catch { $isAdmin = $false }
                }
                if (-not $isAdmin) {
                    Write-Warn "Cannot clear Machine:$Name without admin (was $existing)"
                    continue
                }
            }
            [Environment]::SetEnvironmentVariable($Name, $null, $scope)
            Write-Ok "cleared $scope`:$Name (was $existing)"
        }
        catch {
            Write-Warn "Could not clear $scope`:$Name â€” $($_.Exception.Message)"
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
    if ($Script:IsWindows) {
        $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')
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
        Write-Warn "could not delete $Label (in use?): $($_.Exception.Message)"
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

    $readme = @"
# Merit-Hub backup $stamp

After **Pristine**, cold-start from the hub (no prior clone required):

``````powershell
$(Get-HubRunHint)
# J = Jumpstart OSS  |  V = Jumpstart Vault  |  1 = Prereqs only
``````

Pins: skills=$($cfg.skillsPin) vault=$($cfg.vaultPin)
"@
    Set-Content -LiteralPath (Join-Path $dir 'README.md') -Value $readme -Encoding UTF8
    Write-Ok 'README.md'
    return $dir
}

function Invoke-WipeMeritToolsArtifacts {
    param([bool]$IncludeGhShims = $true)
    $tools = Get-MyMeritToolsRoot
    Write-Info "MYMERITTOOLS = $tools"
    Remove-PathSafe -Path (Join-Path $tools 'merit-venv') -Label 'merit-venv'
    foreach ($f in @('merit-python.cmd', 'merit-python', 'merit-python.ps1')) {
        Remove-PathSafe -Path (Join-Path $tools $f) -Label $f
    }
    if ($IncludeGhShims) {
        foreach ($f in @('gh.cmd', 'gh')) {
            $p = Join-Path $tools $f
            if (Test-Path -LiteralPath $p -PathType Leaf) {
                $size = (Get-Item -LiteralPath $p).Length
                if ($size -lt 2048) {
                    Remove-PathSafe -Path $p -Label "Tools shim $f"
                }
                else {
                    Write-Info "skip large Tools\$f ($size bytes) â€” not assumed MERIT shim"
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
    Write-Info "MYMERITAPP: $oss (wipe=$DoWipeOss)"
    Write-Info "MYMERITTOOLS: $tools (wipe MERIT artifacts=$DoWipeToolsArtifacts)"
    Write-Info "~/dev:      $dev (wipe tree=$DoWipeDevTree)"
    Write-Info 'Will clear MYMERITAPP + MYMERITTOOLS (User/Machine/Process where allowed)'
    Write-Info 'Will remove ~/dev from User Path if present'

    if (-not $Force -and -not $WhatIfPreference) {
        Write-Host ''
        Write-Warn "Type $ConfirmWord to proceed (or -Force)."
        $ans = Read-Host 'Confirm'
        if ($ans -ne $ConfirmWord) {
            Write-Warn 'Aborted â€” backup kept.'
            return
        }
    }

    Write-Header "Cleanup ($ModeName)"

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
                Write-Warn "~/dev not empty after clone wipe â€” remaining: $($remaining.Name -join ', ')"
                Write-Info 'Remove manually or close handles, then re-run Pristine.'
            }
        }
    }

    Clear-EnvVarAllScopes -Name 'MYMERITAPP'
    if ($DoWipeToolsArtifacts) {
        Clear-EnvVarAllScopes -Name 'MYMERITTOOLS'
        Invoke-WipeMeritToolsArtifacts
    }

    Remove-PathFromUserEnvPath -PathsToRemove @($dev)

    if ($DoWipeOss -and -not [string]::IsNullOrWhiteSpace($oss)) {
        $fullOss = Expand-HomePath $oss
        $fullDev = Expand-HomePath $dev
        $hubNorm = Expand-HomePath $Script:HubScriptPath
        $hubDir = Expand-HomePath $Script:HubRoot
        if ($fullOss -in @([IO.Path]::GetFullPath('C:\'), Expand-HomePath $HOME)) {
            Write-Fail "Refusing to wipe unsafe OSS path: $fullOss"
        }
        elseif ($fullOss -eq $fullDev) {
            Write-Fail 'Refusing to wipe OSS bench that equals ~/dev'
        }
        elseif ($fullOss -eq $hubDir) {
            Write-Warn "OSS bench is Merit-Hub directory — skipping full delete of $fullOss"
            Get-ChildItem -LiteralPath $fullOss -Force -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.FullName -ne $hubNorm -and
                    $_.Name -notin @('Merit-Hub', 'backups') -and
                    $_.Name -notlike 'Merit-Hub.ps1'
                } |
                ForEach-Object { Remove-PathSafe -Path $_.FullName -Label "OSS child $($_.Name)" }
        }
        else {
            Remove-PathSafe -Path $fullOss -Label 'OSS bench (MYMERITAPP)'
        }
    }

    Write-Host ''
    Write-Ok "Cleanup finished ($ModeName)."
    Write-Info "Backup: $BackupDir"
    Write-Info "Cold start: $(Get-HubRunHint)  →  J Jumpstart OSS"
}

function Invoke-Mode {
    param([ValidateSet('Pristine', 'Soft', 'BackupOnly')]$Mode)
    switch ($Mode) {
        'Pristine' {
            Write-Header 'Mode: PRISTINE v2 (brand-new laptop)'
            Write-Info 'Wipes OSS bench, ~/dev tree, MYMERIT* env, merit-venv/shims under MYMERITTOOLS.'
            Write-Info "Keeps hub script: $Script:HubScriptPath"
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

function Test-Winget { return $Script:IsWindows -and [bool](Get-Command winget -ErrorAction SilentlyContinue) }

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
    if ($Script:IsWindows) {
        foreach ($c in @(
                (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
                (Join-Path $env:ProgramFiles 'Python312\python.exe')
            )) {
            if ($c -and (Test-Path -LiteralPath $c)) { return $c }
        }
    }
    return $null
}

function Install-MeritToolsPython {
    $tools = Get-MyMeritToolsRoot
    Set-UserEnvVar -Name 'MYMERITTOOLS' -Value $tools
    Write-Header "MERIT Python under MYMERITTOOLS ($tools)"
    $venvDir = Join-Path $tools 'merit-venv'
    $venvPy = if ($Script:IsWindows) { Join-Path $venvDir 'Scripts\python.exe' } else { Join-Path $venvDir 'bin/python3' }
    New-Item -ItemType Directory -Force -Path $tools | Out-Null
    if (Test-Path -LiteralPath $venvPy) {
        Write-Ok "Already present: $venvPy"
        if ($Script:IsWindows) {
            Set-Content -LiteralPath (Join-Path $tools 'merit-python.cmd') -Value "@echo off`r`n`"$venvPy`" %*`r`n" -Encoding ASCII
        }
        return $true
    }
    $base = Resolve-BasePythonExe
    if (-not $base) {
        if ($Script:IsWindows) {
            if (-not (Install-WingetPkg -Id 'Python.Python.3.12' -Name 'Python 3.12')) { return $false }
        }
        else {
            Write-Fail 'Install python3 via your package manager, then re-run.'
            return $false
        }
        Refresh-ProcessPath
        $base = Resolve-BasePythonExe
        if (-not $base) {
            Write-Fail 'Python not on PATH â€” open a new terminal and re-run.'
            return $false
        }
    }
    Write-Ok "Base Python: $base"
    & $base -m venv $venvDir
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $venvPy)) {
        Write-Fail "venv create failed at $venvDir"
        return $false
    }
    if ($Script:IsWindows) {
        Set-Content -LiteralPath (Join-Path $tools 'merit-python.cmd') -Value "@echo off`r`n`"$venvPy`" %*`r`n" -Encoding ASCII
    }
    Write-Ok "MERIT laptop Python: $venvPy"
    return $true
}

function Invoke-MeritPrereqs {
    Write-Header 'Prerequisites â€” check / install'
    $tools = Get-MyMeritToolsRoot
    Write-Ok "MYMERITTOOLS = $tools"
    Write-Ok "MYMERITAPP    = $(Get-MyMeritAppRoot)"
    Set-UserEnvVar -Name 'MYMERITTOOLS' -Value $tools

    $needGit = -not (Get-Command git -ErrorAction SilentlyContinue)
    $needPwsh = -not (Get-Command pwsh -ErrorAction SilentlyContinue)
    $needGh = $true
    $ghExe = $null
    if ($Script:IsWindows) {
        foreach ($c in @(
                (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'GitHub CLI\gh.exe')
            )) {
            if ($c -and (Test-Path -LiteralPath $c)) { $ghExe = $c; break }
        }
    }
    if (-not $ghExe) {
        $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
        if ($ghCmd -and $ghCmd.Source -and ($ghCmd.Source -notmatch '(?i)[\\/]Tools[\\/]gh')) {
            $ghExe = $ghCmd.Source
        }
    }
    if ($ghExe) { Write-Ok "gh â€” $ghExe"; $needGh = $false }
    else { Write-Warn 'gh â€” optional; install for PRs / identity' }

    if (-not $needGit) { Write-Ok ("Git â€” " + ((& git --version 2>&1 | Out-String).Trim())) }
    else { Write-Fail 'Git â€” missing' }
    if (-not $needPwsh) { Write-Ok 'pwsh â€” present' }
    else { Write-Warn 'pwsh â€” missing (Windows PowerShell 5.1 works for hub)' }

    $venvPy = if ($Script:IsWindows) { Join-Path $tools 'merit-venv\Scripts\python.exe' } else { Join-Path $tools 'merit-venv\bin\python3' }
    $needPy = -not (Test-Path -LiteralPath $venvPy)

    if (-not ($needGit -or $needPwsh -or $needGh -or $needPy)) {
        Write-Ok 'All hub prereqs present.'
        return
    }
    if ($Force) {
        if ($needGit) { [void](Install-WingetPkg -Id 'Git.Git' -Name 'Git') }
        if ($needPwsh) { [void](Install-WingetPkg -Id 'Microsoft.PowerShell' -Name 'PowerShell 7+') }
        if ($needGh) { [void](Install-WingetPkg -Id 'GitHub.cli' -Name 'GitHub CLI') }
        if ($needPy) { [void](Install-MeritToolsPython) }
        return
    }
    $ans = Read-Host 'Install missing tools now? [y/N]'
    if ($ans -notmatch '^[Yy]') { Write-Warn 'Skipped.'; return }
    if ($needGit) { [void](Install-WingetPkg -Id 'Git.Git' -Name 'Git') }
    if ($needPwsh) { [void](Install-WingetPkg -Id 'Microsoft.PowerShell' -Name 'PowerShell 7+') }
    if ($needGh) { [void](Install-WingetPkg -Id 'GitHub.cli' -Name 'GitHub CLI') }
    if ($needPy) { [void](Install-MeritToolsPython) }
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
        Write-Fail 'git not on PATH â€” run Prereqs (menu 1) first.'
        return $false
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Dest) | Out-Null
    $gitDir = Join-Path $Dest '.git'
    if (Test-Path -LiteralPath $gitDir) {
        Write-Ok "$Label already cloned: $Dest"
        Write-Info "Fetching / checking out $Pin ..."
        & git -C $Dest fetch --tags origin 2>&1 | Out-Host
        & git -C $Dest checkout --detach "refs/tags/$Pin" 2>&1 | Out-Host
        return ($LASTEXITCODE -eq 0)
    }
    if (Test-Path -LiteralPath $Dest) {
        Write-Fail "$Dest exists but is not a git clone â€” move aside and retry."
        return $false
    }
    Write-Info "Cloning $Url @ $Pin -> $Dest"
    & git clone --branch $Pin $Url $Dest
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "git clone failed (exit $LASTEXITCODE)"
        return $false
    }
    Write-Ok "Cloned $Label @ $Pin"
    return $true
}

function Invoke-JumpstartOss {
    $cfg = Get-HubConfig
    Write-Header "Jumpstart OSS @ $($cfg.skillsPin)"
    [void](Invoke-MeritPrereqs)
    $bench = Ensure-MyMeritAppPrompt
    $skillsDest = Join-Path $bench 'merit-agent-skills'
    $ok = Invoke-GitClonePin -Url ([string]$cfg.skillsUrl) -Pin ([string]$cfg.skillsPin) -Dest $skillsDest -Label 'merit-agent-skills'
    if (-not $ok) { return }

    $bootPs1 = Join-Path $skillsDest 'BootStrap\MERIT_BootStrap.ps1'
    $bootCmd = Join-Path $skillsDest 'BootStrap\MERIT_BootStrap.cmd'
    if (-not (Test-Path -LiteralPath $bootPs1)) {
        Write-Fail "BootStrap missing: $bootPs1"
        return
    }
    Write-Ok 'Launching repo OSS BootStrap (menus 1â€“4, P vault teaser) ...'
    Write-Note "Hub pins: skills=$($cfg.skillsPin) vault=$($cfg.vaultPin)"
    if (Test-Path -LiteralPath $bootCmd) {
        & $bootCmd
    }
    else {
        & $bootPs1
    }
}

function Invoke-JumpstartVault {
    $cfg = Get-HubConfig
    Write-Header "Jumpstart Vault @ $($cfg.vaultPin)"
    [void](Invoke-MeritPrereqs)
    $dev = Get-DevRoot
    $owner = [string]$cfg.vaultOwner
    if ([string]::IsNullOrWhiteSpace($owner)) { $owner = 'AgentDraven' }
    $repo = [string]$cfg.vaultRepo
    if ([string]::IsNullOrWhiteSpace($repo)) { $repo = 'merit-private-vault' }
    $vaultDest = Join-Path (Join-Path $dev $owner) $repo
    $ok = Invoke-GitClonePin -Url ([string]$cfg.vaultUrl) -Pin ([string]$cfg.vaultPin) -Dest $vaultDest -Label 'merit-private-vault'
    if (-not $ok) { return }

    $seedCmd = Join-Path $vaultDest 'BootStrap\seed-private-dev.cmd'
    $bootCmd = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.cmd'
    $bootPs1 = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.ps1'
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
    Write-Header 'Merit-Hub laptop hub'
    Write-Info "Location: $Script:HubScriptPath"
    Write-Info "MYMERITTOOLS: $(Get-MyMeritToolsRoot)  |  MYMERITAPP: $(Get-MyMeritAppRoot)"
    Write-Info "Pins: skills=$($cfg.skillsPin)  vault=$($cfg.vaultPin)"
    Write-Host ''
    Write-Host '  CLEANUP' -ForegroundColor White
    Write-Host '  P) Pristine v2   full cold-start wipe (+ merit-venv, ~/dev folder, env)' -ForegroundColor Green
    Write-Host '  S) Soft          bench + status; keep ~/dev clones'
    Write-Host '  B) Backup only'
    Write-Host ''
    Write-Host '  JUMPSTART' -ForegroundColor White
    Write-Host '  J) Jumpstart OSS    clone skills pin + launch repo BootStrap'
    Write-Host '  V) Jumpstart Vault  clone vault pin + launch vault BootStrap'
    Write-Host '  1) Prereqs only     git / gh / pwsh / MYMERITTOOLS Python'
    Write-Host ''
    Write-Host '  M) Set MYMERITAPP bench path'
    Write-Host '  T) Set MYMERITTOOLS root (shows current; persists User env)'
    Write-Host '  H) Help'
    Write-Host '  0) Exit'
    Write-Host ''
    Write-Note 'After Pristine: J is the only file you need â€” no manual git clone first.'
}

function Set-MyMeritToolsPrompt {
    $current = Get-MyMeritToolsRoot
    Write-Note "Laptop tools root (merit-venv, shims). Default: $(Get-DefaultMyMeritTools)"
    $ans = Read-Host "MYMERITTOOLS path [$current]"
    $path = if ([string]::IsNullOrWhiteSpace($ans)) { $current } else { $ans }
    Set-UserEnvVar -Name 'MYMERITTOOLS' -Value (Expand-HomePath $path)
}

function Show-InteractiveMenu {
    while ($true) {
        Show-MeritHubHelp
        Write-Host '  Recommended cold start:  J' -ForegroundColor Yellow
        Write-Host ''
        $c = (Read-Host 'Select').Trim()
        switch -Regex ($c) {
            '^(P|p|Pristine)$' { Invoke-Mode -Mode Pristine; return }
            '^(S|s|Soft)$' { Invoke-Mode -Mode Soft; return }
            '^(B|b|BackupOnly)$' { Invoke-Mode -Mode BackupOnly; return }
            '^(J|j|Jumpstart|Oss)$' { Invoke-JumpstartOss; return }
            '^(V|v|Vault)$' { Invoke-JumpstartVault; return }
            '^1$' { Invoke-MeritPrereqs; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('M', 'm') } { Ensure-MyMeritAppPrompt | Out-Null; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('T', 't') } { Set-MyMeritToolsPrompt; Read-Host 'Press Enter' | Out-Null }
            '^(H|h|\?|Help)$' { continue }
            '^(0|Q|q|Exit)$' { Write-Info 'Bye.'; return }
            default { Write-Warn 'Unknown â€” choose P, S, B, J, V, 1, M, T, H, or 0.' }
        }
    }
}

# --- main ---
New-Item -ItemType Directory -Force -Path $Script:BackupRoot | Out-Null

if ($Help) {
    Show-MeritHubHelp
    return
}

if ($Pristine) { Invoke-Mode -Mode Pristine; return }
if ($Soft) { Invoke-Mode -Mode Soft; return }
if ($BackupOnly) { Invoke-Mode -Mode BackupOnly; return }
if ($Prereqs) { Invoke-MeritPrereqs; return }
if ($Jumpstart -eq 'Oss') { Invoke-JumpstartOss; return }
if ($Jumpstart -eq 'Vault') { Invoke-JumpstartVault; return }

$bound = $PSBoundParameters.Keys
$hasAction = @('Pristine', 'Soft', 'BackupOnly', 'Prereqs', 'Jumpstart', 'Help') | Where-Object { $bound -contains $_ }
if (-not $hasAction) {
    Show-InteractiveMenu
}

