# BootStrap pathway (OSS → Private handoff)

Annotated flowchart for a **new laptop** on the public freeware path. Private-Vault continuation (affiliate **MAD**, persona/repo picker) lives in the vault doc [`vault_usage.md` §7c](https://github.com/AgentDraven/merit-private-vault/blob/main/docs/vault_usage.md#7c-device-bootstrap--affiliate-pathway) (operators only).

**Laptop shared:** `%MYMERITTOOLS%\merit-venv` (default `C:\Tools`) is installed by **OSS BootStrap menu 1** and Merit-Hub prereqs (same path Private-Vault uses). Affiliate / `runtime out` remain Private-Vault only.

## Cold start

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

Save Hub via **Raw** first. Menu **J** clones the current `skills-v*` pin into `%MYMERITAPP%\merit-agent-skills` and continues as PHASE 2. Do **not** copy `BootStrap/` to `%MYMERITAPP%\BootStrap\`.

Use the current public pin (see repo `VERSION` / tags). Clone **from** the bench folder only if you are installing skills by hand so the repo lands at `%MYMERITAPP%\merit-agent-skills`.

## OSS pathway flowchart

```mermaid
flowchart TD
  start([New_laptop]) --> ossOrPriv{OSS_only_or_Private}

  ossOrPriv -->|OSS_freeware| ossA[mkdir_MYMERITAPP]
  ossA --> ossB[Hub_J_clone_skills]
  ossB --> ossC[PHASE2_D_then_G]
  ossC --> ossDone([OSS_done])
  ossDone --> wantPriv{Want_Private_Vault}
  wantPriv -->|No| stayOss([stay_freeware])
  wantPriv -->|Yes_key_3| handoff[PHASE3_clone_vault]

  ossOrPriv -->|Have_vault_access| handoff
```

### What happens at each step

- **New_laptop / OSS_only_or_Private:** Choose public freeware (skills + demo) vs an operator path that needs GitHub access to the private vault. OSS never creates an affiliate runtime.
- **mkdir_MYMERITAPP:** Create the OSS bench root (default `C:\MyMeritApp`). Hub first run (or menu **M**) can also set User env `MYMERITAPP`.
- **Hub_J_clone_skills:** Merit-Hub **J** clones this public repo at a release tag (`skills-v*`) into the bench. PHASE 2 is `_oss.ps1` inside that clone — not a second script.
- **PHASE2_D_then_G:** Seed `merit-demo`, then validate (`closeout` + `smoke`). Freeware OSS is done here.
- **Want_Private_Vault:** Stay on OSS forever, or continue with PHASE 3 key **3**.
- **PHASE3_clone_vault:** Clones the private vault at the pinned release tag (needs credentials / GCM), then launches **Private-Vault** BootStrap. Continue there with edition **V**.

Do **not** create `%MYMERITAPP%\BootStrap\` or `%MYMERITAPP%\MERIT_BootStrap.cmd`. Those were a retired live copy of the old BootStrap product.

## What OSS BootStrap does *not* do

| Concern | OSS? | Where instead |
|---------|------|----------------|
| Affiliate id / `%USERPROFILE%\{id}` | No | Vault affiliate wizard → default **MAD** |
| `runtime out` / `runtime verify` | No | Vault `scripts/merit.ps1` after affiliate configured |
| Persona/repo bulk clone into `~/dev` | No | Vault BootStrap picker (after affiliate) |
| Marketing attribution skill | Separate | Public skill `merit-affiliate` (not operator runtime) |
| Full L1 / L2 product law | No | Private vault `instructions/`; OSS uses skills + pointer stubs |

## MERIT Python on the laptop

`C:\Tools\merit-venv` is **not** assumed pre-installed. Hub **1** / PHASE 1 prereqs create it (same path Private-Vault uses). Public root `merit.ps1` remains PowerShell-first; Tools Python helps **merit-demo / Flask** and later vault `scripts/merit.ps1`.

## After first clone — use merit.ps1 (not raw git)

Cold start may use `git clone` **once**. After that:

- OSS consumer work: `.\merit.ps1` (`verify` / `closeout` / `init` / …)
- Operator closing this skills repo or the vault: vault `scripts/merit.ps1` → **`mXin`** / **`mXout`** / **`git verify`** / **`runtime out`**

Do not agent-closeout with raw `git commit`/`tag`/`push`. See vault §7c.7.

## Related

- [BootStrap/README.md](../BootStrap/README.md) — how to run
- [docs/bootstrap.design.md](bootstrap.design.md) — design / L1–L3 / agent host registry / merit.ps1 law
- [`cfg/agent_hosts.json`](../cfg/agent_hosts.json) — host install + detectHints
- Root [README.md](../README.md) Start-here — OSS BootStrap row
