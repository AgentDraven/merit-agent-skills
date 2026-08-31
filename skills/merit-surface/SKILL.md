---
name: merit-surface
description: Merit Surface map — discover OSS bench (B), IDE skills (A), vault (C), Hub (H), merit-demo (D). Use when paths are unclear or after Pristine.
---

# merit-surface

## Planes

| Sym | What | Has `merit.ps1`? |
|-----|------|------------------|
| **A** | IDE skills (`~/.cursor/skills/merit-*`) | No — instructions only |
| **B** | OSS bench `%MYMERITAPP%\merit-agent-skills` | Yes — public CLI |
| **C** | Vault `merit-private-vault` | Yes — `scripts\merit.ps1` (operator) |
| **H** | `Merit-Hub.ps1` at `%MYMERITTOOLS%` | Bootstrap only |
| **D** | `merit-demo` under `%MYMERITAPP%` | Consumer app (Hub 3/OC) |

## Diagnostic

```powershell
# When B exists:
pwsh -NoProfile -File "%MERIT_SKILLS_ROOT%\merit.ps1" where

# Or from B clone:
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 where

# When B missing (A-only or fresh laptop):
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1 -Surface
# Hub menu: W
```

## Env vars (canonical)

- `MYMERITAPP` — OSS bench root
- `MYMERITTOOLS` — Hub + merit-venv
- `MERIT_SKILLS_ROOT` — optional override for B
- `MERIT_VAULT_ROOT` — optional override for C

## 8 combinations (A × B × C)

| # | A | B | C | Edition | Recovery |
|---|---|---|---|---------|----------|
| 0 | — | — | — | none | Download Hub; run 1→2 |
| 1 | ✓ | — | — | ide-only | Hub 2 clones B |
| 2 | — | ✓ | — | oss | `merit.ps1 where` |
| 3 | ✓ | ✓ | — | oss+ide | Re-run Hub I after git pull |
| 4 | — | — | ✓ | vault-only | Hub 2 for OSS/OC |
| 5 | ✓ | — | ✓ | vault+ide | Hub 2 for public CLI |
| 6 | — | ✓ | ✓ | oss+vault | Tiered closeout |
| 7 | ✓ | ✓ | ✓ | full | Operator + OSS |

**D** (`merit-demo`) is required for Hub **3** and **OC** in addition to **B**.

## Closeout tiers

1. **OSS validate:** `.\merit.ps1 closeout --path <repo>`
2. **OSS ship skills-v*:** `.\merit.ps1 ship -Message "..."` (no vault on disk)
3. **Operator:** `& <vault>\scripts\merit.ps1 mXin` when C present

## Agents

Never assume `~/dev` or Cursor workspace path. Resolve via `MYMERITAPP` → `oss-bench.json` → `merit.ps1 where`.
