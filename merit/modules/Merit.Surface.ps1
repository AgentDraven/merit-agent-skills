# Shared surface resolver implementation.
param([string]$MeritRoot = $PSScriptRoot)
$impl = Join-Path $MeritRoot 'Merit.SurfaceImpl.ps1'
if (-not (Test-Path -LiteralPath $impl)) { throw "Surface implementation not found: $impl" }
. $impl
