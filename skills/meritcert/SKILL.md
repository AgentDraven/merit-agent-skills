---
name: meritcert
description: MERIT foundation certification, capability integration, graph status, and validation.
---

# meritcert

Vocabulary for certification commands. OSS users document status; vault operators run writes.

```powershell
.\merit-live.ps1 verify --path <consumer-repo>
```

Vault operators (cert registry writes):

```powershell
.\scripts\merit.ps1 cert foundation <project-id>
.\scripts\merit.ps1 cert integration <provider> <consumer> --capability <id> --iar-ref "<path>" --pin <package@version>
.\scripts\merit.ps1 cert status [project-id]
.\scripts\merit.ps1 cert validate --json --diagram ascii
```

All explicit technical approval goes through AgentDraven. Requester-IAR ACCEPT is required for operational readiness.
