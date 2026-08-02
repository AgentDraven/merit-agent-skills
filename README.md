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
| **Clean-clone proof** | [Mr-PI-Bala/merit-test](https://github.com/Mr-PI-Bala/merit-test) — independent consumer ID using the same hosted providers |
| **Try bundles (Angles 1–4)** | [docs/TRY_BUNDLES.md](docs/TRY_BUNDLES.md) |
| **Skills only** | Windows `.\install.ps1 -Target Cursor|ClaudeCode|Codex|VSCode`; Linux/macOS `./install.sh -Target …` (aliases: `Claude`, `Agents`) |
| **Mini upgrade (mmUpgrade)** | `/merit-mm-upgrade` or say **mmUpgrade** — gap analysis → FR/AGENT_REQ (no vault) |
| **Affiliate / design partner** | [`skills/merit-affiliate`](skills/merit-affiliate/SKILL.md) — free attribution + portal recipes (no billing) |
| **Live alpha elevate** | `.\merit.ps1 livealpha --path <consumer>` then Cursor `/merit-livealpha …` |

**Production MERIT base:** `https://merit-prod.vercel.app` for metered APIs, packages, and register paths. Portfolio consumers such as SoulOS, SomaTune, DIRT, M4FI, and AURAVYBE stay separate.

## Quick install

```powershell
git clone --branch skills-v0.3.19 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
# omit -Target to print usage (no default host)
```

Linux/macOS:

```bash
git clone --branch skills-v0.3.19 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
./install.sh -Target Cursor
```

## Multi-runtime install (same `skills/` tree)

| Runtime | Install |
|---------|---------|
| **Cursor** | `.\install.ps1 -Target Cursor` → `~/.cursor/skills` |
| **Claude Code** | `.\install.ps1 -Target ClaudeCode` → `~/.claude/skills` (alias: `Claude`) |
| **Codex** | `.\install.ps1 -Target Codex` → `~/.codex/skills` (or `$CODEX_HOME/skills`) |
| **VS Code / Agents** | `.\install.ps1 -Target VSCode` → `~/.agents/skills` (alias: `Agents`) |
| **Hermes** | `hermes skills tap add AgentDraven/merit-agent-skills` · or copy into `~/.hermes/skills` / scan `~/.agents/skills` |
| **OpenClaw** | `openclaw skills install ./skills/merit-mm-upgrade` · ClawHub publish if desired (license: Apache-2.0 here) |
| **Project (Cursor)** | `.\install.ps1 -Target Project -Path <repo>` → `<repo>/.cursor/skills` |

**mmUpgrade** is public freeware (`merit-mm-upgrade`). Full **`merit-upgrade`** (IAR / hygiene / maturity / closeout) stays vault-only via `merit.ps1 runtime out` — not in this OSS tree.

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

`npm install` installs the demo’s declared Node dev tooling, including `@playwright/test`; the repo postinstall attempts to install the Chromium browser used for screenshots. The MERIT wrapper then runs the route/provider checks and writes screenshots under `merit-demo docs/evidence/`. If dependencies are not installed, `verify` can still pass, but screenshot capture is skipped.

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
| Pin | Release tags, not floating `main` (L1 §E.0 / FR-SK-14) |
| Current human-validation baseline | **`skills-v0.3.19`** |

Phase 1 shipped skills-only (`skills-v0.1.0`). Freemium merit CLI is pre-GA until dogfood smokes green.

## Licensing (product fork)

Apache-2.0 adoption on skills; monetization via meritstore — not license royalties. See **`LICENSING.md`**, **`THIRD_PARTY_NOTICES.md`**.

## Sync from vault

Exported from `merit-private-vault/templates/skills/` at release time.
