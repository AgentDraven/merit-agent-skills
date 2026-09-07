# Regression coverage for the standalone launcher; never runs the real Hub.
param([switch]$LiveDownload)
$ErrorActionPreference = 'Stop'
$source = Join-Path (Split-Path -Parent $PSScriptRoot) 'Merit-Hub.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('merit-launcher-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$launcher = Join-Path $testRoot 'Merit-Hub-B.ps1'
$installed = Join-Path $testRoot 'Merit-Hub\Merit-Hub.ps1'
$marker = Join-Path $testRoot 'Merit-Hub\started.txt'
$utf8 = New-Object Text.UTF8Encoding($true)
function Assert-Test([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message"
}

Copy-Item -LiteralPath $source -Destination $launcher
if ($LiveDownload) {
    # Exercise real download, decoding, parsing and installation, but skip Hub
    # invocation (it can prompt, install prerequisites and change this device).
    $code = [IO.File]::ReadAllText($launcher).Replace('& $implementation @args', "Write-Host 'Real Hub invocation skipped by test'")
    [IO.File]::WriteAllText($launcher, $code, $utf8)
    & $launcher
    Assert-Test ($LASTEXITCODE -eq 0) 'live GitHub download and current-host parse'
    $bytes = [IO.File]::ReadAllBytes($installed)
    Assert-Test ($bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) 'installed UTF-8 BOM'
    Write-Host "Evidence files: $testRoot"
    exit 0
}

$testContext = [pscustomobject]@{ Requests = 0; Scenario = 'good' }
function Invoke-WebRequest {
    param([Uri]$Uri, [string]$OutFile, [hashtable]$Headers, [switch]$UseBasicParsing, [string]$ErrorAction)
    Assert-Test ($Uri.IsAbsoluteUri -and $Uri.Host -eq 'raw.githubusercontent.com' -and $Uri.AbsolutePath.EndsWith('/Merit-Hub/Merit-Hub.ps1')) 'complete download URI'
    $testContext.Requests++
    if ($testContext.Scenario -eq 'network') { throw 'Simulated network unavailable' }
    if ($testContext.Scenario -eq 'html') { [IO.File]::WriteAllText($OutFile, '<html>error page</html>'); return }
    if ($testContext.Scenario -eq 'syntax') { [IO.File]::WriteAllText($OutFile, '# "skillsPin": "skills-v1.2.3"' + "`n'broken"); return }
    $fixture = @'
# "skillsPin": "skills-v1.2.3"
if ($args[0] -ne 'forwarded-argument') { throw 'Launcher lost arguments' }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'started.txt'), 'started')
exit 0
'@
    # Include a box character encoded without a BOM to test 5.1 normalization.
    $fixture = '# ' + [char]0x2502 + "`n" + $fixture
    [IO.File]::WriteAllText($OutFile, $fixture, (New-Object Text.UTF8Encoding($false)))
}
& $launcher 'forwarded-argument'
Assert-Test ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $marker)) 'missing-file download, launch and argument forwarding'
& $launcher 'forwarded-argument'
Assert-Test ($testContext.Requests -eq 2) 'existing implementation always refreshed'
$goodHash = (Get-FileHash -LiteralPath $installed).Hash
Remove-Item -LiteralPath $marker
foreach ($case in @('network', 'html', 'syntax')) {
    $testContext.Scenario = $case
    $caught = $false
    try { & $launcher 'forwarded-argument' } catch { $caught = $true }
    Assert-Test $caught "$case failure reported"
    Assert-Test ((Get-FileHash -LiteralPath $installed).Hash -eq $goodHash) "$case failure preserves cached file"
    Assert-Test (-not (Test-Path -LiteralPath $marker)) "$case failure does not execute stale cache"
    Assert-Test (@(Get-ChildItem (Split-Path $installed) -Filter '*.download.ps1').Count -eq 0) "$case staging file removed"
}
Write-Host "Host: $($PSVersionTable.PSVersion); evidence fixtures: $testRoot"
