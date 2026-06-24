---
name: merit-onboard
description: MERIT OSS quickstart and vault persona/repo onboard.
---

# merit-onboard

## OSS quickstart (no vault)

```powershell
git clone https://github.com/AgentDraven/merit-agent-skills.git
git clone https://github.com/Mr-PI-Bala/merit-demo.git
cd merit-agent-skills
.\merit-live.ps1 par scaffold --path ..\merit-demo --variant workbench-journal
.\merit-live.ps1 branding scaffold --path ..\merit-demo
.\merit-live.ps1 subs scaffold --path ..\merit-demo
.\merit-live.ps1 deploy vercel --path ..\merit-demo
```

Reference consumer: **Mr-PI-Bala/merit-demo**.

## Vault operators

```powershell
.\scripts\merit.ps1 persona activate AgentDraven
.\scripts\merit.ps1 repo onboard <path>
.\scripts\merit.ps1 cert foundation <project-id>
```
