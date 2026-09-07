# Compatibility module during Bootstrap migration.
param([string]$MeritRoot = $PSScriptRoot)
$legacy = Join-Path (Split-Path -Parent (Split-Path -Parent $MeritRoot)) 'BootStrap\_resolve.ps1'
if (-not (Test-Path -LiteralPath $legacy)) { throw "Legacy surface helper not found: $legacy" }
. $legacy
