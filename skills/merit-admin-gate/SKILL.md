---
name: merit-admin-gate
description: MeritAdminGate phrase auth (adj-noun-pin); demo init via merit-live; vault hash for operators.
---

# merit-admin-gate

Phrase format: `{adjective}-{noun}-{####}` (four digits). Wordlists are public; hashes are never in git.

```powershell
.\merit-live.ps1 admin gate demo-init --path <consumer-repo>
```

Vault operators (production hash slots + Vercel sync):

```powershell
.\scripts\merit.ps1 admin operator-gate hash -Project <id> --phrase adj-noun-#### --label <tag>
.\scripts\merit.ps1 deploy vercel -Project <id> --sync-env
```

Revoke: `admin operator-gate revoke --label <tag>`. Phrase never in chat/git.
