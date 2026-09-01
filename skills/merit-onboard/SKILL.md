---
name: merit-onboard
description: MERIT OSS quickstart and vault persona/repo onboard.
---

# merit-onboard

## Law

```powershell
.\merit.ps1 law --for-skill merit-onboard
.\merit.ps1 where
```

## OSS quickstart (no vault)

Merit-Hub cold start: menu **1** then **2**.

```powershell
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 init --path ..\merit-demo
.\merit.ps1 apply --path ..\merit-demo
.\merit.ps1 verify --path ..\merit-demo
```

Install IDE skills: Hub **I** or `.\install.ps1 -Target Cursor`.

## Closeout (OSS)

```powershell
.\merit.ps1 law closeout
.\merit.ps1 closeout --path .
.\merit.ps1 ship -Message "..."
```

## Operator (plane C only)

Resolve: `.\merit.ps1 where` → `operatorMeritCli`.

```powershell
& '<vault>\scripts\merit.ps1' persona activate AgentDraven
& '<vault>\scripts\merit.ps1' repo onboard <path>
```
