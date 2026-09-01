# MAS-IAR-HUB-PP-02 — Merit-Hub vestigial sprawl scan

**Document ID:** MAS-IAR-HUB-PP-02  
**Vault evidence:** `merit-private-vault/docs/IAR/VAULT_EVIDENCE.md` § merit-hub-vestigial  
**Ships with:** skills-v0.5.53+

## Requirement

Pre-Pristine and Pristine must not leave unknown MERIT folder sprawl on the laptop. Operator may decline individual paths, but Hub must **surface** vestigial candidates and offer archive-to-backup before wipe.

## Detection (`Get-HubVestigialCandidates`)

| Kind | Example |
|------|---------|
| `extra-app-bench` | `C:\DevApps` when `MYMERITAPP=C:\DApps` |
| `extra-tools-root` | `C:\Tools` when `MYMERITTOOLS=C:\DevTools` |
| `stub-skills-clone` | `merit-agent-skills` folder without `merit.ps1` |
| `duplicate-skills-clone` | second full skills git tree |
| `drive-merit-root` | `C:\DApps`, `C:\DTools`, … from `rogueDriveRootNames` + known names |
| `stale-hub-script` | `Merit-Hub.ps1` outside canonical tools Hub |
| `env-mismatch` | User vs Process `MYMERIT*` (report only) |

## Protected (never auto-archived)

- Canonical `MYMERITAPP` / `MYMERITTOOLS` trees and their `backups\`
- `Setup_LocalModels*` and `Wiring OpenModel*` (operator local-model work)
- Current tools `Merit-Hub.ps1` copy

## Operator runbook

```powershell
# Preview only
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1 -VestigialScan

# Pre-Pristine (prompts y/N/review; archives into backups\<stamp>\vestigial-archived\)
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1 -PrePristine

# Pristine (-Force archives all vestigial without per-item prompts)
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1 -Pristine
```

Artifacts: `vestigial-scan.json`, `vestigial-archived\MANIFEST.txt` under each pre-pristine stamp.
