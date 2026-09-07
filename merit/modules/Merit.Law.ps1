# Compatibility module during Bootstrap migration.
# The public CLI loads law through merit/modules; the legacy helper remains
# available to Hub callers until the Bootstrap phase is fully retired.
param([string]$MeritRoot = $PSScriptRoot)
$legacy = Join-Path (Split-Path -Parent (Split-Path -Parent $MeritRoot)) 'BootStrap\_law.ps1'
if (-not (Test-Path -LiteralPath $legacy)) { throw "Legacy law helper not found: $legacy" }
. $legacy
