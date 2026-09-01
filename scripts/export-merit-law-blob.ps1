# Export merit.blob + cfg/merit_law.json from OSS law pack source.
# Operator: vault scripts/merit.ps1 law export-blob -Source instructions/MERIT.instructions
# OSS maintainers: pwsh -File scripts/export-merit-law-blob.ps1 [-SkillsVersion 0.5.45]
#Requires -Version 5.1
param(
    [string]$SourcePath = '',
    [string]$RepoRoot = '',
    [string]$SkillsVersion = '',
    [switch]$Bootstrap
)

$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) { $RepoRoot = Split-Path -Parent $PSScriptRoot }
. (Join-Path $RepoRoot 'BootStrap\_law.ps1')

function Get-DefaultOssLawSections {
    return @(
        @{
            id    = 'II'
            title = 'Agent execution norms'
            body  = @'
Agents on merit-agent-skills follow public OSS law via merit.ps1 law (merit.blob unpack).
- Resolve paths: MYMERITAPP, merit.ps1 where, Merit-Hub -Surface — never assume ~/dev.
- Skills are index cards; binding law prints from merit.ps1 law closeout.
- Consumer work: public merit.ps1 on plane B. Operator work: vault scripts\merit.ps1 when plane C exists.
- Do not fork L1 into consumer repos. Do not raw git commit/tag/push as MERIT closeout.
'@
        }
        @{
            id    = 'CLI'
            title = 'CLI law table'
            body  = @'
| CLI | Path | Use |
|-----|------|-----|
| Public OSS | B\merit.ps1 | init, apply, verify, closeout, ship, law, where, create, oc |
| Operator | C\scripts\merit.ps1 | mXin, mXout, git verify, runtime, cert, deploy vercel |
| Hub | H\Merit-Hub.ps1 | cold start 1→2, menu W surface, I install skills |

merit.ps1 closeout --path = VALIDATE ONLY (verify + git diff --check).
Full MERIT closeout = merit.ps1 law closeout then ship (OSS) or vault mXin (operator).
'@
        }
        @{
            id    = 'SURFACE'
            title = 'Merit Surface editions'
            body  = @'
Planes: A=IDE skills, B=OSS bench, C=vault, H=Hub, D=merit-demo.
Editions: none, ide-only, oss, oss+ide, vault-only, vault+ide, oss+vault, full.
Diagnostic: merit.ps1 where (B present) or Merit-Hub.ps1 -Surface (B missing).
Hub 3/OC require B+D. Closeout tier follows edition — run merit.ps1 law edition.
'@
        }
        @{
            id    = 'VIII.F'
            title = 'Closeout (validate + git release)'
            body  = @'
MERIT closeout sequence (binding):
1. Hygiene — stage intended files only; no secrets.
2. Validate — merit.ps1 closeout --path <repo> (or consumer verify).
3. VERSION + CHANGELOG — PATCH bump for skills release.
4. Git release:
   OSS (no vault / MERIT_SHIP_OSS): merit.ps1 ship -Message "..." from skills repo root.
   Operator (plane C): & <vault>\scripts\merit.ps1 mXin -Message "..." then git verify.
5. Chat 3-3: Done · State (VERSION/tag) · Next (≤3 bullets).

ship requires branch (not detached HEAD unless -AllowDetached). Reads VERSION + TAG_PREFIX → skills-v*.
'@
        }
        @{
            id    = 'H'
            title = '3-3 report'
            body  = @'
End every completed scope with chat 3-3:
**Done** — what shipped this cycle.
**State** — VERSION, tag, branch, edition from merit.ps1 where if relevant.
**Next** — ≤3 bullets.

Exception: user said WIP / no commit / local-only.
'@
        }
        @{
            id    = 'VIII.G'
            title = 'Maturity basics'
            body  = @'
OSS builders target consumer verify + portal promise. Operators add hygiene, remote closeout, cert registry.
Use merit-mm-upgrade for gap analysis without vault. Use merit-upgrade (vault) for full L1 lifecycle.
'@
        }
        @{
            id    = 'PORTAL'
            title = 'Portal / here.now'
            body  = @'
OSS: merit.ps1 portal --path <consumer> (BYOK HERENOW_API_KEY).
Operator (plane C): use operatorMeritCli from merit.ps1 where for vault portal publish.
Footer: MERIT Powered. Include portal/legal.html and portal/terms.html.
'@
        }
        @{
            id    = 'DEPLOY'
            title = 'Deploy'
            body  = @'
OSS consumer: merit.ps1 deploy --path <repo> with cfg/flask_deploy.json vercel_scope.
Operator catalog: operatorMeritCli deploy vercel -Project <id> [--sync-env].
Cloud First: create lands on merit-prod /apps by default.
'@
        }
        @{
            id    = 'CERT'
            title = 'Certification vocabulary'
            body  = @'
OSS: merit.ps1 verify --path <consumer> documents readiness.
Operator writes: cert foundation, cert integration, cert status via vault scripts\merit.ps1.
Acceptance IDs: {ACRONYM}-{PROVIDER}-{NN}. Requester-IAR ACCEPT required for operational readiness.
'@
        }
        @{
            id    = 'GATE'
            title = 'Admin gate'
            body  = @'
OSS demo: merit.ps1 admin gate demo-init --path <consumer> (local placeholders).
Operator production: admin operator-gate hash via vault CLI; phrase never in git/chat.
'@
        }
        @{
            id    = 'SUBS'
            title = 'MeritSubs / freemium'
            body  = @'
OSS: merit.ps1 subs scaffold; hosted merit-prod endpoints for metered rails.
Legal pages in portal/. Vault templates for operator legal HTML when plane C present.
No local /api/meritsubs stubs in production consumer builds.
'@
        }
        @{
            id    = 'LIVEALPHA'
            title = 'Live alpha / research floors'
            body  = @'
OSS: merit.ps1 livealpha --path <consumer> scaffolds research + baseline cfg.
Research floors: ≥10 categories, ≥10 APA refs each, ≥50 cross-ref edges.
Honesty bounds: no demoware claims for multi-user sync, email, or managed video without providers.
'@
        }
    )
}

