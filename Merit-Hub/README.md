# Merit-Hub — one file

**Download one script:** [`Merit-Hub.ps1`](Merit-Hub.ps1) — standalone, no git, no folder, no `.json`, no extra launcher.

## Required: run the full command

After you save the file, **you must start it with this entire line**. Do **not** double-click `Merit-Hub.ps1`, and do **not** type `.\Merit-Hub.ps1` in an already-open PowerShell window.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

Windows treats an internet download as a security risk (unsigned script + **Mark of the Web**). A plain run is blocked (`not digitally signed` / `PSSecurityException`). macOS may quarantine a downloaded script the same way. `-ExecutionPolicy Bypass` applies to **this process only** — it does not change User/Machine policy. The script then **Unblock-File**s itself.

Browser / SmartScreen **“this file can harm your computer”** is expected — **Keep**. Do not disable Defender or set ExecutionPolicy to Unrestricted.

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
4. **Required** — paste the full command (do not double-click the file):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

First run prompts for **MYMERITTOOLS** / **MYMERITAPP** if unset (**Enter** = defaults `C:\Tools` / `C:\MyMeritApp`).

**`not digitally signed` / `PSSecurityException`?** You did not use the full command. Double-click and `.\Merit-Hub.ps1` are blocked for internet downloads.

**ParserError at MYMERITTOOLS?** You saved GitHub HTML instead of the script. Use **Raw** download again.

Raw: `https://raw.githubusercontent.com/AgentDraven/merit-agent-skills/main/Merit-Hub/Merit-Hub.ps1`

## Hub menu (short)

| Key | Action |
|-----|--------|
| **J** | PHASE 1 prereqs + skills clone, then **PHASE 2** (green) demo + validate in the **same** script |
| **2** | PHASE 2 OSS bench menu only (after a clone exists) |
| **V** | Clone vault + BootStrap |
| **I** | Install skills to Cursor / Codex / Hermes / … |
| **1** | Prereqs: lists Git/gh/pwsh **and** MERIT Python venv MISSING/OK; `y` only installs those items and SETs empty `MYMERIT*` User env |
| **P** | Pristine: wipe OSS bench, leftover `Tools\Merit-Hub\`, ~/dev, **MYMERIT* env** (next run prompts again), merit-venv. Keeps `C:\Tools\Merit-Hub.ps1`. UAC-elevates. Then asks about leftover folders (`HumanBala`, `DravenCode.OLD`, `Code`, `*Merit*`) — type **DELETE** to remove. Window stays open until **Enter**. Log: `backups\Merit-Hub-history.log` (append). |

## What the script creates locally

| Path | When |
|------|------|
| `backups\` | Next to the script |
| `%MYMERITTOOLS%\pwsh\` | Menu **1 → Portable** (optional) |
| `%MYMERITTOOLS%\merit-venv\` | Menu **1** |
| `%MYMERITAPP%\merit-agent-skills\` | Menu **J** or **I** |
| `~/.cursor/skills\` (etc.) | Menu **I** / `-InstallSkills` |
