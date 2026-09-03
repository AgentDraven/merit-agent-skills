# Merit Surface matrix (A × B × C)

Three install planes are **independent**. Merit-Hub and `merit.ps1 where` discover what is on disk without assuming vault or `~/dev`.

## Planes

| Sym | Name | What | Has public `merit.ps1`? |
|-----|------|------|-------------------------|
| **A** | IDE skills | `install.ps1` / Hub **I** → `~/.cursor/skills/merit-*` | No — markdown only |
| **B** | OSS bench | Full `merit-agent-skills` under `%MYMERITAPP%` + `oss-bench.json` | Yes — repo root |
| **C** | Vault | `merit-private-vault` clone | Yes — `scripts\merit.ps1` (operator) |

**Related (not in A×B×C factorial):**

| Sym | What | Required for |
|-----|------|--------------|
| **H** | `Merit-Hub.ps1` at `%MYMERITTOOLS%` | Cold start when B missing |
| **D** | `merit-demo` under `%MYMERITAPP%` | Hub **3**, **OC** (not validate alone) |
| **T** | `%MYMERITTOOLS%\merit-venv` or `merit-python` shim | Flask demo; vault Python later |

## 8 combinations

| # | A | B | C | Edition | Public CLI | Operator CLI | Recovery |
|---|---|---|---|---------|------------|--------------|----------|
| 0 | — | — | — | `none` | N/A | N/A | Hub **1→2→3** |
| 1 | ✓ | — | — | `ide-only` | Not on disk | N/A | Hub **2** or clone B |
| 2 | — | ✓ | — | `oss` | `B\merit.ps1` | N/A | `merit.ps1 where` |
| 3 | ✓ | ✓ | — | `oss+ide` | `B\merit.ps1` | N/A | Re-run Hub **I** |
| 4 | — | — | ✓ | `vault-only` | N/A until **2** | Vault CLI | Hub **2** |
| 5 | ✓ | — | ✓ | `vault+ide` | N/A until **2** | Vault CLI | Hub **2** |
| 6 | — | ✓ | ✓ | `oss+vault` | `B\merit.ps1` | Vault CLI | Tiered closeout |
| 7 | ✓ | ✓ | ✓ | `full` | `B\merit.ps1` | Vault CLI | Operator + OSS |

**Deleted B** (env points at missing folder): treat as B absent; resolver validates `merit.ps1` at every step.

**Pristine + A remains**: edition **1**; `.merit-surface.json` may reference deleted B → `staleIdeMarker` + Hub **2**.

**Steps 3 / OC** require **D** in addition to **B**.

## Diagnostic commands

```powershell
# B present:
.\merit.ps1 where
.\merit.ps1 where -NoWrite    # CI / read-only

# B missing (A-only or fresh laptop):
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1 -Surface
# Hub menu: W
```

## Env vars

| Var | Purpose |
|-----|---------|
| `MYMERITAPP` | OSS bench root |
| `MYMERITTOOLS` | Hub + merit-venv |
| `MERIT_SKILLS_ROOT` | Optional override for B |
| `MERIT_VAULT_ROOT` | Optional override for C |
| `MERIT_SHIP_OSS` | Allow `ship` when C also present |

## Closeout tiers

| Goal | Command |
|------|---------|
| Validate OSS | `.\merit.ps1 closeout --path .` |
| Ship `skills-v*` (no vault) | `.\merit.ps1 ship -Message "..."` |
| Operator release | `& <vault>\scripts\merit.ps1 mXin ...` |
| Diagnostic | `.\merit.ps1 where` or `Merit-Hub.ps1 -Surface` |

## IDE marker

After `install.ps1` or Hub **I**, each host `destRoot` gets `.merit-surface.json` (hint only — resolver re-validates B path).
