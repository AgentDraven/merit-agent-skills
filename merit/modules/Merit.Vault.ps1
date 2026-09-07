param([string]$MeritRoot = '')

function Resolve-MeritVaultRoot {
    param([string]$FromRoot = '')
    $candidates = @()
    if ($env:MERIT_VAULT_ROOT) { $candidates += $env:MERIT_VAULT_ROOT }
    if ($FromRoot) { $candidates += (Join-Path (Split-Path -Parent $FromRoot) 'merit-private-vault') }
    if ($env:MYMERITAPP) { $candidates += (Join-Path $env:MYMERITAPP 'merit-private-vault') }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'scripts\merit.ps1')) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
    return $null
}

function Invoke-MeritVaultCommand {
    param([string[]]$ArgList = @(), [string]$FromRoot = '')
    $vault = Resolve-MeritVaultRoot -FromRoot $FromRoot
    if (-not $vault) { throw 'Vault command unavailable: set MERIT_VAULT_ROOT or place merit-private-vault beside merit-agent-skills.' }
    $vaultCli = Join-Path $vault 'scripts\merit.ps1'
    $verb = if ($ArgList.Count) { [string]$ArgList[0] } else { 'help' }
    if ($verb -notin @('mXin','mXout','runtime','env','cert','git')) { throw "Vault command '$verb' is not allow-listed." }
    Write-Host "Delegating to vault CLI: $vaultCli ($verb)"
    & pwsh -NoProfile -File $vaultCli @ArgList
    if ($LASTEXITCODE -ne 0) { throw "Vault command failed (exit $LASTEXITCODE)" }
}
