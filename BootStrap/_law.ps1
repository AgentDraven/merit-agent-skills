# Merit law pack — unpack merit.blob (OSS L1 excerpt). In-memory only.
#Requires -Version 5.1

$Script:MeritLawPackCache = $null

function Get-MeritLawBlobPath {
    param([string]$RepoRoot)
    if (-not $RepoRoot) {
        $RepoRoot = if ($Script:MeritResolveRepoRoot) { $Script:MeritResolveRepoRoot } else { $PSScriptRoot | Split-Path -Parent }
    }
    return Join-Path $RepoRoot 'merit.blob'
}

function Get-MeritLawManifestPath {
    param([string]$RepoRoot)
    if (-not $RepoRoot) {
        $RepoRoot = if ($Script:MeritResolveRepoRoot) { $Script:MeritResolveRepoRoot } else { $PSScriptRoot | Split-Path -Parent }
    }
    return Join-Path $RepoRoot 'cfg\merit_law.json'
}

function Get-MeritLawXorKey {
  param([string]$Seed = 'merit-law-pack-v1')
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Seed))
    }
    finally { $sha.Dispose() }
}

function Protect-MeritLawBytes {
    param([byte[]]$Data, [byte[]]$Key, [switch]$Unprotect)
    $out = New-Object byte[] $Data.Length
    for ($i = 0; $i -lt $Data.Length; $i++) {
        $out[$i] = $Data[$i] -bxor $Key[$i % $Key.Length]
    }
    return $out
}

function Expand-MeritLawBytes {
    param([byte[]]$Compressed)
    $ms = New-Object System.IO.MemoryStream(,$Compressed)
    $gzip = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
    $out = New-Object System.IO.MemoryStream
    $gzip.CopyTo($out)
    $gzip.Dispose()
    $ms.Dispose()
    return $out.ToArray()
}

function Compress-MeritLawBytes {
    param([byte[]]$Plain)
    $ms = New-Object System.IO.MemoryStream
    $gzip = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Compress)
    $gzip.Write($Plain, 0, $Plain.Length)
    $gzip.Dispose()
    return $ms.ToArray()
}

function Read-MeritLawPack {
    param([string]$RepoRoot)
    if ($Script:MeritLawPackCache) { return $Script:MeritLawPackCache }
    $blobPath = Get-MeritLawBlobPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $blobPath)) {
        throw "merit law: missing merit.blob at $blobPath"
    }
    $raw = [IO.File]::ReadAllBytes($blobPath)
    if ($raw.Length -lt 12) { throw 'merit law: blob too small' }
    $magic = [System.Text.Encoding]::ASCII.GetString($raw, 0, 8)
    if ($magic -ne 'MERITLAW') { throw "merit law: bad magic ($magic)" }
    $ver = [BitConverter]::ToUInt32($raw, 8)
    if ($ver -ne 1) { throw "merit law: unsupported blob version $ver" }
    $payload = Protect-MeritLawBytes -Data $raw[12..($raw.Length - 1)] -Key (Get-MeritLawXorKey)
    $plain = Expand-MeritLawBytes -Compressed $payload
    $json = [System.Text.Encoding]::UTF8.GetString($plain)
    $Script:MeritLawPackCache = $json | ConvertFrom-Json
    return $Script:MeritLawPackCache
}

