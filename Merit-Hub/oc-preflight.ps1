param([Parameter(Mandatory)][string]$DemoRoot,[string]$Gateway='')
$ErrorActionPreference='Stop'; $fail=0
function Check($name,$ok,$detail){ if($ok){Write-Host "  [PASS] $name - $detail" -ForegroundColor Green}else{$script:fail++;Write-Host "  [FAIL] $name - $detail" -ForegroundColor Red} }
Write-Host 'OC preflight (no publish performed)' -ForegroundColor Cyan
if(-not $Gateway){$Gateway='https://merit-prod.vercel.app'}
Write-Host "Provider gateway: $Gateway" -ForegroundColor DarkCyan
Check 'demo Git checkout' (Test-Path (Join-Path $DemoRoot '.git')) $DemoRoot
Check 'play route' (Test-Path (Join-Path $DemoRoot 'play\index.html')) 'play/index.html present'
Check 'portal source' (Test-Path (Join-Path $DemoRoot 'portal\index.html')) 'portal/index.html present'
$pinsPath=Join-Path $DemoRoot 'cfg\par_pins.json'; $pins=$null
try{$pins=Get-Content $pinsPath -Raw|ConvertFrom-Json}catch{}
Check 'CompatSet pins' ($null -ne $pins) 'cfg/par_pins.json parses'
if($pins){$wb=$pins.packages.merit_workbench; $js=$wb.artifacts.js; Check 'workbench pin' ($wb.version -and $js.url -and $js.sri) ("$($wb.version) + URL + SRI")
  try{$u=Invoke-WebRequest -Uri ([string]$js.url) -Method Head -TimeoutSec 15; Check 'workbench artifact' ($u.StatusCode -ge 200 -and $u.StatusCode -lt 400) ([string]$js.url)}catch{Check 'workbench artifact' $false $_.Exception.Message}}
foreach($u in @("$Gateway/api/health","$Gateway/api/meritsubs/api/v1/health")){try{$r=Invoke-WebRequest -Uri $u -Method Get -TimeoutSec 15;Check "endpoint $u" ($r.StatusCode -eq 200) "HTTP $($r.StatusCode)"}catch{Check "endpoint $u" $false $_.Exception.Message}}
$portalUrl=$env:MERIT_OC_HERENOW_URL
if($portalUrl){try{$r=Invoke-WebRequest -Uri $portalUrl -Method Head -TimeoutSec 15;Check 'here.now portal' ($r.StatusCode -ge 200 -and $r.StatusCode -lt 400) $portalUrl}catch{Check 'here.now portal' $false $_.Exception.Message}}else{Write-Host '  [INFO] here.now portal URL not configured; OC will publish portal/.' -ForegroundColor Yellow}
if($fail){Write-Host "OC preflight BLOCKED ($fail failure(s)); no publish performed." -ForegroundColor Red; exit 1}
Write-Host 'OC preflight PASS; publish may proceed.' -ForegroundColor Green; exit 0
