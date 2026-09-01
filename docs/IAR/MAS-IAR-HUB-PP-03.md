# MAS-IAR-HUB-PP-03 — Hub menu key rationalization (sprawl G)

**Document ID:** MAS-IAR-HUB-PP-03  
**Vault evidence:** `merit-private-vault/docs/IAR/VAULT_EVIDENCE.md` § merit-hub-menu-keys  
**Ships with:** skills-v0.5.54+

## Problem

Interactive menu key **V** was overloaded: vault clone (`4` alias) and sprawl scan both claimed **V**. Sprawl scan was unreachable from the menu (regex matched vault first).

## Fix

| Before | After |
|--------|-------|
| Sprawl menu **V** | **G** (sprawl) |
| Vault alias **V** | **4** only |
| CLI `-VestigialScan` | `-SprawlScan` (alias retained) |

## Operator

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File $env:MYMERITTOOLS\Merit-Hub.ps1
# G = preview sprawl   A = archive   P = pristine
```
