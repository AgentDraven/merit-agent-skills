# Install MERIT agent skills into an AI IDE host (or a project repo).
# No default target — omit -Target to print usage (same pattern as merit.ps1 help).
[CmdletBinding()]
param(
    [string]$Target,
    [string]$Path = '',
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

function Write-InstallUsage {
    Write-Host @"
install.ps1 - install MERIT agent skills into an AI IDE host

Usage:
  .\install.ps1 -Target <host>
  .\install.ps1 -Target Project -Path <repo-root>
  ./install.sh -Target <host>          # Linux/macOS (requires pwsh/powershell)

Targets:
  Cursor       -> ~/.cursor/skills
  ClaudeCode   -> ~/.claude/skills     (alias: Claude)
  Codex        -> ~/.codex/skills      (or `$CODEX_HOME/skills)
  VSCode       -> ~/.agents/skills     (alias: Agents)
  Project      -> <repo>/.cursor/skills  (requires -Path)

Examples:
  .\install.ps1 -Target Cursor
  .\install.ps1 -Target ClaudeCode
  .\install.ps1 -Target Codex
  .\install.ps1 -Target VSCode
  .\install.ps1 -Target Project -Path ..\my-app

Re-run after git pull to refresh installed skills. Existing skill folders are replaced (not nested).
"@
}

$known = @('Cursor', 'ClaudeCode', 'Claude', 'Codex', 'VSCode', 'Agents', 'Project')

if ($Help -or [string]::IsNullOrWhiteSpace($Target)) {
    Write-InstallUsage
    if ($Help) { exit 0 }
    exit 1
}

if ($known -notcontains $Target) {
    Write-InstallUsage
    Write-Error "Unknown -Target '$Target'. Use one of: $($known -join ', ')"
}

$repoRoot = $PSScriptRoot
$skillsSrc = Join-Path $repoRoot 'skills'
if (-not (Test-Path $skillsSrc)) {
    Write-Error "skills/ folder not found under $repoRoot"
}

$homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
if (-not $homeRoot) {
    Write-Error 'USERPROFILE/HOME is not set'
}

$resolved = switch ($Target) {
    'Claude' { 'ClaudeCode' }
    'Agents' { 'VSCode' }
    default { $Target }
}

switch ($resolved) {
    'Cursor' {
        $destRoot = Join-Path $homeRoot '.cursor\skills'
    }
    'ClaudeCode' {
        $destRoot = Join-Path $homeRoot '.claude\skills'
    }
    'Codex' {
        $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $homeRoot '.codex' }
        $destRoot = Join-Path $codexHome 'skills'
    }
    'VSCode' {
        # Open Agent Skills user path (VS Code / Copilot-style hosts + Agents alias)
        $destRoot = Join-Path $homeRoot '.agents\skills'
    }
    'Project' {
        if (-not $Path) {
            Write-InstallUsage
            Write-Error 'Project install requires -Path <repo-root>'
        }
        $destRoot = Join-Path (Resolve-Path $Path).Path '.cursor\skills'
    }
}

New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
$count = 0
Get-ChildItem -LiteralPath $skillsSrc -Directory | ForEach-Object {
    $destSkill = Join-Path $destRoot $_.Name
    # Replace the skill folder atomically. Copy-Item into an existing directory
    # nests as dest/name/name (duplicate SKILL.md discovery in Cursor/hosts).
    if (Test-Path -LiteralPath $destSkill) {
        Remove-Item -LiteralPath $destSkill -Recurse -Force
    }
    Write-Host "install $($_.Name) -> $destSkill"
    Copy-Item -LiteralPath $_.FullName -Destination $destSkill -Recurse -Force
    $count++
}
Write-Host "Installed $count skills to $destRoot (Target=$Target)"
