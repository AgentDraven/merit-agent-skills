---
name: meritcert
description: MERIT foundation certification, capability integration, graph status, and validation.
---

# meritcert

Vocabulary for certification. OSS documents status; vault operators run writes.

## Law

```powershell
.\merit.ps1 law --for-skill meritcert
```

## OSS (always)

```powershell
.\merit.ps1 verify --path <consumer-repo>
```

## Operator (plane C only)

Resolve: `.\merit.ps1 where` → `operatorMeritCli`.

```powershell
& '<vault>\scripts\merit.ps1' cert foundation <project-id>
& '<vault>\scripts\merit.ps1' cert integration <provider> <consumer> --capability <id> --iar-ref "<path>" --pin <package@version>
& '<vault>\scripts\merit.ps1' cert status [project-id]
```

Requester-IAR ACCEPT required for operational readiness.
