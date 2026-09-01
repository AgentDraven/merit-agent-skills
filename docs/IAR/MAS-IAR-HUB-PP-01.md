# MAS-IAR-HUB-PP-01 — Merit-Hub Pre-Pristine / Pristine foolproof

**Document ID:** MAS-IAR-HUB-PP-01  
**Vault evidence:** `merit-private-vault/docs/IAR/VAULT_EVIDENCE.md` § merit-hub-pre-pristine  
**Ships with:** skills-v0.5.52+

## Requirement

Hub must be safe for a non-expert operator to archive, wipe, and cold-start without losing the Hub binary, the archive, or cloning a stale pin.

## Controls (Hub)

| Function | Role |
|----------|------|
| `Initialize-HubBackupRoot` | Archives under `%MYMERITTOOLS%\backups` |
| `Install-HubToToolsRoot` | Refreshes `%MYMERITTOOLS%\Merit-Hub.ps1` |
| `Write-HubFoolproofGate` | Pins + wipe warnings |
| `-PrePristine` / menu **A** | Archive only |
| `-Pristine` / menu **P** | Archive then wipe |

## Operator runbook

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1 -PrePristine
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1 -Help
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1 -Pristine
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1
# 1 → 2 → 3
```
