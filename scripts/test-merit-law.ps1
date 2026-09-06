# Merit law pack tests.
#Requires -Version 5.1
param([switch]$Verbose)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
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

Assert-Test 'merit.blob exists' {
    if (-not (Test-Path (Join-Path $Root 'merit.blob'))) { throw 'missing merit.blob' }
}

Assert-Test 'cfg/merit_law.json exists' {
    if (-not (Test-Path (Join-Path $Root 'cfg\merit_law.json'))) { throw 'missing manifest' }
}

Assert-Test 'closeout contract exists and requires 3-3' {
    $path = Join-Path $Root 'cfg\merit_closeout_contract.json'
    if (-not (Test-Path $path)) { throw 'missing closeout contract' }
    $contract = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($contract.contractId -ne 'MERIT-CLOSEOUT-1') { throw 'unexpected closeout contract id' }
    if ($contract.chatThreeThreeRequired -ne $true) { throw 'chat 3-3 is not required' }
    foreach ($name in @('lawCommand', 'validationCommand', 'ossReleaseCommand', 'operatorReleaseCommand')) {
        if ([string]::IsNullOrWhiteSpace([string]$contract.$name)) { throw "missing contract field $name" }
    }
}

Assert-Test 'merit-closeout skill requires law, release, and 3-3' {
    $skill = Get-Content -LiteralPath (Join-Path $Root 'skills\merit-closeout\SKILL.md') -Raw
    foreach ($needle in @('law closeout', 'ship', 'mXin', '3-3')) {
        if ($skill -notmatch [regex]::Escape($needle)) { throw "skill missing $needle" }
    }
}

. (Join-Path $Root 'BootStrap\_law.ps1')
$Script:MeritResolveRepoRoot = $Root

Assert-Test 'Read-MeritLawPack unpacks' {
    $pack = Read-MeritLawPack -RepoRoot $Root
    if (-not $pack.sections -or @($pack.sections).Count -lt 10) { throw 'expected >=10 sections' }
}

Assert-Test 'VIII.F closeout section present' {
    $s = Get-MeritLawSection -SectionId 'VIII.F' -RepoRoot $Root
    if (-not $s -or -not $s.body) { throw 'missing VIII.F body' }
}

Assert-Test 'skill map merit-closeout' {
    $secs = Get-MeritLawForSkill -SkillName 'merit-closeout' -RepoRoot $Root
    if ($secs.Count -lt 2) { throw 'expected multiple sections' }
}

Assert-Test 'merit.ps1 law list exit 0' {
    & pwsh -NoProfile -File (Join-Path $Root 'merit.ps1') law list
    if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
}

Assert-Test 'merit.ps1 law closeout exit 0' {
    & pwsh -NoProfile -File (Join-Path $Root 'merit.ps1') law closeout 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }
}

Write-Host ''
Write-Host "test-merit-law: $passed passed, $failed failed"
if ($failed -gt 0) { exit 1 }
exit 0
