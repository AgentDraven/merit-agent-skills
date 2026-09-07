# Shared public CLI primitives. Loaded by the root merit.ps1 dispatcher.

function Get-ArgValue {
    param([string[]]$ArgList, [string]$Name)
    for ($i = 0; $i -lt $ArgList.Count; $i++) {
        if ($ArgList[$i] -eq $Name -and ($i + 1) -lt $ArgList.Count) { return $ArgList[$i + 1] }
    }
    return $null
}

function Test-ArgFlag {
    param([string[]]$ArgList, [string]$Name)
    return $ArgList -contains $Name
}

function Read-JsonFile {
    param([string]$Path)
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Write-JsonFile {
    param([string]$Path, [object]$Object)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Object | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Resolve-TargetRoot {
    param([string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--path'
    if ($p) {
        if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
        return (Resolve-Path $p).Path
    }
    return (Get-Location).Path
}

function Add-GitIgnoreLine {
    param([string]$TargetRoot, [string]$Line)
    $path = Join-Path $TargetRoot '.gitignore'
    if (Test-Path $path) {
        $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if ($text -match "(?m)^$([regex]::Escape($Line))$") { return }
        $prefix = if ($text.EndsWith("`n")) { '' } else { "`n" }
        [System.IO.File]::AppendAllText($path, "$prefix$Line`n", [System.Text.UTF8Encoding]::new($false))
    } else {
        [System.IO.File]::WriteAllText($path, "$Line`n", [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-LaunchPath {
    param([string]$TargetRoot, [string[]]$ArgList)
    $p = Get-ArgValue -ArgList $ArgList -Name '--launch'
    if (-not $p) { $p = '.merit_launch.md' }
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return (Join-Path $TargetRoot $p)
}

function Get-LaunchSettings {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "Launch file not found: $Path. Run merit init --path <repo> first." }
    $settings = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trim = $line.Trim()
        if (-not $trim -or $trim.StartsWith('#') -or $trim.StartsWith('```') -or $trim.StartsWith('<!--')) { continue }
        $m = [regex]::Match($trim, '^([A-Za-z0-9_]+)\s*=\s*(.*)$')
        if ($m.Success) { $settings[$m.Groups[1].Value.ToLowerInvariant()] = $m.Groups[2].Value.Trim() }
    }
    return $settings
}

function Get-Setting {
    param([System.Collections.IDictionary]$Settings, [string]$Name, [string]$Default = '')
    $key = $Name.ToLowerInvariant()
    if ($Settings.Contains($key) -and $Settings[$key]) { return $Settings[$key] }
    return $Default
}

function Require-Setting {
    param([System.Collections.IDictionary]$Settings, [string]$Name)
    $value = Get-Setting -Settings $Settings -Name $Name
    if (-not $value) { throw ".merit_launch.md missing mandatory value: $Name" }
    return $value
}

function Set-LaunchIniValue {
    param([string]$Path, [string]$Name, [string]$Value)
    if (-not (Test-Path $Path)) { throw "Launch file not found: $Path" }
    $key = $Name.Trim()
    $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8)
    $found = $false
    $out = foreach ($line in $lines) {
        if ($line -match("^\s*$([regex]::Escape($key))\s*=")) { $found = $true; "$key = $Value" } else { $line }
    }
    if (-not $found) { $out += "$key = $Value" }
    Set-Content -LiteralPath $Path -Value $out -Encoding UTF8
}