function Import-LawSectionsFromInstructions {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Source not found: $Path" }
    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $sections = Get-DefaultOssLawSections
    if ($text -match '(?ms)§VIII\.F.*?(?=§[A-Z]|\z)') {
        $body = $Matches[0].Trim()
        if ($body.Length -gt 200) {
            $sections = @($sections | Where-Object { $_.id -ne 'VIII.F' })
            $sections += @{ id = 'VIII.F'; title = 'Closeout (from vault L1)'; body = $body.Substring(0, [Math]::Min(8000, $body.Length)) }
        }
    }
    return $sections
}

$ver = $SkillsVersion
if (-not $ver) {
    $vf = Join-Path $RepoRoot 'VERSION'
    if (Test-Path $vf) { $ver = ((Get-Content $vf -Raw) -split '\r?\n')[0].Trim() }
    else { $ver = '0.0.0' }
}

$sections = if ($SourcePath) { Import-LawSectionsFromInstructions -Path $SourcePath } else { Get-DefaultOssLawSections }

$pack = [ordered]@{
    schemaVersion  = 1
    blobVersion    = '1.0.0'
    skillsVersion  = $ver
    exportedAt     = (Get-Date).ToString('o')
    source         = if ($SourcePath) { $SourcePath } else { 'bootstrap:export-merit-law-blob.ps1' }
    sections       = $sections
}

$manifest = [ordered]@{
    schemaVersion = 1
    blobVersion   = '1.0.0'
    blobFile      = 'merit.blob'
    skillsVersion = $ver
    skillMap      = [ordered]@{
        'merit-closeout'     = @('VIII.F', 'H', 'CLI')
        'merit-surface'      = @('SURFACE', 'CLI', 'VIII.F')
        'merit-onboard'      = @('SURFACE', 'CLI', 'VIII.F')
        'merit-portal'       = @('PORTAL', 'CLI')
        'merit-deploy-vercel'= @('DEPLOY', 'CLI')
        'merit-admin-gate'   = @('GATE', 'CLI')
        'meritcert'          = @('CERT', 'CLI')
        'merit-iar'          = @('CERT', 'CLI')
        'merit-subs'         = @('SUBS', 'CLI')
        'merit-livealpha'    = @('LIVEALPHA', 'CLI')
        'merit-prd'          = @('II', 'CLI')
        'merit-applogic'     = @('II', 'CLI')
        'merit-mm-upgrade'   = @('VIII.G', 'II')
        'merit-par-workbench'= @('II', 'CLI')
        'merit-ama'          = @('II', 'CLI')
        'merit-referral'     = @('II', 'CLI')
        'merit-law'          = @('II', 'CLI', 'VIII.F', 'H', 'SURFACE')
    }
    sectionIndex  = @($sections | ForEach-Object { $_.id })
}

$blobPath = Join-Path $RepoRoot 'merit.blob'
$manifestPath = Join-Path $RepoRoot 'cfg\merit_law.json'

Write-MeritLawBlob -PackObject $pack -OutPath $blobPath
($manifest | ConvertTo-Json -Depth 6) | Set-Content -LiteralPath $manifestPath -Encoding UTF8

Write-Host "Wrote $blobPath ($((Get-Item $blobPath).Length) bytes)"
Write-Host "Wrote $manifestPath"
Write-Host "Sections: $($sections.Count)"
