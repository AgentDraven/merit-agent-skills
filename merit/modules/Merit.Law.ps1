# Shared law resolver implementation.
param([string]$MeritRoot = $PSScriptRoot)
$impl = Join-Path $MeritRoot 'Merit.LawImpl.ps1'
if (-not (Test-Path -LiteralPath $impl)) { throw "Law implementation not found: $impl" }
. $impl
