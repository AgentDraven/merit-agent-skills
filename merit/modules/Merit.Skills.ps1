# Unified IDE skill command adapter. The installer implementation remains
# compatibility-owned by install.ps1 until the migration phase removes it.
function Invoke-MeritSkillsCommand {
    param([string[]]$ArgList, [string]$RepoRoot)
    $sub = if ($ArgList.Count) { "$($ArgList[0])".ToLowerInvariant() } else { 'list' }
    $target = Get-ArgValue -ArgList $ArgList -Name '--target'
    $installer = Join-Path $RepoRoot 'install.ps1'
    if (-not (Test-Path -LiteralPath $installer)) { throw "Skill installer not found: $installer" }
    switch ($sub) {
        'list' { & $installer -Help; return }
        'status' {
            Write-Host "MERIT skills root: $RepoRoot"
            Write-Host "Installed surface markers:" 
            Get-ChildItem -Path (Get-Location).Path -Filter '.merit-surface.json' -Recurse -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.FullName)" }
            return
        }
        'install' {
            if (-not $target) { throw 'Usage: .\merit.ps1 skills install --target <Host>' }
            & $installer -Target $target
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "skills install failed (exit $LASTEXITCODE)" }
            return
        }
        'remove' { throw 'skills remove is not implemented until the installer module migration phase.' }
        default { throw 'Usage: .\merit.ps1 skills list|status|install --target <Host>|remove --target <Host>' }
    }
}
