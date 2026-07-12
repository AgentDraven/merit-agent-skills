# MERIT public CLI — one entrypoint for free users.

param()

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Deploy = Join-Path $Root 'merit-deploy.ps1'
$Live = Join-Path $Root 'merit-live.ps1'
$MERIT_VERSION = '0.3.11'

$Command = if ($args.Count -gt 0) { "$($args[0])".ToLowerInvariant() } else { 'help' }
$Rest = if ($args.Count -gt 1) { @($args[1..($args.Count - 1)]) } else { @() }

function Write-MeritHelp {
    Write-Host @"
merit.ps1 — public MERIT CLI

Use this one script for the free-user path.

Commands:
  init --path <repo>       Create .merit_launch.md and gitignore it
  apply --path <repo>      Read .merit_launch.md and generate config + .env.local
  verify --path <repo>     Verify local MERIT scaffold
  deploy --path <repo>     Apply launch file, then deploy Vercel
  portal --path <repo>     Apply launch file, then publish here.now portals
  all --path <repo>        Apply launch file, deploy Vercel, then publish portals
  par|branding|subs|admin  Advanced scaffold helpers routed through compatibility plumbing
  version                  Print version
  help                     Print help

Typical flow:
  .\merit.ps1 init --path ..\merit-demo
  # edit ..\merit-demo\.merit_launch.md
  .\merit.ps1 apply --path ..\merit-demo
  npx vercel link --scope <your-vercel-scope>
  .\merit.ps1 deploy --path ..\merit-demo
"@
}

function Invoke-Script {
    param([string]$Script, [string[]]$ScriptArgs)
    & $Script @ScriptArgs
}

switch -Regex ($Command) {
    '^(help|\?)$' { Write-MeritHelp; exit 0 }
    '^version$' { Write-Host "merit $MERIT_VERSION"; exit 0 }
    '^init$' { Invoke-Script -Script $Deploy -ScriptArgs (@('init') + $Rest); exit $LASTEXITCODE }
    '^apply$' { Invoke-Script -Script $Deploy -ScriptArgs (@('apply') + $Rest); exit $LASTEXITCODE }
    '^sync$' { Invoke-Script -Script $Deploy -ScriptArgs (@('apply') + $Rest); exit $LASTEXITCODE }
    '^verify$' { Invoke-Script -Script $Live -ScriptArgs (@('verify') + $Rest); exit $LASTEXITCODE }
    '^deploy$' { Invoke-Script -Script $Deploy -ScriptArgs (@('vercel') + $Rest); exit $LASTEXITCODE }
    '^vercel$' { Invoke-Script -Script $Deploy -ScriptArgs (@('vercel') + $Rest); exit $LASTEXITCODE }
    '^portal$' { Invoke-Script -Script $Deploy -ScriptArgs (@('portal') + $Rest + @('--all')); exit $LASTEXITCODE }
    '^all$' { Invoke-Script -Script $Deploy -ScriptArgs (@('all') + $Rest + @('--all')); exit $LASTEXITCODE }
    '^par$' { Invoke-Script -Script $Live -ScriptArgs (@('par') + $Rest); exit $LASTEXITCODE }
    '^branding$' { Invoke-Script -Script $Live -ScriptArgs (@('branding') + $Rest); exit $LASTEXITCODE }
    '^subs$' { Invoke-Script -Script $Live -ScriptArgs (@('subs') + $Rest); exit $LASTEXITCODE }
    '^admin$' { Invoke-Script -Script $Live -ScriptArgs (@('admin') + $Rest); exit $LASTEXITCODE }
    '^app$' { Invoke-Script -Script $Live -ScriptArgs (@('app') + $Rest); exit $LASTEXITCODE }
    default { Write-MeritHelp; exit 1 }
}
