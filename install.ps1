# Install MERIT agent skills into an AI IDE host (or a project repo).
[CmdletBinding()]
param(
    # Canonical: Cursor | ClaudeCode | Codex | VSCode | Project
    # Aliases:   Claude (=ClaudeCode) | Agents (=VSCode)
    [ValidateSet('Cursor', 'ClaudeCode', 'Claude', 'Codex', 'VSCode', 'Agents', 'Project')]
    [string]$Target = 'Cursor',
    [string]$Path = ''
)

$ErrorActionPreference = 'Stop'
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
