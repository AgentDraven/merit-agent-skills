---
name: merit-iar
description: MERIT IAR acceptance IDs and cross-repo handoff rules.
---

# merit-iar

Acceptance IDs: `{ACRONYM}-{PROVIDER}-{NN}`. Operational readiness requires requester-IAR ACCEPT.

## Law

```powershell
.\merit.ps1 law --for-skill merit-iar
```

## OSS (always)

```powershell
.\merit.ps1 verify --path <consumer-repo>
```

## Operator (plane C only)

Resolve: `.\merit.ps1 where` → `operatorMeritCli`.

```powershell
& '<vault>\scripts\merit.ps1' cert status <project-id>
```
