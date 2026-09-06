# MERIT root Hub launcher.
# Keep this file small and stable: the implementation lives under Merit-Hub/.
$ErrorActionPreference = 'Stop'
$implementation = Join-Path $PSScriptRoot 'Merit-Hub\Merit-Hub.ps1'
if (-not (Test-Path -LiteralPath $implementation -PathType Leaf)) {
    throw "MERIT Hub implementation not found: $implementation"
}

& $implementation @args
exit $LASTEXITCODE
