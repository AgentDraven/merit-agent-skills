param([Parameter(Mandatory)][string]$BenchRoot)
$ErrorActionPreference='Stop'
$statePath=Join-Path $BenchRoot 'oss-bench.json'; if(!(Test-Path $statePath)){throw "oss-bench.json not found: $statePath"}
$s=Get-Content $statePath -Raw|ConvertFrom-Json
$items=@(
 @{Name='Hosted play';Url=$s.ocPlayUrl;Expect='Hosted OC app'},
 @{Name='Register free';Url=$s.ocRegisterUrl;Expect='Hosted registration'},
 @{Name='Marketing portal';Url=$s.ocPortalUrl;Expect='Hosted marketing site'})
Write-Host 'MERIT OC Tutorial - hosted walkthrough' -ForegroundColor Cyan
Write-Host 'Each step opens the published URL from the OC receipt. No publish is performed.' -ForegroundColor Yellow
foreach($i in $items){if([string]::IsNullOrWhiteSpace([string]$i.Url)){Write-Host "[SKIP] $($i.Name): URL not recorded" -ForegroundColor Yellow;continue};Write-Host "[$($i.Name)] $($i.Expect)" -ForegroundColor Green;Write-Host "  $($i.Url)"; Start-Process ([string]$i.Url); Read-Host 'Press Enter for the next step' | Out-Null}
Write-Host 'OC tutorial complete. Review each browser tab and the OC receipt for evidence.' -ForegroundColor Green
