# Merit-Hub — one file

**Download one script:** [`Merit-Hub.ps1`](Merit-Hub.ps1) — standalone, no git, no folder, no `.json`, no extra launcher.

`C:\Tools` (or `%MYMERITTOOLS%`) is a **laptop folder**, not a git repo. This file is what git stores. Menu **1** installs `merit-venv` and shims on the machine; do not copy your Tools tree back into this repo.

## New laptop sequence

1. Open [`Merit-Hub.ps1`](Merit-Hub.ps1) on GitHub → **Raw** → Save As `C:\Tools\Merit-Hub.ps1` (browser **Keep**). That is the only download.
2. Run this entire line (do not double-click):

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

3. First run: **Enter** for `MYMERITTOOLS` / `MYMERITAPP` (defaults `C:\Tools` / `C:\MyMeritApp`).
4. **1** Setup laptop — git / gh / pwsh + `merit-venv`. Does not re-download this script.
5. **2** (alias **J**) Install OSS — clones this repo at the `skills-v*` pin into `%MYMERITAPP%\merit-agent-skills` and seeds merit-demo.
6. **3** Try it locally. **OC** when you want DualRail play hosted on merit-prod.
7. **4** / **V** only if you have private-vault access (still local). **VC** is operator grade, not a hosted vault.
8. **5** / **R** optional: clone a catalog consumer or provider. **RC** is that repo on its host (usually Vercel), not OC.
9. **6** Join MERIT (**sign up**). Same key after **OC** (store register) or after **4** (operator/partner). Not OC-only.

The Hub prints this map every run. MOTW (Mark of the Web) and pwsh notes are below. MOTW is Windows tagging a browser download as internet-sourced, so a plain run is blocked.

## Required: run the full command

After you save the file, **start it with this entire line**. Do **not** double-click `Merit-Hub.ps1`. If you type `.\Merit-Hub.ps1` in Windows PowerShell 5.1, the script prints this command and re-launches `pwsh` when it is installed (no ParserError).

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

Windows treats an internet download as a security risk (unsigned script + **Mark of the Web**). A plain run is blocked (`not digitally signed` / `PSSecurityException`). macOS may quarantine a downloaded script the same way. `-ExecutionPolicy Bypass` applies to **this process only** — it does not change User/Machine policy. The script then **Unblock-File**s itself.

Browser / SmartScreen **“this file can harm your computer”** is expected — **Keep**. Do not disable Defender or set ExecutionPolicy to Unrestricted.

## PowerShell 7 (pwsh) — required for daily use

Merit-Hub is written for **PowerShell 7+** (`pwsh`). Windows PowerShell 5.1 can start the file: it prints the `pwsh` command and re-launches when pwsh is present. If pwsh is missing, stay in 5.1 for menu **1** to install it.

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

Do **1** then **2** first. The rest are branches from there.

| Key | Action |
|-----|--------|
| **1** | Setup laptop (prereqs + MYMERIT* + merit-venv) |
| **2** | Install OSS (skills pin + merit-demo + quiet smoke). Alias **J** |
| **3** | Try it — open local `play/index.html` |
| **OC** | OSS in the Cloud — DualRail play + **required** store activate + MERIT-hosted marketing site (`/play/site`) |
| **4** | Vault clone (still local; working clone kept). Alias **V** |
| **VC** | Venture Capable — operator/tenant grade vs freeware OC (not a hosted vault) |
| **5** | Catalog clone; role consumer or provider. Alias **R** |
| **RC** | That catalog repo on its host (usually Vercel) — not OC |
| **6** | Join MERIT (**sign up**) — portal + register. After **OC** or after **4** (not OC-only) |
| **0** | Stop |
| **P** | Pristine: wipe OSS bench, leftover `Tools\Merit-Hub\`, ~/dev, **MYMERIT* env** (next run prompts again), merit-venv. Keeps `C:\Tools\Merit-Hub.ps1`. |


## Hub baseline

Keys **1 2 3 OC 4 VC 5 R RC 6** are wired and working on the laptop Hub. **OC** DualRail product quality can still be validated separately; the Hub steps for those keys are baselined.

## VC is not a hosted vault

**4** clones the private vault onto this laptop. **VC** (Venture Capable) is operator grade on that clone: vault BootStrap, operator gates, `runtime out`. The vault is **not** published to merit-prod (that is OC / RC for other artifacts).

**Protected** means a **private GitHub remote**, not a public website:

1. `git remote -v` on the vault is the AgentDraven private remote (mXin) — never a public origin.
2. `.\scripts\merit.ps1 git verify` — tag matches VERSION, tree clean.
3. `.\scripts\merit.ps1 runtime out` then `runtime verify` — affiliate mirror.
4. Secrets stay in vault `env/` (not git). Product deploys use operator-gate hashes.

There is no vault play URL. If the vault tree is a public site, that is a fail.

**Validate VC:** Hub **4** (clone exists) → **VC** (BootStrap) → those four checks from the vault clone.

## Multi-creator benches (one PC)

A second **creator** is another OSS bench, not another Tools tree and not a subscriber.

Subscribers join `$0` on `/store/{oc-id}/register`. They never need `MYMERITAPP`.

```powershell
# Shared tools. Process-only bench (does not overwrite User MYMERITAPP).
pwsh -NoProfile -File C:\MyMeritApps\merit-agent-skills\Merit-Hub\oc-bench.ps1 `
  -Name creator-01 -ProductName 'Creator 01 DualRail' -All
pwsh -NoProfile -File C:\MyMeritApps\merit-agent-skills\Merit-Hub\oc-bench.ps1 `
  -Name creator-02 -ProductName 'Creator 02 DualRail' -All
```

Each bench is `%MYMERITAPP%` = `C:\MyMeritApps\benches\<name>` with its own `oss-bench.json` / `ocConsumerId`. `MYMERITTOOLS` stays `C:\MyMeritTools`. Same Hub, `-NewOc` if you want a second OC from **one** bench.

Cloud isolation is `consumer_id` on merit-prod (v0.1.84+). Two benches on an older gateway still collide on `play/index.html`.

## What the script creates locally

| Path | When |
|------|------|
| `backups\` | Next to the script |
| `%MYMERITTOOLS%\pwsh\` | Menu **1 → Portable** (optional) |
| `%MYMERITTOOLS%\merit-venv\` | Menu **1** |
| `%MYMERITAPP%\merit-agent-skills\` | Menu **J** or **I** |
| `%MYMERITAPP%\oss-bench.json` | Laptop status (human field names, including OC URLs) |
| `~/.cursor/skills\` (etc.) | Menu **I** / `-InstallSkills` |

Hub does **not** create `%MYMERITAPP%\BootStrap\` or `%MYMERITAPP%\MERIT_BootStrap.cmd`. Those leftover live copies are retired; Hub removes them on menu start / **J** / **2** / Pristine.
