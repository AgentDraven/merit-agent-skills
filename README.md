# merit-agent-skills

Free **MERIT agent skills** and **`merit`** CLI — one-stop OSS cold start for **Cursor**, **Claude Code**, **Codex**, **VS Code / Open Agents**, **Hermes**, **OpenClaw**, **Grok Bot**, **Devin**, and more agent harnesses (see [Collaboration](#collaboration--suggest-a-host)).

## Start here

| Goal | Path |
|------|------|
| **Laptop hub (easiest cold start)** | **[Download `Merit-Hub.ps1`](Merit-Hub/Merit-Hub.ps1)** to `C:\Tools\`. **Required** (do not double-click / `.\`): `pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1`. Internet downloads are blocked otherwise. Details: [Merit-Hub/README.md](Merit-Hub/README.md). **J** OSS · **V** vault · **P** reset. |
| **Build over dinner (start here)** | **[HowToLaunch-Over-Dinner-Tutorial.md](HowToLaunch-Over-Dinner-Tutorial.md)** â€” 3 steps, no accounts night one |
| **OSS BootStrap** | Internal **PHASE 2** inside Merit-Hub (not a second product). Hub **J** dotsources `BootStrap/_oss.ps1` in the skills clone. Do **not** copy BootStrap to `%MYMERITAPP%\BootStrap\`. Pathway: [docs/bootstrap_pathway.md](docs/bootstrap_pathway.md). |
| **Usage (accounts, tiers, commerce)** | [docs/usage.md](docs/usage.md) |
| **Launch/deploy PoV** | [docs/deploy.md](docs/deploy.md) â€” one local `.merit_launch.md`, one `merit` command |
| **LLD map (audit)** | [docs/IAR/MERIT_AGENT_SKILLS_LLD_MAP.md](docs/IAR/MERIT_AGENT_SKILLS_LLD_MAP.md) |
| **Full freemium showcase** | [Mr-PI-Bala/merit-demo](https://github.com/Mr-PI-Bala/merit-demo) â€” workbench, journal, AMA, subs, legal |
| **Clean-clone proof** | [Mr-PI-Bala/merit-test](https://github.com/Mr-PI-Bala/merit-test) â€” independent consumer ID using the same hosted providers |
| **Try bundles (Angles 1â€“4)** | [docs/TRY_BUNDLES.md](docs/TRY_BUNDLES.md) |
| **Skills only** | Merit-Hub menu **I** or `pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1 -InstallSkills Cursor` (after **J**). Or from cloned repo: `.\install.ps1 -Target Cursor|ClaudeCode|Codex|VSCode|Hermes|OpenClaw|GrokBot|Devin` |
| **Mini upgrade (mmUpgrade)** | `/merit-mm-upgrade` or say **mmUpgrade** â€” gap analysis â†’ FR/AGENT_REQ (no vault) |
| **Affiliate / design partner** | [`skills/merit-affiliate`](skills/merit-affiliate/SKILL.md) â€” free attribution + portal recipes (no billing) |
| **Live alpha elevate** | `.\merit.ps1 livealpha --path <consumer>` then Cursor `/merit-livealpha â€¦` |

**Production MERIT base:** `https://merit-prod.vercel.app` for metered APIs, packages, and register paths. Portfolio consumers such as SoulOS, SomaTune, DIRT, M4FI, and AURAVYBE stay separate.

## Public vs private SSOT

| | Public (this repo + Portal) | Private (operators only) |
|--|----------------------------|--------------------------|
| **What** | Skills, `merit` CLI recipes, dinner/tutorial, freemium docs | Full platform **product law**, L1, env, cert registry |
| **Where** | **This README**, [docs/usage.md](docs/usage.md), [HowToLaunch-Over-Dinner-Tutorial.md](HowToLaunch-Over-Dinner-Tutorial.md), live [Portal](https://merit-prod.vercel.app/portal/) | Vault `docs/PRD_MERIT_AGENT_SKILLS_PLATFORM.md` (**ACCEPTED** technical SSOT â€” not published here) |
| **Who** | Builders, agents on OSS path | HumanBala / AgentDraven with vault |
| **Pin** | Clone **`skills-v*`** release tags (FR-SK-14 / L1 Â§E.0) | Not a substitute for product VERSION on consumers |

**Do not** expect a public copy of the vault PRD. Implementers with vault access apply FR tables from the private PRD + provider IAR; builders follow **usage + Portal** only.

**Same names, different jobs** (not vestigial; do not overwrite each other):

| File | What it is | What it is not |
|------|------------|----------------|
| This repo **`merit.ps1` / `merit.sh`** | Public OSS CLI (`create` / `apply` / `verify` / `portal` / consumer `closeout`) | Vault operator CLI |
| Vault **`scripts/merit.ps1`** | Operator CLI (`mXin`, `runtime`, `env`, hygiene) | Public create/deploy CLI |
| This repo **`BootStrap/MERIT.json`** | Repo template / pointer (edition `oss`) | Live laptop state (that is `%MYMERITAPP%\oss-bench.json`) |
| Vault **`BootStrap/MERIT.json`** | Vault BootStrap template (edition `vault`) | Public OSS registry |
| **`~/dev/MERIT.json`** | Live machine BootStrap state after first run | A committed repo file |

## Quick install

**Recommended cold start:** [download `Merit-Hub.ps1`](Merit-Hub/Merit-Hub.ps1) (**Raw**) to `C:\Tools\`. **Required — use the full command.** Do not double-click the file or run `.\Merit-Hub.ps1`. Windows (and other OS quarantine) treats an internet-downloaded script as a security risk and will block a plain run.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

`-ExecutionPolicy Bypass` is for **this process only**. Browser “harmful file” warnings are expected — **Keep**.

Menu **J** / **V** clones pinned OSS/vault for you — no full repo clone required first.

**Full repo install** (OSS bench = `%MYMERITAPP%`, default `C:\MyMeritApp`):

```powershell
mkdir C:\MyMeritApp
cd C:\MyMeritApp
git clone --branch skills-v0.5.2 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
# omit -Target to print usage (no default host)
# Do not run BootStrap as a second product. Use Merit-Hub (required full command):
# pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1
```

Linux/macOS:

```bash
mkdir -p ~/MyMeritApp
cd ~/MyMeritApp
git clone --branch skills-v0.5.2 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
./install.sh -Target Cursor
```

## Multi-runtime install (same `skills/` tree)

| Runtime | Status | Install |
|---------|--------|---------|
| **Cursor** | supported | `.\install.ps1 -Target Cursor` → `~/.cursor/skills` |
| **Claude Code** | supported | `.\install.ps1 -Target ClaudeCode` → `~/.claude/skills` (alias: `Claude`) |
| **Codex** | supported | `.\install.ps1 -Target Codex` → `~/.codex/skills` (or `$CODEX_HOME/skills`) |
| **VS Code / Open Agents** | supported | `.\install.ps1 -Target VSCode` → `~/.agents/skills` (alias: `Agents`) |
| **Hermes** | supported | `.\install.ps1 -Target Hermes` → `~/.hermes/skills` · or `hermes skills tap add AgentDraven/merit-agent-skills` |
| **OpenClaw** | supported | `.\install.ps1 -Target OpenClaw` → `~/.openclaw/skills` · or `openclaw skills install ./skills/<skill>` |
| **Grok Bot** | supported | `.\install.ps1 -Target GrokBot` → `~/.grok/skills` (alias: `Grok`) |
| **Devin** | supported | `.\install.ps1 -Target Devin` → `~/.devin/skills` + repo `AGENTS.md` in cloud sessions |
| **Project (Cursor)** | supported | `.\install.ps1 -Target Project -Path <repo>` → `<repo>/.cursor/skills` |
| **Paperclip** | research | — (suggest via email below) |

Registry source of truth: [`cfg/agent_hosts.json`](cfg/agent_hosts.json).

## Collaboration — suggest a host

MERIT aims to be the **one-stop** public path for builders on **any** AI IDE, agentic harness, or autonomous agent — not just the hosts above.

**Missing your stack?** Email **[meritlabs@protonmail.com](mailto:meritlabs@protonmail.com?subject=MERIT%20host%20suggestion)** with:

- Host / product name (e.g. your IDE, CLI agent, or cloud agent)
- Where skills or instructions are loaded from (path, env var, or doc link)
- Whether you want file-copy install (`install.ps1 -Target …`) or CLI-only integration

We add vetted hosts to [`cfg/agent_hosts.json`](cfg/agent_hosts.json) and promote `research` → `supported` when install wiring lands. Same instruction chain (L1 → L2 → L3) for every host — hosts mount skills; they do not fork product law.

**mmUpgrade** is public freeware (`merit-mm-upgrade`). Full **`merit-upgrade`** (IAR / hygiene / maturity / closeout) stays vault-only via `merit.ps1 runtime out` â€” not in this OSS tree.

## 3 Steps Over Dinner cheatsheet

Use this review order for human validation once code, docs, and E2E are complete:

1. **Start here:** [HowToLaunch-Over-Dinner-Tutorial.md](HowToLaunch-Over-Dinner-Tutorial.md)
   - Goal: confirm the zero-account, first-night story makes sense.
2. **Understand the commands:** [docs/usage.md](docs/usage.md)
   - Goal: verify clone, install, `init`, `apply`, `verify`, optional `e2e`, and optional `deploy`.
3. **Deploy PoV:** [docs/deploy.md](docs/deploy.md)
   - Goal: confirm `.merit_launch.md` is the one user-edited launch profile and generated files are explained.
4. **Demo proof:** [merit-demo usage](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/merit_demo_usage.md)
   - Goal: validate the hello-world consumer, screenshots, hosted provider links, and no local metered provider source.
5. **Clean-clone proof:** [merit-test usage](https://github.com/Mr-PI-Bala/merit-test/blob/main/merit-test%20docs/merit_test_usage.md)
   - Goal: confirm a second consumer identity uses the same hosted meritutils, meritsubs, and meritstore boundaries without inheriting `merit-demo` identity.
6. **Release/audit map:** [docs/IAR/MERIT_AGENT_SKILLS_LLD_MAP.md](docs/IAR/MERIT_AGENT_SKILLS_LLD_MAP.md)
   - Goal: confirm the public skills repo is standalone, skills-only, and aligned to MERIT Prod.

Optional confidence pass: run **E2E Testing Using Playwright** in both `merit-demo` and `merit-test` after `npm install`; screenshots prove the local routes and responsive flows, while provider checks prove the hosted MERIT boundary and independent consumer identities.

## One public CLI

```powershell
.\merit.ps1 init --path ..\my-app
# edit ..\my-app\.merit_launch.md
.\merit.ps1 apply --path ..\my-app
.\merit.ps1 verify --path ..\my-app
```

Optional BYOK publish/deploy:

```powershell
.\merit.ps1 deploy --path ..\my-app
.\merit.ps1 portal --path ..\my-app
```

Linux/macOS:

```bash
./merit.sh init --path ../my-app
# edit ../my-app/.merit_launch.md
./merit.sh apply --path ../my-app
./merit.sh verify --path ../my-app
```

Shell wrappers require `pwsh` or PowerShell.

Smokes: Windows `.\scripts\smoke-freemium.ps1`; Linux/macOS `./scripts/smoke-freemium.sh`.

## E2E Testing Using Playwright (optional)

The public quickstart does not require Node dependencies, but full visual validation does. In `merit-demo`, run:

```powershell
npm install
.\merit.ps1 e2e
```

Linux/macOS:

```bash
npm install
./merit.sh e2e
```

`npm install` installs the demoâ€™s declared Node dev tooling, including `@playwright/test`; the repo postinstall attempts to install the Chromium browser used for screenshots. The MERIT wrapper then runs the route/provider checks and writes screenshots under `merit-demo docs/evidence/`. If dependencies are not installed, `verify` can still pass, but screenshot capture is skipped.

## Skills

| Skill | Purpose |
|-------|---------|
| `merit-par-workbench` | DualRail Gloss play (`merit_ux` + Value Tour) + Advanced `merit_workbench` / `journal` |
| `merit-prd` | Bake `*prd.md` (marketing + FR matrix) before portal / `app_logic/` |
| `merit-applogic` | Implement Must FRs under `app_logic/` from PRD + portal (`/merit-applogic`) |
| `merit-portal` | here.now marketing (`portal/` only); multi-surface |
| `merit-subs` | meritsubs + meritstore funnel, freemium caps |
| `merit-ama` | AMA Q&A + leaderboard (merit-demo) |
| `merit-admin-gate` | MeritAdminGate phrase auth |
| `merit-deploy-vercel` | Scoped Vercel deploy (your team scope) |
| `merit-onboard` | OSS quickstart â†’ merit-demo |
| `meritcert`, `merit-closeout`, `merit-iar` | Vocabulary; vault operators run writes |

`merit.ps1 create` (v0.3.31+): **Cloud First** â€” live `merit-prod` `/apps/<app>/play`. Phase 7 jumpstart portal + PRD include Make Art, ecosystem providers, PAR packages, and consumer examples (CAST = Cloud-Assisted Autonomous Synth-Podcast Theatre, DIRT, SomaTune, M4FI, Tranquil Balance). Phase 8 publishes portal/ to here.now when credentials exist.

All OSS user docs use **`.\merit.ps1`** / **`./merit.sh`**. There are no public shim scripts.

## Freemium vs Plus

| | Free (OSS) | Plus |
|---|------------|------|
| PAR | `merit_workbench@0.4.x`, `journal@0.2.x` | `@1.0.x` commercial line (Phase 3 gate) |
| Journal | 2 entries/day | Uncapped |
| AMA | 2 ask/vote/response/day; top 25 | Uncapped |
| CLI | merit.ps1 / merit.sh | + vault merit.ps1 for operators |
| Commerce | â€” | meritstore + meritsubs on **your** `consumer_id` |

Plus: **$10.79/mo** ($2.49/wk round up); 20% off 6-month; 50% off annual.

### Guest â†’ paid funnel

Guest OSS PAR â†’ free register (meritstore) â†’ hit freemium cap â†’ **Plus** SKU â†’ meritsubs entitlements. See [docs/TRY_BUNDLES.md](docs/TRY_BUNDLES.md).

## Releases

| Policy | Detail |
|--------|--------|
| Pre-GA tags | `skills-v0.x.y` â€” minor bumps in this program |
| GA | `skills-v1.0.0` when **HumanBala** approves |
| Pin | Release tags, not floating `main` (L1 Â§E.0 / FR-SK-14) |
| Current tip (Portal pin) | **`skills-v0.5.2`** |
| Current human-validation baseline | **`skills-v0.3.22`** |

Phase 1 shipped skills-only (`skills-v0.1.0`). Freemium merit CLI is pre-GA until dogfood smokes green.

## Licensing (product fork)

Apache-2.0 adoption on skills; monetization via meritstore â€” not license royalties. See **`LICENSING.md`**, **`THIRD_PARTY_NOTICES.md`**.

## Sync from vault

Exported from `merit-private-vault/templates/skills/` at release time.
