# Merit-Hub — one file

**Download one script:** [`Merit-Hub.ps1`](Merit-Hub.ps1) — standalone, no git, no folder, no `.json`.

Save it anywhere (default: **`C:\Tools\Merit-Hub.ps1`**) and run:

```powershell
# Windows — PowerShell 7+ (recommended)
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1

# Windows — built-in Windows PowerShell 5.1 also works
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

```bash
# Linux / macOS (PowerShell 7+ required)
pwsh Merit-Hub.ps1
```

That opens the menu. **J** jumpstarts OSS, **V** jumpstart vault, **P** pristine laptop reset. Release pins are **inside the script** — no config file.

## Download (no git)

1. Open **[Merit-Hub.ps1](Merit-Hub.ps1)** on GitHub.
2. **Raw** → Save As → `Merit-Hub.ps1` (e.g. under `C:\Tools\`).
3. Run the command above.

Direct raw link (replace `main` with a `skills-v*` tag for a frozen pin):

`https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1`

## What the script creates locally

| Path | When |
|------|------|
| `backups\<timestamp>\` | Next to the script, on Pristine / Soft / Backup |
| `C:\Tools\merit-venv\` | Menu **1** or jumpstart (MYMERITTOOLS root) |
| `%MYMERITAPP%\merit-agent-skills\` | Menu **J** (default bench `C:\MyMeritApp`) |
| `~/dev\...\merit-private-vault\` | Menu **V** |

**P** keeps **`Merit-Hub.ps1`** itself; it removes bench clones, `~/dev`, and merit-venv/shims under Tools.

## Naming

| Name | Role |
|------|------|
| **Merit-Hub.ps1** | This laptop hub (this file) |
| **merit.ps1** | Public CLI inside `merit-agent-skills` (cloned by **J**) |
| **MERIT.ps1** | Vault operator CLI under `~/dev` (after **V**) |
