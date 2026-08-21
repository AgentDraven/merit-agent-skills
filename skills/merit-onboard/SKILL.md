---
name: merit-onboard
description: MERIT OSS quickstart and vault persona/repo onboard.
---

# merit-onboard

## OSS quickstart (no vault)

```powershell
git clone --branch skills-v0.3.54 https://github.com/AgentDraven/merit-agent-skills.git
git clone https://github.com/Mr-PI-Bala/merit-demo.git
cd merit-agent-skills
.\merit.ps1 init --path ..\merit-demo
# edit ..\merit-demo\.merit_launch.md
.\merit.ps1 apply --path ..\merit-demo
.\merit.ps1 verify --path ..\merit-demo
```

Reference consumer: **Mr-PI-Bala/merit-demo**.

Deploy is optional and BYOK:

```powershell
.\merit.ps1 deploy --path ..\merit-demo
```

## Vault operators

```powershell
.\scripts\merit.ps1 persona activate AgentDraven
.\scripts\merit.ps1 repo onboard <path>
.\scripts\merit.ps1 cert foundation <project-id>
```