function Get-MeritLawManifest {
    param([string]$RepoRoot)
    $path = Get-MeritLawManifestPath -RepoRoot $RepoRoot
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-MeritLawSection {
    param(
        [string]$SectionId,
        [string]$RepoRoot = ''
    )
    $pack = Read-MeritLawPack -RepoRoot $RepoRoot
    $id = $SectionId.Trim()
    foreach ($s in @($pack.sections)) {
        if ([string]$s.id -eq $id) { return $s }
    }
    return $null
}

function Get-MeritLawForSkill {
    param(
        [string]$SkillName,
        [string]$RepoRoot = ''
    )
    $manifest = Get-MeritLawManifest -RepoRoot $RepoRoot
    $pack = Read-MeritLawPack -RepoRoot $RepoRoot
    $skill = $SkillName.Trim().TrimStart('/')
    if ($manifest -and $manifest.skillMap.PSObject.Properties[$skill]) {
        $ids = @($manifest.skillMap.$skill)
    }
    else {
        $ids = @('II', 'CLI')
    }
    $out = [System.Collections.Generic.List[object]]::new()
    foreach ($sid in $ids) {
        $sec = Get-MeritLawSection -SectionId $sid -RepoRoot $RepoRoot
        if ($sec) { [void]$out.Add($sec) }
    }
    return @($out)
}

function Write-MeritLawSectionText {
    param($Section)
    Write-Host ''
    Write-Host ("## {0} — {1}" -f $Section.id, $Section.title) -ForegroundColor Cyan
    Write-Host $Section.body
}

function Invoke-MeritLawEdition {
    param([string]$RepoRoot = '')
    $tier = 'oss'
    $closeout = '.\merit.ps1 closeout --path .`n.\merit.ps1 ship -Message "..."'
    if (Get-Command Get-MeritSurface -ErrorAction SilentlyContinue) {
        $surf = Get-MeritSurface -NoWrite
        Write-Host ("edition: {0}" -f $surf.edition)
        if ($surf.operatorMeritCli) {
            Write-Host ("operator CLI: {0}" -f $surf.operatorMeritCli)
            if ($surf.edition -match 'vault') {
                $tier = 'operator'
                $closeout = "& '$($surf.operatorMeritCli)' mXin -Message `"...`"`n& '$($surf.operatorMeritCli)' git verify"
            }
        }
    }
    Write-Host ''
    Write-Host 'Closeout tier for this machine:' -ForegroundColor Yellow
    if ($tier -eq 'operator') {
        Write-Host '  Operator (plane C): vault mXin + git verify (preferred when vault on disk)'
        Write-Host "  OSS override: MERIT_SHIP_OSS=1 then .\merit.ps1 ship"
    }
    else {
        Write-Host '  OSS: .\merit.ps1 closeout --path . then .\merit.ps1 ship -Message "..."'
    }
    Write-Host ''
    $sec = Get-MeritLawSection -SectionId 'VIII.F' -RepoRoot $RepoRoot
    if ($sec) { Write-MeritLawSectionText -Section $sec }
}

function Invoke-MeritLaw {
    param(
        [string[]]$ArgList,
        [string]$RepoRoot = ''
    )
    if (-not $RepoRoot) {
        $RepoRoot = if ($Script:MeritResolveRepoRoot) { $Script:MeritResolveRepoRoot } else { Split-Path -Parent $PSScriptRoot }
    }
    $sub = if ($ArgList.Count -gt 0) { "$($ArgList[0])".ToLowerInvariant() } else { 'list' }
    $rest = if ($ArgList.Count -gt 1) { @($ArgList[1..($ArgList.Count - 1)]) } else { @() }

    if ($sub -eq 'list') {
        $pack = Read-MeritLawPack -RepoRoot $RepoRoot
        Write-Host "merit law pack v$($pack.blobVersion) (skills $($pack.skillsVersion))"
        foreach ($s in @($pack.sections)) {
            Write-Host ("  {0,-10} {1}" -f $s.id, $s.title)
        }
        return
    }

    if ($sub -eq 'closeout') {
        $secs = @('VIII.F', 'H', 'CLI')
        $pack = Read-MeritLawPack -RepoRoot $RepoRoot
        Write-Host 'MERIT closeout law (from merit.blob — validate + ship/mXin + 3-3)' -ForegroundColor Cyan
        foreach ($sid in $secs) {
            foreach ($s in @($pack.sections)) {
                if ([string]$s.id -eq $sid) { Write-MeritLawSectionText -Section $s }
            }
        }
        Invoke-MeritLawEdition -RepoRoot $RepoRoot
        return
    }

    if ($sub -eq 'edition') {
        Invoke-MeritLawEdition -RepoRoot $RepoRoot
        return
    }

    $sectionArg = $null
    $skillArg = $null
    for ($i = 0; $i -lt $rest.Count; $i++) {
        if ($rest[$i] -eq '--section' -and ($i + 1) -lt $rest.Count) { $sectionArg = $rest[$i + 1]; $i++ }
        if ($rest[$i] -eq '--for-skill' -and ($i + 1) -lt $rest.Count) { $skillArg = $rest[$i + 1]; $i++ }
    }
    if (-not $sectionArg -and -not $skillArg) {
        $sectionArg = $sub
    }

    if ($skillArg) {
        $sections = Get-MeritLawForSkill -SkillName $skillArg -RepoRoot $RepoRoot
        Write-Host "Law for skill: $skillArg" -ForegroundColor Cyan
        foreach ($s in $sections) { Write-MeritLawSectionText -Section $s }
        return
    }

    if ($sectionArg) {
        $sec = Get-MeritLawSection -SectionId $sectionArg -RepoRoot $RepoRoot
        if (-not $sec) { throw "law: unknown section '$sectionArg' (try: merit.ps1 law list)" }
        Write-MeritLawSectionText -Section $sec
        return
    }

    throw 'law: use list | closeout | edition | <section-id> | --section <id> | --for-skill <name>'
}

function Write-MeritLawBlob {
    param(
        [Parameter(Mandatory = $true)]
        $PackObject,
        [Parameter(Mandatory = $true)]
        [string]$OutPath,
        [string]$XorSeed = 'merit-law-pack-v1'
    )
    $json = $PackObject | ConvertTo-Json -Depth 8 -Compress
    $plain = [System.Text.Encoding]::UTF8.GetBytes($json)
    $compressed = Compress-MeritLawBytes -Plain $plain
    $xored = Protect-MeritLawBytes -Data $compressed -Key (Get-MeritLawXorKey -Seed $XorSeed)
    $header = [System.Text.Encoding]::ASCII.GetBytes('MERITLAW')
    $verBytes = [BitConverter]::GetBytes([uint32]1)
    $all = New-Object byte[] ($header.Length + $verBytes.Length + $xored.Length)
    [Array]::Copy($header, 0, $all, 0, 8)
    [Array]::Copy($verBytes, 0, $all, 8, 4)
    [Array]::Copy($xored, 0, $all, 12, $xored.Length)
    $dir = Split-Path -Parent $OutPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    [IO.File]::WriteAllBytes($OutPath, $all)
}
