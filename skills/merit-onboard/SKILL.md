---
name: merit-onboard
description: MERIT OSS quickstart and vault persona/repo onboard.
---

# merit-onboard

## Resolve paths first

Do not assume `~/dev` or a Cursor workspace path.

```powershell
# From OSS bench (B):
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 where

# When B missing:
pwsh -NoProfile -ExecutionPolicy Bypass -File %MYMERITTOOLS%\Merit-Hub.ps1 -Surface
```

See skill **merit-surface** for the A×B×C matrix.

## OSS quickstart (no vault)

**Recommended:** Merit-Hub cold start — menu **1** then **2** (clones pinned `skills-v*` + `merit-demo`).

Manual clone (only if not using Hub):

```powershell
git clone --branch skills-v0.5.44 https://github.com/AgentDraven/merit-agent-skills.git %MYMERITAPP%\merit-agent-skills
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 init --path ..\merit-demo
.\merit.ps1 apply --path ..\merit-demo
.\merit.ps1 verify --path ..\merit-demo
```

Reference consumer: **Mr-PI-Bala/merit-demo**.

Install IDE skills: `.\install.ps1 -Target Cursor` or Hub **I**.

## Closeout (OSS laptop)

```powershell
.\merit.ps1 closeout --path .
.\merit.ps1 ship -Message "fix: <summary>"
```

When vault is on disk, prefer vault `scripts\merit.ps1 mXin` (see **merit-closeout**).

## Vault operators

```powershell
& '<vault>\scripts\merit.ps1' persona activate AgentDraven
& '<vault>\scripts\merit.ps1' repo onboard <path>
& '<vault>\scripts\merit.ps1' cert foundation <project-id>
```
