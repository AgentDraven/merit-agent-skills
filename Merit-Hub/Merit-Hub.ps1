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
    -Vc                    Venture Capable receipt after local vault
    -JoinMerit             portal / partners / register links
    -InstallSkills <host>  copy skills/ to Cursor, Codex, Hermes, ... (needs OSS clone; menu I)
    -Prereqs                 install/check git, gh, pwsh, MYMERITTOOLS Python venv

  Recommended runner: PowerShell 7+ (pwsh). Windows PowerShell 5.1 can bootstrap the hub once.

  Env (mirrors BootStrap):
    MYMERITAPP    OSS bench (default C:\MyMeritApp)
    MYMERITTOOLS  laptop tools root (default C:\Tools) - merit-venv, shims

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
    [switch]$Vc,
    [switch]$JoinMerit,
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
$Script:HistoryLog = Join-Path $Script:BackupRoot 'Merit-Hub-history.log'
$Script:TranscriptStarted = $false
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
  "skillsPin": "skills-v0.5.25",
  "vaultPin": "vault-v0.5.8",
  "agentCloseoutRequired": true,
  "agentCloseout": "Never end a completed scope without merit.ps1 mXin + git verify + chat 3-3 (Done, State with VERSION/tag, Next). Exception only if user said WIP / no commit / local-only.",
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
    foreach ($key in @($PSBoundParameters.Keys)) {
        $val = $PSBoundParameters[$key]
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

function Set-UserEnvVar {
    param([string]$Name, [string]$Value)
    $existing = [Environment]::GetEnvironmentVariable($Name, 'User')
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
    if ($existing -eq $Value) {
        Write-Ok "$Name User env already set = $Value"
        return
    }
    Write-Ok "SET User env $Name = $Value (was $(if ($existing) { $existing } else { 'empty' }))"
    Write-Note 'Open a NEW terminal to see User env in other windows. This process already has it.'
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
    param([string]$ConfiguredOss)
    $seen = @{}
    $targets = @()
    foreach ($p in @($ConfiguredOss, (Get-DefaultMyMeritApp))) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $full = Expand-HomePath $p
        if ($seen.ContainsKey($full)) { continue }
        $seen[$full] = $true
        $targets += $full
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
    $benches = New-Object System.Collections.Generic.List[string]
    foreach ($p in @((Get-MyMeritAppRoot), (Get-DefaultMyMeritApp))) {
        if ([string]::IsNullOrWhiteSpace($p)) { continue }
        $full = Expand-HomePath $p
        if (-not $benches.Contains($full)) { [void]$benches.Add($full) }
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
        Write-Ok 'No catalog leftovers (HumanBala, DravenCode.OLD, Code, *Merit*, …)'
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
    param([bool]$IncludeGhShims = $true)
    $tools = Get-MyMeritToolsRoot
    Write-Info "MYMERITTOOLS = $tools"
    Invoke-WipeLegacyMeritHubFolder
    Remove-PathSafe -Path (Join-Path $tools 'merit-venv') -Label 'merit-venv'
    foreach ($f in @('merit-python.cmd', 'merit-python', 'merit-python.ps1', 'pwsh.cmd')) {
        Remove-PathSafe -Path (Join-Path $tools $f) -Label $f
    }
    # Keep %MYMERITTOOLS%\pwsh\ tree on Pristine (re-download via menu 1); remove only if empty aside shim
    if ($IncludeGhShims) {
        foreach ($f in @('gh.cmd', 'gh')) {
            $p = Join-Path $tools $f
            if (Test-Path -LiteralPath $p -PathType Leaf) {
                $size = (Get-Item -LiteralPath $p).Length
                if ($size -lt 2048) {
                    Remove-PathSafe -Path $p -Label "Tools shim $f"
                }
                else {
                    Write-Info ('skip large Tools\' + $f + ' (' + $size + ' bytes) - not assumed MERIT shim')
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

    Clear-EnvVarAllScopes -Name 'MYMERITAPP'
    if ($DoWipeToolsArtifacts) {
        Clear-EnvVarAllScopes -Name 'MYMERITTOOLS'
        Invoke-WipeMeritToolsArtifacts
    }
    Write-Note 'MYMERITAPP / MYMERITTOOLS cleared. Next interactive run will prompt (Enter = defaults).'
    Write-HubEnvScopes

    Remove-PathFromUserEnvPath -PathsToRemove @($dev)

    if ($DoWipeOss) {
        Invoke-WipeOssBenches -ConfiguredOss $oss
    }

    if ($ModeName -eq 'Pristine') {
        Invoke-RogueFolderReview
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
            Write-Info 'Wipes OSS bench (MYMERITAPP and default C:\MyMeritApp), leftover Tools\Merit-Hub folder, ~/dev tree, MYMERIT* env, merit-venv/shims.'
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
    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path -LiteralPath $cmd.Source)) { return $cmd.Source }
    if ($Script:HubOnWindows) {
        foreach ($c in @(
                (Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'),
                (Join-Path ${env:ProgramFiles(x86)} 'PowerShell\7\pwsh.exe')
            )) {
            if ($c -and (Test-Path -LiteralPath $c)) { return $c }
        }
    }
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
    $bench = Get-MyMeritAppRoot
    return Join-Path $bench 'merit-agent-skills'
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
    return $true
}

function Write-HubMap {
    param([string]$Here = '')
    $mark = {
        param([string]$Step, [string]$Text)
        if ($Here -and $Step -eq $Here) { return "* $Text" }
        return "  $Text"
    }
    Write-Host ''
    Write-Host '  MAP (always)   * = you are here' -ForegroundColor White
    Write-Host ('  ' + (& $mark '1' '1 Setup laptop'))
    Write-Host '         |'
    Write-Host '         v'
    Write-Host ('  ' + (& $mark '2' '2 Install OSS  (J)'))
    Write-Host '         |'
    Write-Host ('         +--> ' + (& $mark '3' '3 Try it') + ' --> ' + (& $mark 'OC' 'OC  OSS in the Cloud'))
    Write-Host ('         +--> ' + (& $mark '4' '4 Vault (V, still local)') + ' --> ' + (& $mark 'VC' 'VC  Venture Capable'))
    Write-Host ('         +--> ' + (& $mark '5' '5 Join MERIT'))
    Write-Host '         +--> 0 Stop'
}

function Write-HubDrillIn {
    param([string]$Step)
    switch ($Step) {
        '1' { Write-Note 'Drill-in: git / gh / pwsh + MERIT Python venv under MYMERITTOOLS. Persist MYMERIT*. Not hosted.' }
        '2' { Write-Note 'Drill-in: clone skills pin + merit-demo; quiet smoke. Old D+G live here. Not cloud.' }
        '3' { Write-Note 'Drill-in: open local merit-demo\play\index.html. Still not hosted.' }
        'OC' { Write-Note 'Drill-in: publish play+cfg + portal/ marketing site to merit-prod; store activate MUST succeed. here.now is a platform-key upgrade (no laptop key).' }
        '4' { Write-Note 'Drill-in: clone private vault into ~/dev. Still local. Not VC yet.' }
        'VC' { Write-Note 'Drill-in: operator/tenant grade vs freeware OC. Vault BootStrap on this laptop.' }
        '5' { Write-Note 'Drill-in: links only - portal, partners, register. Affiliate is ?affiliate= on register, not a here.now slug.' }
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
            if ($playUrl) { Write-Ok "play      : $playUrl" } else { Write-Warn 'play URL missing' }
            if ($regUrl) { Write-Ok "register  : $regUrl" } else { Write-Warn 'register URL missing (activate required)' }
            if ($portalUrl) { Write-Ok "portal    : $portalUrl" } else { Write-Warn 'marketing portal missing - OC publishes the demo portal/ tree' }
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
            Write-Note 'Still local. VC is the operator/cloud grade after this clone.'
        }
        'VC' {
            if (Test-Path -LiteralPath (Join-Path $vault '.git')) { Write-Ok "Vault local: $vault" } else { Write-Warn 'Run 4 first (clone vault).' }
            Write-Note 'OC = freeware Community Member on merit-prod. VC = operator/tenant grade (vault BootStrap, operator gate).'
        }
        '5' {
            Write-Info 'https://merit-prod.vercel.app/portal/'
            Write-Info 'https://merit-prod.vercel.app/portal/partners.html'
            Write-Info 'After OC: https://merit-prod.vercel.app/store/{your-oc-id}/register'
            Write-Note 'Affiliate attribution: ?affiliate= on the register URL. Not a here.now slug.'
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
    if (-not (Get-Command Get-OssState -ErrorAction SilentlyContinue)) {
        Write-Fail "OSS helpers did not load Get-OssState from $oss (dot-source Hub at script scope)."
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
    if ([string]::IsNullOrWhiteSpace($cid) -or $cid -notmatch '^oc-') {
        $cid = New-HubOcConsumerId
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
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "OC failed (exit $LASTEXITCODE). Play publish, store activate, and the marketing portal are all required; play-only is not OC-done."
        foreach ($line in @($ocLines | ForEach-Object { "$_" } | Select-Object -Last 8)) {
            if ($line.Trim()) { Write-Note "  $line" }
        }
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

function Invoke-HubJoinMerit {
    Write-Header '5 Join MERIT'
    Write-HubMap -Here '5'
    Write-HubDrillIn '5'
    Write-HubReceipt '5'
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

function Get-HubOssInternalScript {
    $bench = Get-MyMeritAppRoot
    return Join-Path $bench 'merit-agent-skills\BootStrap\_oss.ps1'
}

function Enter-HubOssPhase {
    param([switch]$Chain)
    Remove-RetiredOssLiveBootStrap
    Invoke-HubInstallOss -SkipPrereqs:$false
}

function Invoke-JumpstartVault {
    $cfg = Get-HubConfig
    Write-Header "4 Vault (local) @ $($cfg.vaultPin)"
    Write-HubMap -Here '4'
    Write-HubDrillIn '4'
    [void](Invoke-MeritPrereqs)
    $vaultDest = Get-HubVaultDest
    $ok = Invoke-GitClonePin -Url ([string]$cfg.vaultUrl) -Pin ([string]$cfg.vaultPin) -Dest $vaultDest -Label 'merit-private-vault'
    if (-not $ok) { return }

    Write-HubReceipt '4'
    $seedCmd = Join-Path $vaultDest 'BootStrap\seed-private-dev.cmd'
    $bootCmd = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.cmd'
    $bootPs1 = Join-Path $vaultDest 'BootStrap\MERIT_BootStrap.ps1'
    $go = Read-Host 'Launch vault BootStrap now? [y/N] (needed before VC operator menus)'
    if ($go -notmatch '^[Yy]') {
        Write-Note 'Vault is local. Run VC when you want the operator/cloud grade receipt.'
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
    Write-Host '  OC) OSS in the Cloud  DualRail play + register + here.now portal'
    Write-Host '  4) Vault            clone private vault (still local)       (alias V)'
    Write-Host '  VC) Venture Capable operator/tenant grade vs freeware OC'
    Write-Host '  5) Join MERIT       portal / partners / register links'
    Write-Host '  0) Stop'
    Write-Host ''
    Write-Host '  ALSO' -ForegroundColor White
    Write-Host '  P) Pristine v2   full cold-start wipe'
    Write-Host '  S) Soft          bench + status; keep ~/dev clones'
    Write-Host '  B) Backup only'
    Write-Host '  I) Install skills   Cursor, Codex, Hermes, ...'
    Write-Host '  M) Set MYMERITAPP bench path'
    Write-Host '  T) Set MYMERITTOOLS root'
    Write-Host '  H) Help'
    Write-Host ''
    Write-Note 'Cold start: 1 then 2. Do not double-click this file. ASCII hyphens only in this script.'
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
            '^5$' { Invoke-HubJoinMerit; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('I', 'i', 'Install', 'InstallSkills') } { Invoke-InstallSkillsMenu; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('M', 'm') } { Ensure-MyMeritAppPrompt | Out-Null; Read-Host 'Press Enter' | Out-Null }
            { $_ -in @('T', 't') } { Set-MyMeritToolsPrompt; Read-Host 'Press Enter' | Out-Null }
            '^(H|h|\?|Help)$' { continue }
            '^(0|Q|q|Exit)$' { Write-Info 'Bye.'; return }
            default { Write-Warn 'Unknown - choose 1, 2, 3, OC, 4, VC, 5, 0 (or P S B I M T H).' }
        }
    }
}

# --- main ---
if ($Help) {
    Show-MeritHubHelp
    return
}
Ensure-HubElevated
$ossHelpers = Get-HubOssInternalScript
if (Test-Path -LiteralPath $ossHelpers) {
    . $ossHelpers
}
New-Item -ItemType Directory -Force -Path $Script:BackupRoot | Out-Null
Start-HubTranscript
try {
    if ($Pristine) { Invoke-Mode -Mode Pristine; return }
    if ($Soft) { Invoke-Mode -Mode Soft; return }
    if ($BackupOnly) { Invoke-Mode -Mode BackupOnly; return }
    if ($Prereqs) { Invoke-HubSetupLaptop; return }
    if ($InstallSkills) {
        [void](Invoke-InstallMeritSkills -Target $InstallSkills -ProjectPath $InstallSkillsPath)
        return
    }
    if ($OssPhase -or $InstallOss) { Invoke-HubInstallOss; return }
    if ($TryIt) { Invoke-HubTryIt; return }
    if ($Oc) { Invoke-HubOc; return }
    if ($Vc) { Invoke-HubVc; return }
    if ($JoinMerit) { Invoke-HubJoinMerit; return }
    if ($Jumpstart -eq 'Oss') { Invoke-HubInstallOss; return }
    if ($Jumpstart -eq 'Vault') { Invoke-JumpstartVault; return }

    $bound = $PSBoundParameters.Keys
    $hasAction = @('Pristine', 'Soft', 'BackupOnly', 'Prereqs', 'Jumpstart', 'InstallSkills', 'Help', 'OssPhase', 'InstallOss', 'TryIt', 'Oc', 'Vc', 'JoinMerit') | Where-Object { $bound -contains $_ }
    if (-not $hasAction) {
        Show-InteractiveMenu
    }
}
finally {
    Complete-HubSession
}

