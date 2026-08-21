# BootStrap — design & introduction (OSS)

## Purpose

Separate **device BootStrap** from the public **MERIT CLI** (`merit.ps1`) so builders get a one-command laptop setup without confusing it with `init` / `apply` / `verify`.

## Layout

| Location | Role |
|----------|------|
| `BootStrap/MERIT_BootStrap.ps1` (+ `.cmd` / `.sh`) | OSS BootStrap menu |
| `BootStrap/MERIT.json` | Local status template (no secrets) |
| `BootStrap/README.md` | Operator-facing how to run |
| `%MYMERITAPP%` (default `C:\MyMeritApp`) | Live OSS bench after first run |

## MYMERITAPP

Bench root is not hard-coded forever. First run (or menu **M**) prompts for a path and sets User environment variable **`MYMERITAPP`**. Scripts read process env, then User env, then default `C:\MyMeritApp`.

## Private-Vault teaser (no IP leak)

Menu **T** / **P** may mention only:

1. AgentDraven hosts the private ecosystem account  
2. Private repo `merit-private-vault` exists  
3. That repo contains `BootStrap` to install into `~/dev`  

Clone still requires GitHub permission. Vault product law stays out of this public repo.

## How this branch was landed (one-time)

On 2026-08-20 the work was preserved from a detached `skills-v0.3.53` checkout under `C:\MyMeritApp\merit-agent-skills`:

1. Backup `BootStrap/` + `README.md` to a temp folder  
2. `git fetch origin`  
3. `git checkout -B bootstrap/oss-bootstrap origin/main`  
4. Restore/ensure `BootStrap/` and README Start-here row  
5. Add `docs/design.md` BootStrap section + this file + CHANGELOG entry  
6. Commit and `git push -u origin bootstrap/oss-bootstrap`  
7. Merge to `main`, then baseline release **`skills-v0.3.54`** (menus 1–4 restored; pin docs + tag)

## Cold start (baseline)

```powershell
git clone --branch skills-v0.3.54 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills\BootStrap
.\MERIT_BootStrap.cmd
# Menu T = vault teaser; Menu P = clone AgentDraven/merit-private-vault @ v1.8.68 (GCM credentials)
```
