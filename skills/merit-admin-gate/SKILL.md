---
name: merit-admin-gate
description: MeritAdminGate phrase auth (adj-noun-pin); demo init via merit CLI; vault hash for operators.
---

# merit-admin-gate

Phrase format: `{adjective}-{noun}-{####}`. Wordlists are public; hashes never in git.

## Law

```powershell
.\merit.ps1 law --for-skill merit-admin-gate
```

## OSS (always)

```powershell
.\merit.ps1 admin gate demo-init --path <consumer-repo>
```

## Operator (plane C only)

Resolve: `.\merit.ps1 where` → `operatorMeritCli`.

```powershell
& '<vault>\scripts\merit.ps1' admin operator-gate hash -Project <id> --phrase adj-noun-#### --label <tag>
& '<vault>\scripts\merit.ps1' deploy vercel -Project <id> --sync-env
```

Revoke via vault CLI. Phrase never in chat/git.
