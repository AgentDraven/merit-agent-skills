# Unified IDE skill command adapter. The implementation lives beside this
# adapter; root installer scripts were removed. Use `merit.ps1 skills install`.
function Invoke-MeritSkillsCommand {
    param([string[]]$ArgList, [string]$RepoRoot)
    $sub = if ($ArgList.Count) { "$($ArgList[0])".ToLowerInvariant() } else { 'list' }
    $target = Get-ArgValue -ArgList $ArgList -Name '--target'
    $installer = Join-Path $RepoRoot 'merit\modules\Merit.SkillsInstall.ps1'
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
            $path = Get-ArgValue -ArgList $ArgList -Name '--path'
            if ($path) { & $installer -Target $target -Path $path }
            else { & $installer -Target $target }
            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "skills install failed (exit $LASTEXITCODE)" }
            return
        }
        'remove' {
            if (-not $target) { throw 'Usage: .\merit.ps1 skills remove --target <Host> [--yes]' }
            $homeRoot = if ($env:USERPROFILE) { $env:USERPROFILE } else { $env:HOME }
            if (-not $homeRoot) { throw 'USERPROFILE/HOME is not set' }
            $resolved = switch ($target) { 'Claude' {'ClaudeCode'} 'Agents' {'VSCode'} 'Grok' {'GrokBot'} default {$target} }
            $destRoot = switch ($resolved) {
                'Cursor' { Join-Path $homeRoot '.cursor\skills' }
                'ClaudeCode' { Join-Path $homeRoot '.claude\skills' }
                'Codex' { Join-Path (if ($env:CODEX_HOME) {$env:CODEX_HOME} else {Join-Path $homeRoot '.codex'}) 'skills' }
                'VSCode' { Join-Path $homeRoot '.agents\skills' }
                'Hermes' { Join-Path $homeRoot '.hermes\skills' }
                'OpenClaw' { Join-Path $homeRoot '.openclaw\skills' }
                'GrokBot' { Join-Path $homeRoot '.grok\skills' }
                'Devin' { Join-Path $homeRoot '.devin\skills' }
                'Project' { throw 'Project removal requires manual review of the project .cursor/skills tree.' }
                default { throw "Unknown skill target '$target'." }
            }
            if (-not (Test-ArgFlag -ArgList $ArgList -Name '--yes')) { throw "Refusing to remove skills without --yes: $destRoot" }
            if (-not (Test-Path -LiteralPath $destRoot)) { Write-Host "No installed skills found at $destRoot"; return }
            Get-ChildItem -LiteralPath $destRoot -Directory -Filter 'merit-*' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
            Write-Host "Removed MERIT skill folders from $destRoot"
            return
        }
        default { throw 'Usage: .\merit.ps1 skills list|status|install --target <Host>|remove --target <Host>' }
    }
}
