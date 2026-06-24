# Install MERIT agent skills into Cursor or a project repo.
[CmdletBinding()]
param(
    [ValidateSet('Cursor', 'Project')]
    [string]$Target = 'Cursor',
    [string]$Path = ''
)

$ErrorActionPreference = 'Stop'
$repoRoot = $PSScriptRoot
$skillsSrc = Join-Path $repoRoot 'skills'
if (-not (Test-Path $skillsSrc)) {
    Write-Error "skills/ folder not found under $repoRoot"
}

if ($Target -eq 'Cursor') {
    $destRoot = Join-Path $env:USERPROFILE '.cursor\skills'
} else {
    if (-not $Path) {
        Write-Error 'Project install requires -Path <repo-root>'
    }
    $destRoot = Join-Path (Resolve-Path $Path).Path '.cursor\skills'
}

New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
$count = 0
Get-ChildItem -LiteralPath $skillsSrc -Directory | ForEach-Object {
    $target = Join-Path $destRoot $_.Name
    Write-Host "install $($_.Name) -> $target"
    Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
    $count++
}
Write-Host "Installed $count skills to $destRoot"
