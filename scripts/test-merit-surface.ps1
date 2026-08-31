# Table-driven Merit Surface resolver tests (no vault required).
#Requires -Version 5.1
param([switch]$Verbose)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$resolve = Join-Path $Root 'BootStrap\_resolve.ps1'
if (-not (Test-Path -LiteralPath $resolve)) { throw "missing $resolve" }

$Script:MeritResolveRepoRoot = $Root
. $resolve

$passed = 0
$failed = 0

function Assert-Test {
    param([string]$Name, [scriptblock]$Test)
    try {
        & $Test
        $script:passed++
        if ($Verbose) { Write-Host "PASS $Name" -ForegroundColor Green }
    }
    catch {
        $script:failed++
        Write-Host "FAIL $Name — $($_.Exception.Message)" -ForegroundColor Red
    }
}

Assert-Test 'Test-MeritSkillsRoot accepts repo' {
    if (-not (Test-MeritSkillsRoot $Root)) { throw 'repo root should be valid B' }
}

Assert-Test 'Test-MeritSkillsRoot rejects missing path' {
    if (Test-MeritSkillsRoot 'C:\no-such-merit-bench-xyz') { throw 'expected false' }
}

Assert-Test 'Get-MeritEdition matrix' {
    if ((Get-MeritEdition -HasA $false -HasB $false -HasC $false) -ne 'none') { throw 'none' }
    if ((Get-MeritEdition -HasA $true -HasB $false -HasC $false) -ne 'ide-only') { throw 'ide-only' }
    if ((Get-MeritEdition -HasA $false -HasB $true -HasC $false) -ne 'oss') { throw 'oss' }
    if ((Get-MeritEdition -HasA $true -HasB $true -HasC $true) -ne 'full') { throw 'full' }
}

Assert-Test 'Get-MeritSurface -NoWrite in CI checkout' {
    $surf = Get-MeritSurface -NoWrite
    if (-not $surf.edition) { throw 'edition missing' }
    if (-not $surf.skillsRepoRoot) { throw 'expected B in checkout' }
    if (-not (Test-Path -LiteralPath $surf.publicMeritCli)) { throw 'publicMeritCli missing' }
    if ($surf.edition -notin @('oss', 'oss+ide', 'oss+vault', 'full')) {
        throw "unexpected edition in CI: $($surf.edition)"
    }
}

Assert-Test 'Resolve-MeritSkillsRepoRoot finds checkout' {
    $r = Resolve-MeritSkillsRepoRoot
    if (-not $r.Root) { throw 'no skills root' }
    if (-not (Test-MeritSkillsRoot $r.Root)) { throw 'resolved path invalid' }
}

Assert-Test 'merit.ps1 where -NoWrite exits 0' {
    $merit = Join-Path $Root 'merit.ps1'
    & pwsh -NoProfile -File $merit where -NoWrite
    if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
}

Write-Host ''
Write-Host "test-merit-surface: $passed passed, $failed failed"
if ($failed -gt 0) { exit 1 }
exit 0
