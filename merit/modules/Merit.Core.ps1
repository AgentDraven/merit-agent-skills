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

function ConvertTo-ConsumerSlug {
    param([string]$Name)
    $s = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-' -replace '^-+|-+$', ''
    if (-not $s) { $s = 'my-app' }
    return $s
}

function Get-UsagePassphraseEnvName {
    param([string]$ConsumerId)
    $slug = ($ConsumerId.ToUpperInvariant() -replace '[^A-Z0-9]+', '_')
    return "MERIT_${slug}_PASSPHRASE"
}

function Get-Sha256Hex {
    param([string]$Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
    } finally { $sha.Dispose() }
}

function Set-EnvLocalValue {
    param([string]$Path, [string]$Name, [string]$Value)
    $lines = @()
    if (Test-Path $Path) { $lines = @(Get-Content -LiteralPath $Path -Encoding UTF8) }
    $found = $false
    $out = foreach ($line in $lines) {
        if ($line -match "^$([regex]::Escape($Name))=") { $found = $true; "$Name=$Value" } else { $line }
    }
    if (-not $found) { $out += "$Name=$Value" }
    Set-Content -LiteralPath $Path -Value $out -Encoding UTF8
}

function Write-EnvLocal {
    param([string]$TargetRoot, [System.Collections.IDictionary]$Settings, [string]$ConsumerId)
    $baseUrl = Get-Setting -Settings $Settings -Name 'meritsubs_public_base_url' -Default 'https://merit-prod.vercel.app/api/meritsubs'
    $lines = @('# Generated by merit apply from .merit_launch.md. Do not commit.', "SUPABASE_URL=$(Require-Setting -Settings $Settings -Name 'supabase_url')", "SUPABASE_ANON_KEY=$(Require-Setting -Settings $Settings -Name 'supabase_anon_key')", "SUPABASE_SERVICE_ROLE_KEY=$(Require-Setting -Settings $Settings -Name 'supabase_service_role_key')", '', "MERIT_CONSUMER_ID=$ConsumerId", '', "MERIT_METERED_API_BASE_URL=$(Get-Setting -Settings $Settings -Name 'merit_metered_api_base_url' -Default 'https://merit-prod.vercel.app')", "MERITSUBS_PUBLIC_BASE_URL=$baseUrl", "MERITSTORE_BASE_URL=$(Get-Setting -Settings $Settings -Name 'meritstore_base_url' -Default 'https://merit-prod.vercel.app/store')", "MERIT_DEFAULT_PROMOCODE=$(Get-Setting -Settings $Settings -Name 'default_promocode' -Default 'MERITAGENT')", "MERIT_INTRO_CREDIT_USD=$(Get-Setting -Settings $Settings -Name 'intro_credit_usd' -Default '25')", 'MERIT_VERCEL_LINKED=0', 'MERIT_VERCEL_DEPLOYED=0')
    $gate = Get-Setting -Settings $Settings -Name 'operator_gate_hash_slot_1'
    if ($gate) { $lines += @('', "OPERATOR_GATE_HASH_SLOT_1=$gate") }
    $here = Get-Setting -Settings $Settings -Name 'herenow_api_key'
    if ($here) { $lines += @('', "HERENOW_API_KEY=$here") }
    [System.IO.File]::WriteAllText((Join-Path $TargetRoot '.env.local'), ($lines -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
}

function Update-Branding {
    param([string]$TargetRoot, [System.Collections.IDictionary]$Settings)
    $path = Join-Path $TargetRoot 'cfg/branding.json'
    if (-not (Test-Path $path)) { return }
    $branding = Read-JsonFile $path
    $product = Get-Setting -Settings $Settings -Name 'product_name'
    $email = Get-Setting -Settings $Settings -Name 'operator_email'
    if ($product -and ($branding.PSObject.Properties.Name -contains 'product_name')) { $branding.product_name = $product }
    if ($email -and ($branding.PSObject.Properties.Name -contains 'operator_email')) { $branding.operator_email = $email }
    Write-JsonFile -Path $path -Object $branding
}
