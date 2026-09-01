# Fail if skills use ambiguous .\scripts\merit.ps1 without Operator gate.
#Requires -Version 5.1
param([switch]$Verbose)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$skillsDir = Join-Path $Root 'skills'
$bad = @()

Get-ChildItem -LiteralPath $skillsDir -Directory | ForEach-Object {
    $skill = Join-Path $_.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skill)) { return }
    $text = Get-Content -LiteralPath $skill -Raw -Encoding UTF8
    if ($text -match '(?m)^\s*\.\\\scripts\\merit\.ps1') {
        $bad += $_.Name
    }
    if ($text -match '(?m)^\s*\.\/scripts\/merit\.ps1') {
        $bad += $_.Name
    }
}

if ($bad.Count -gt 0) {
    Write-Host "FAIL: skills with .\scripts\merit.ps1 (use '<vault>\scripts\merit.ps1' under Operator section):" -ForegroundColor Red
    $bad | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" }
    exit 1
}

Write-Host 'test-skill-paths: OK (no ambiguous .\scripts\merit.ps1)' -ForegroundColor Green
exit 0
