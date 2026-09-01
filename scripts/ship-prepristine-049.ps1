#Requires -Version 5.1
# Ship skills-v0.5.49 (Pre-Pristine in Hub). Run once from any pwsh.
$ErrorActionPreference = 'Stop'
Set-Location C:\DevApps\merit-agent-skills
$env:MERIT_HUB_NO_ELEVATE = '1'

Write-Host '=== PrePristine smoke ===' -ForegroundColor Cyan
& pwsh -NoProfile -ExecutionPolicy Bypass -File .\Merit-Hub\Merit-Hub.ps1 -PrePristine
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "PrePristine exit $LASTEXITCODE" }

Write-Host '=== export law blob ===' -ForegroundColor Cyan
& pwsh -NoProfile -File .\scripts\export-merit-law-blob.ps1 -SkillsVersion 0.5.49

Write-Host '=== tests ===' -ForegroundColor Cyan
& pwsh -NoProfile -File .\scripts\test-merit-law.ps1
& pwsh -NoProfile -File .\scripts\test-merit-surface.ps1
& pwsh -NoProfile -File .\scripts\test-skill-paths.ps1

Write-Host '=== closeout + ship ===' -ForegroundColor Cyan
& pwsh -NoProfile -File .\merit.ps1 law closeout
& pwsh -NoProfile -File .\merit.ps1 closeout --path .
& pwsh -NoProfile -File .\merit.ps1 ship -Message 'feat: Hub built-in Pre-Pristine archive (-PrePristine / menu A)'

$src = 'C:\DevApps\merit-agent-skills\Merit-Hub\Merit-Hub.ps1'
foreach ($destRoot in @('C:\DevTools', 'C:\Tools')) {
    if (-not (Test-Path $destRoot)) { continue }
    $dest = Join-Path $destRoot 'Merit-Hub.ps1'
    Copy-Item $src $dest -Force
    Unblock-File $dest -ErrorAction SilentlyContinue
    Write-Host "Installed Hub -> $dest"
}
Write-Host 'DONE skills-v0.5.49' -ForegroundColor Green
