---
name: merit-iar
description: MERIT IAR acceptance IDs and cross-repo handoff rules.
---

# merit-iar

Acceptance IDs: `{ACRONYM}-{PROVIDER}-{NN}` (e.g. `STN-MSU-01`). Operational readiness requires requester-IAR ACCEPT.

```powershell
.\merit-live.ps1 verify --path <consumer-repo>
```

Vault operators:

```powershell
.\scripts\merit.ps1 cert status <project-id>
```
