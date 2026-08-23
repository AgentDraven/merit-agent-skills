# Merit-Hub — one file

**Download one script:** [`Merit-Hub.ps1`](Merit-Hub.ps1) — standalone, no git, no folder, no `.json`, no extra launcher.

## Windows: one command (not `.\Merit-Hub.ps1`)

A browser-downloaded `.ps1` is unsigned and has **Mark of the Web**. An already-open PowerShell session (`.\Merit-Hub.ps1`) uses **RemoteSigned** and refuses it. `pwsh` cannot unlock a file it was never allowed to start.

**One process flag is enough** (`Bypass` applies to this run only — not User/Machine policy):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

The script then **Unblock-File**s itself so later local copies are not treated as remote. Browser / SmartScreen **“this file can harm your computer”** is expected — **Keep**. Do not disable Defender or set ExecutionPolicy to Unrestricted.

## PowerShell 7 (pwsh) — required for daily use

Merit-Hub is written for **PowerShell 7+** (`pwsh`). You can **start once** with Windows PowerShell 5.1 (`powershell -NoProfile -ExecutionPolicy Bypass -File …`) to run menu **1** and install pwsh.

| Platform | Install |
|----------|---------|
| **Windows (winget)** | `winget install Microsoft.PowerShell` → `Program Files\PowerShell\7\` (system-wide) |
| **Windows (docs / MSI)** | [Installing PowerShell on Windows](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows) |
| **Windows (portable under Tools)** | Merit-Hub menu **1** → **[P]ortable** → `%MYMERITTOOLS%\pwsh\` + `pwsh.cmd` shim (stays inside Tools; we control the path) |
| **macOS** | `brew install powershell/tap/powershell` |
| **Linux** | [Installing PowerShell on Linux](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux) |
| **All platforms (zip)** | [GitHub releases](https://github.com/PowerShell/PowerShell/releases) |

**Does pwsh have to live in Tools?** No. **winget/MSI** installs one copy under Program Files and adds `pwsh` to PATH — that is normal. If you want everything MERIT-owned under **`C:\Tools`**, use menu **1 → Portable** so only `%MYMERITTOOLS%\pwsh\` + a small `pwsh.cmd` shim sit in Tools (not scattered).

## Skills install (no separate install.ps1 required)

After **J** (jumpstart OSS) — or menu **I** anytime — Merit-Hub copies `skills/` into your host (Cursor, Codex, Hermes, …). Same behavior as repo `install.ps1`:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1 -InstallSkills Cursor
```

Interactive: menu **I**.

## Download (no git)

1. Open **[Merit-Hub.ps1](Merit-Hub.ps1)** on GitHub → click **Raw** → Save As **`Merit-Hub.ps1`** (not the HTML page).
2. Save to **`C:\Tools\Merit-Hub.ps1`** (one file at Tools root — not a folder saved from the GitHub web UI).
3. Browser **Keep** if warned. Install pwsh (table above) if needed.
4. Run the **one command** above — first run prompts for **MYMERITTOOLS** / **MYMERITAPP** if unset (**Enter** = defaults `C:\Tools` / `C:\MyMeritApp`).

**`not digitally signed` / `PSSecurityException`?** You used `.\Merit-Hub.ps1`. Use the Bypass `-File` line.

**ParserError at MYMERITTOOLS?** You saved GitHub HTML instead of the script. Use **Raw** download again.

Raw: `https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1`

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
