# MERIT BootStrap

How device bootstrap works for OSS vs Private-Vault. Use the word **BootStrap** everywhere (not "genesis").

## Two different `merit` scripts

| Script | Role |
|--------|------|
| **Repo-root `merit.ps1`** | MERIT **CLI** — `init` / `apply` / `verify` / `create` / … (ecosystem runtime) |
| **`BootStrap/MERIT_BootStrap.*`** | Device **BootStrap** — prereqs, clones, validate, editions |

Do not overwrite the CLI with BootStrap (or the reverse).

## Where it lives in GitHub vs on disk

| Edition | Stored in GitHub | First run installs live copy to |
|---------|------------------|-----------------------------------|
| **OSS** | `merit-agent-skills/BootStrap/` | `C:\MyMeritApp\BootStrap\` (+ `C:\MyMeritApp\MERIT_BootStrap.cmd`) |
| **Private-Vault** | `merit-private-vault/BootStrap/` | `~\dev\` (MERIT ecosystem root; `merit.cmd` + `MERIT_BootStrap.*`) |

Re-running BootStrap refreshes the scripts; it keeps an existing `MERIT.json` status file when present.

## Run

**OSS**

```powershell
cd <clone>\merit-agent-skills\BootStrap
.\MERIT_BootStrap.cmd
# after install:
C:\MyMeritApp\MERIT_BootStrap.cmd
```

**Private-Vault (operators)**

```powershell
cd <clone>\merit-private-vault\BootStrap
.\MERIT_BootStrap.cmd
# after install:
cd ~\dev
.\merit.cmd
# or: .\MERIT_BootStrap.cmd
```

## Editions (Private-Vault BootStrap only)

- **OSS** — public path + Private-Vault **teaser** (subscription = FUTURE)
- **Private-Vault** — unlocks with GitHub identity **AgentDraven** or **Mr-PI-Bala**

OSS repo BootStrap stays OSS-only (teaser, no L1 product law).

## Safe to re-run

Prereqs and install are idempotent: status checks, optional installs, script refresh. They do not wipe clones.
