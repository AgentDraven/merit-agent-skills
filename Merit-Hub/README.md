# Merit-Hub — laptop hub

Single entry under **`%MYMERITTOOLS%\Merit-Hub`** (default **`C:\Tools\Merit-Hub`**).

Script name **`Merit-Hub`** — distinct from repo **`merit.ps1`** (public CLI) and **`MERIT.ps1`** (vault operator copy under `~/dev`).

| Launcher | Role |
|----------|------|
| **`Merit-Hub.cmd`** / **`Merit-Hub.ps1`** / **`Merit-Hub.sh`** | Hub menu + switches |

Config: [`Merit-Hub.json`](Merit-Hub.json) (pins `skills-v0.5.1` / `vault-v0.5.2`).

## Quick start

```powershell
cd C:\Tools\Merit-Hub
.\Merit-Hub.cmd
# P = Pristine v2  |  J = Jumpstart OSS  |  V = Jumpstart Vault
```

Non-interactive:

```powershell
.\Merit-Hub.cmd -Pristine -Force
.\Merit-Hub.cmd -Jumpstart Oss
.\Merit-Hub.cmd -Jumpstart Vault
.\Merit-Hub.cmd -Prereqs -Force
```

Linux/macOS: `./Merit-Hub.sh` (needs `pwsh`).

## Install from git

Copy this folder from **`merit-agent-skills/Merit-Hub`** to your laptop tools root:

```powershell
# default target
Copy-Item -Recurse -Force .\Merit-Hub C:\Tools\Merit-Hub
cd C:\Tools\Merit-Hub
.\Merit-Hub.cmd
```

Or run [`install.ps1`](install.ps1) from the repo copy.

## Environment variables

| Variable | Default (Windows) | Purpose |
|----------|-------------------|---------|
| **`MYMERITTOOLS`** | `C:\Tools` | Tools root — `merit-venv`, shims |
| **`MYMERITAPP`** | `C:\MyMeritApp` | OSS bench |

Menu **T** / **M** set and display paths (User env).

## Naming (avoid confusion)

| Name | Where | Role |
|------|-------|------|
| **Merit-Hub** | `C:\Tools\Merit-Hub\Merit-Hub.*` | Laptop cold-start / cleanup |
| **merit.ps1** | `merit-agent-skills` repo root | Public freemium CLI |
| **MERIT.ps1** | `~/dev` after vault BootStrap | Operator CLI mirror |
| **MERIT.json** | `~/dev` or `BootStrap/` | BootStrap registry (not Merit-Hub.json) |

## Pristine v2

**P** wipes OSS bench, **~/dev** tree + folder, **merit-venv** under MYMERITTOOLS, clears **MYMERITAPP** / **MYMERITTOOLS**, strips **~/dev** from User Path. Keeps **`C:\Tools\Merit-Hub`** hub files.

Open a **new terminal** after Pristine, then **J** to jumpstart.

Backups: `backups\<timestamp>\`
