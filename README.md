# merit-agent-skills

Free **Cursor Agent Skills** and **`merit`** CLI for MERIT-shaped product repos.

## Start here

| Goal | Path |
|------|------|
| **Build over dinner (start here)** | **[HowToLaunch-Over-Dinner-Tutorial.md](HowToLaunch-Over-Dinner-Tutorial.md)** — 3 steps, no accounts night one |
| **Usage (accounts, tiers, commerce)** | [docs/usage.md](docs/usage.md) |
| **Launch/deploy PoV** | [docs/deploy.md](docs/deploy.md) — one local `.merit_launch.md`, one `merit` command |
| **LLD map (audit)** | [docs/IAR/MERIT_AGENT_SKILLS_LLD_MAP.md](docs/IAR/MERIT_AGENT_SKILLS_LLD_MAP.md) |
| **Full freemium showcase** | [Mr-PI-Bala/merit-demo](https://github.com/Mr-PI-Bala/merit-demo) — workbench, journal, AMA, subs, legal |
| **Try bundles (Angles 1–4)** | [docs/TRY_BUNDLES.md](docs/TRY_BUNDLES.md) |
| **Skills only** | Windows `.\install.ps1 -Target Cursor`; Linux/macOS `./install.sh -Target Cursor` |

**Production MERIT base:** `https://merit-prod.vercel.app` for metered APIs, packages, and register paths. Portfolio consumers such as SoulOS, SomaTune, DIRT, M4FI, and AURAVYBE stay separate.

## Quick install

```powershell
git clone --branch skills-v0.3.12 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
```

Linux/macOS:

```bash
git clone --branch skills-v0.3.12 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
./install.sh -Target Cursor
```

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

## Skills (10)

| Skill | Purpose |
|-------|---------|
| `merit-par-workbench` | PAR play shell (`merit_workbench@0.4.x`, `journal@0.2.x`) |
| `merit-portal` | here.now marketing (`portal/` only); multi-surface |
| `merit-subs` | meritsubs + meritstore funnel, freemium caps |
| `merit-ama` | AMA Q&A + leaderboard (merit-demo) |
| `merit-admin-gate` | MeritAdminGate phrase auth |
| `merit-deploy-vercel` | Scoped Vercel deploy (your team scope) |
| `merit-onboard` | OSS quickstart → merit-demo |
| `meritcert`, `merit-closeout`, `merit-iar` | Vocabulary; vault operators run writes |

All OSS user docs use **`.\merit.ps1`** / **`./merit.sh`**. There are no public shim scripts.

## Freemium vs Plus

| | Free (OSS) | Plus |
|---|------------|------|
| PAR | `merit_workbench@0.4.x`, `journal@0.2.x` | `@1.0.x` commercial line (Phase 3 gate) |
| Journal | 2 entries/day | Uncapped |
| AMA | 2 ask/vote/response/day; top 25 | Uncapped |
| CLI | merit.ps1 / merit.sh | + vault merit.ps1 for operators |
| Commerce | — | meritstore + meritsubs on **your** `consumer_id` |

Plus: **$10.79/mo** ($2.49/wk round up); 20% off 6-month; 50% off annual.

### Guest → paid funnel

Guest OSS PAR → free register (meritstore) → hit freemium cap → **Plus** SKU → meritsubs entitlements. See [docs/TRY_BUNDLES.md](docs/TRY_BUNDLES.md).

## Releases

| Policy | Detail |
|--------|--------|
| Pre-GA tags | `skills-v0.x.y` — minor bumps in this program |
| GA | `skills-v1.0.0` when **HumanBala** approves |
| Pin | Release tags, not floating `main` |
| Current | **`skills-v0.3.12`** · merit **0.3.12** |

Phase 1 shipped skills-only (`skills-v0.1.0`). Freemium merit CLI is pre-GA until dogfood smokes green.

## Licensing (product fork)

Apache-2.0 adoption on skills; monetization via meritstore — not license royalties. See **`LICENSING.md`**, **`THIRD_PARTY_NOTICES.md`**.

## Sync from vault

Exported from `merit-private-vault/templates/skills/` at release time.
