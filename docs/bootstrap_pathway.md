# BootStrap pathway (OSS â†’ Private handoff)

Annotated flowchart for a **new laptop** on the public freeware path. Private-Vault continuation (affiliate **MAD**, Tools Python, persona/repo picker) lives in the vault doc [`vault_usage.md` Â§7c](https://github.com/AgentDraven/merit-private-vault/blob/main/docs/vault_usage.md#7c-device-bootstrap--affiliate-pathway) (operators only).

**Not covered here:** operator affiliate runtime, `runtime out`, or `C:\Tools\merit-venv`. Those are Private-Vault BootStrap only.

## Cold start

```powershell
mkdir C:\MyMeritApp
cd C:\MyMeritApp
git clone --branch skills-v0.3.57 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills\BootStrap
.\MERIT_BootStrap.cmd
```

Use the current public pin if newer than `skills-v0.3.57` (see repo `VERSION` / tags). Clone **from** the bench folder so the repo lands at `%MYMERITAPP%\merit-agent-skills`.

## OSS pathway flowchart

```mermaid
flowchart TD
  start([New_laptop]) --> ossOrPriv{OSS_only_or_Private}

  ossOrPriv -->|OSS_freeware| ossA[mkdir_MYMERITAPP]
  ossA --> ossB[clone_skills_pin]
  ossB --> ossC[run_OSS_BootStrap]
  ossC --> ossD[optional_menus_1_4]
  ossD --> ossT[T_teaser]
  ossT --> wantPriv{Want_Private_Vault}
  wantPriv -->|No| ossDone([OSS_done])
  wantPriv -->|Yes_menu_P| handoff[P_clone_vault_and_launch]

  ossOrPriv -->|Have_vault_access| handoff
```

### What happens at each step

- **New_laptop / OSS_only_or_Private:** Choose public freeware (skills + demo) vs an operator path that needs GitHub access to the private vault. The OSS path never creates an affiliate runtime folder and never installs Tools MERIT Python.
- **mkdir_MYMERITAPP:** Create the OSS bench root (default `C:\MyMeritApp`). First BootStrap run (or menu **M**) can also set User env `MYMERITAPP`.
- **clone_skills_pin:** Clone this public repo at a release tag (`skills-v*`). Prefer cloning into the bench so paths match BootStrap expectations.
- **run_OSS_BootStrap:** Run `BootStrap\MERIT_BootStrap.cmd`. That installs/refreshes live BootStrap under `%MYMERITAPP%\BootStrap\` and a launcher `%MYMERITAPP%\MERIT_BootStrap.cmd`.
- **optional_menus_1_4:** Prerequisites, ensure skills under the bench, seed `merit-demo`, closeout/smoke. Safe to skip if you only need the Private teaser/handoff.
- **T_teaser:** Public facts only â€” AgentDraven hosts the private ecosystem account; repo `merit-private-vault` exists; that repoâ€™s BootStrap installs into `~/dev`. No L1 product law in this public folder.
- **Want_Private_Vault:** Stay on OSS forever, or continue with menu **P**.
- **P_clone_vault_and_launch:** Clones the private vault at the pinned release tag (needs credentials / GCM), then launches **Private-Vault** BootStrap. Continue there with edition **V**. See vault Â§7c for affiliate **MAD**, Tools Python, and `~/dev` populate.

## What OSS BootStrap does *not* do

| Concern | OSS? | Where instead |
|---------|------|----------------|
| `C:\Tools\merit-venv` / Tools Python | No | Private-Vault BootStrap menu 1 (edition **V**) |
| Affiliate id / `%USERPROFILE%\{id}` | No | Vault affiliate wizard â†’ default **MAD** |
| `runtime out` / `runtime verify` | No | Vault `scripts/merit.ps1` after affiliate configured |
| Persona/repo bulk clone into `~/dev` | No | Vault BootStrap picker (after affiliate) |
| Marketing attribution skill | Separate | Public skill `merit-affiliate` (not operator runtime) |
| Full L1 / L2 product law | No | Private vault `instructions/`; OSS uses skills + pointer stubs |

## L1 / L2 / L3 and any AI IDE (summary)

MERIT keeps instructions **inside the ecosystem** (L1 platform → L2 persona → optional L3 project). Cursor, Codex, Claude Code, Hermes, Paperclip, OpenClaw, Grok Bot, Devin, and future hosts only **install skills** or read `AGENTS.md` — they do not replace L1.

Full design + **`cfg/agent_hosts.json`** (auto-detect hints, supported/planned/research hosts): [bootstrap.design.md](bootstrap.design.md#instruction-chain-l1--l2--l3--why-merit-stays-host-agnostic).

## After first clone — use merit.ps1 (not raw git)

Cold start may use `git clone` **once**. After that:

- OSS consumer work: `.\merit.ps1` (`verify` / `closeout` / `init` / …)
- Operator closing this skills repo or the vault: vault `scripts/merit.ps1` → **`mXin`** / **`mXout`** / **`git verify`** / **`runtime out`**

Do not agent-closeout with raw `git commit`/`tag`/`push`. See vault §7c.7 and [bootstrap.design.md](bootstrap.design.md#operator--agent-law--meritps1-after-first-clone).

## Related

- [BootStrap/README.md](../BootStrap/README.md) — how to run
- [docs/bootstrap.design.md](bootstrap.design.md) — design / L1–L3 / agent host registry / merit.ps1 law
- [`cfg/agent_hosts.json`](../cfg/agent_hosts.json) — host install + detectHints
- Root [README.md](../README.md) Start-here — OSS BootStrap row
