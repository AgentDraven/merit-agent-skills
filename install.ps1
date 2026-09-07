# Compatibility wrapper. Canonical installation is: .\merit.ps1 skills install --target <Host>
[CmdletBinding()]
param([string]$Target, [string]$Path = '', [switch]$Help)
$ErrorActionPreference = 'Stop'
$argsList = @('skills','install')
if ($Target) { $argsList += @('--target', $Target) }
if ($Path) { $argsList += @('--path', $Path) }
if ($Help) { $argsList += '--help' }
& (Join-Path $PSScriptRoot 'merit.ps1') @argsList
exit $LASTEXITCODE
