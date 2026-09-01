---
name: merit-surface
description: Merit Surface map — discover OSS bench (B), IDE skills (A), vault (C), Hub (H), merit-demo (D). Use when paths are unclear or after Pristine.
---

# merit-surface

## Law

```powershell
.\merit.ps1 law --for-skill merit-surface
.\merit.ps1 law edition
```

## Diagnostic

```powershell
# B present:
.\merit.ps1 where

# B missing:
pwsh -NoProfile -ExecutionPolicy Bypass -File %MYMERITTOOLS%\Merit-Hub.ps1 -Surface
```

## Planes

**A** IDE skills · **B** OSS bench · **C** vault · **H** Hub · **D** merit-demo

## Closeout tiers

1. `.\merit.ps1 law closeout`
2. Validate: `.\merit.ps1 closeout --path .`
3. OSS: `.\merit.ps1 ship` · Operator (C): `& <operatorMeritCli> mXin`

Never assume `~/dev`. Resolve paths via `where` first.
