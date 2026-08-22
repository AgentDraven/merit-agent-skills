# Merit-Hub — one file

**Download one script:** [`Merit-Hub.ps1`](Merit-Hub.ps1) — standalone, no git, no folder, no `.json`.

## PowerShell 7 (pwsh) — required for daily use

Merit-Hub is written for **PowerShell 7+** (`pwsh`). You can **start once** with Windows PowerShell 5.1 (`powershell -File …`) to run menu **1** and install pwsh.

| Platform | Install |
|----------|---------|
| **Windows (winget)** | `winget install Microsoft.PowerShell` → `Program Files\PowerShell\7\` (system-wide) |
| **Windows (docs / MSI)** | [Installing PowerShell on Windows](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows) |
| **Windows (portable under Tools)** | Merit-Hub menu **1** → **[P]ortable** → `%MYMERITTOOLS%\pwsh\` + `pwsh.cmd` shim (stays inside Tools; we control the path) |
| **macOS** | `brew install powershell/tap/powershell` |
| **Linux** | [Installing PowerShell on Linux](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux) |
| **All platforms (zip)** | [GitHub releases](https://github.com/PowerShell/PowerShell/releases) |

**Does pwsh have to live in Tools?** No. **winget/MSI** installs one copy under Program Files and adds `pwsh` to PATH — that is normal. If you want everything MERIT-owned under **`C:\Tools`**, use menu **1 → Portable** so only `%MYMERITTOOLS%\pwsh\` + a small `pwsh.cmd` shim sit in Tools (not scattered).

Then run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

## Skills install (no separate install.ps1 required)

After **J** (jumpstart OSS) — or menu **I** anytime — Merit-Hub copies `skills/` into your host (Cursor, Codex, Hermes, …). Same behavior as repo `install.ps1`:

```powershell
pwsh -File C:\Tools\Merit-Hub.ps1 -InstallSkills Cursor
```

Interactive: menu **I**.

## Download (no git)

1. Open **[Merit-Hub.ps1](Merit-Hub.ps1)** on GitHub → **Raw** → Save As `C:\Tools\Merit-Hub.ps1`
2. Install pwsh (table above)
3. `pwsh -File C:\Tools\Merit-Hub.ps1`

Raw link: `https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1`

## Hub menu (short)

| Key | Action |
|-----|--------|
| **J** | Clone OSS + optional skills install + BootStrap |
| **V** | Clone vault + BootStrap |
| **I** | Install skills to Cursor / Codex / Hermes / … |
| **1** | Prereqs (git, gh, pwsh, merit-venv) |
| **P** | Pristine laptop reset |

## What the script creates locally

| Path | When |
|------|------|
| `backups\` | Next to the script |
| `%MYMERITTOOLS%\pwsh\` | Menu **1 → Portable** (optional) |
| `%MYMERITTOOLS%\merit-venv\` | Menu **1** |
| `%MYMERITAPP%\merit-agent-skills\` | Menu **J** or **I** |
| `~/.cursor/skills\` (etc.) | Menu **I** / `-InstallSkills` |
