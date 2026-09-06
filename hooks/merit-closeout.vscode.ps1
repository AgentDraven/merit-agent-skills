param()
$payload = [Console]::In.ReadToEnd()
if ($payload -match 'stop_hook_active\s*["'':=]+\s*(true|1)') { '{"continue":true,"systemMessage":"MERIT recursion guard active."}'; exit 0 }
$repo = if ($env:MERIT_REPO_PATH) { $env:MERIT_REPO_PATH } else { (Get-Location).Path }
$cli = if ($env:MERIT_CLI_PATH) { $env:MERIT_CLI_PATH } else { Join-Path $repo 'merit-agent-skills\merit.ps1' }
if (-not (Test-Path -LiteralPath $cli)) { '{"continue":true,"systemMessage":"MERIT CLI not found; guidance-only warning."}'; exit 0 }
& powershell -NoProfile -ExecutionPolicy Bypass -File $cli law closeout *> $null
& powershell -NoProfile -ExecutionPolicy Bypass -File $cli closeout --path $repo *> $null
if ($LASTEXITCODE -eq 0) { '{"continue":true,"systemMessage":"MERIT closeout passed. End with 3-3: Done, State, Next."}'; exit 0 }
'{"continue":false,"stopReason":"MERIT closeout validation failed; remediate before ending."}'
exit 2
