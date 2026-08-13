# merit-agent-skills — usage

Public guide for the **OSS** path: `merit.ps1`, skills, and freemium try bundles.
Operator-only vault workflows are optional and not required for a first-time public user.

**Related:** [TRY_BUNDLES.md](TRY_BUNDLES.md) · [README](../README.md) · [LICENSING.md](../LICENSING.md) · canonical consumer [merit-demo usage](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/merit_demo_usage.md)

### Public vs private product law

- **Public (this file + README + production Portal):** how to install, create, verify, deploy, and use free vs paid *hosted* services.
- **Private (merit-private-vault only):** full platform PRD (`PRD_MERIT_AGENT_SKILLS_PLATFORM.md`, ACCEPTED for technical implement 2026-08-09). Not shipped in this OSS tree; operators with vault access implement FR-SK / commerce / PAR against that SSOT.

## Document map

| Section | Topic |
|---------|--------|
| [What is free without any account](#what-is-free-without-any-account) | Clone, scaffold, local PAR |
| [Accounts — what needs one and when](#accounts--what-needs-one-and-when) | GitHub, Vercel, here.now, Supabase, commerce |
| [Platform vs BYOK](#platform-vs-byok-what-merit-hosts-for-you) | PAR CDN, meritstore, meritsubs, data plane |
| [Validation tiers](#validation-tiers) | Tier 1–4 on a clean machine |
| [Commerce and payouts](#commerce-and-payouts-guest--creator--subscriber) | Who pays whom, KYC, Square |
| [Attribution](#attribution-for-later-paid-conversion) | Optional consumer id, affiliate, promo |
| [merit commands](#merit-commands) | CLI reference |
| [Launch profile](deploy.md) | One local `.merit_launch.md` PoV for Vercel, here.now, and secrets |
| [FAQ](#faq) | Common misconceptions |

---

## 3 Steps Over Dinner

### 1. Local Setup

Create an empty directory, clone the pinned skills release, clone `merit-demo`, install the skills, and verify the baseline:

```powershell
mkdir C:\MeritOverDinner
cd C:\MeritOverDinner
git clone --branch skills-v0.3.50 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
```

### 2. AutoMagic create (preferred)

```powershell
.\merit.ps1 create --path ..\my-app --profile fullstack-consumer --vercel-scope <your-team>
# optional CI / local shell only:
.\merit.ps1 create --path ..\my-app --profile fullstack-consumer --vercel-scope <your-team> --scaffold-only
```

Phases print as `CREATE phase N/9`. On failure the CLI stops with recovery tips.

### 2b. Initialize manually (optional redo)

Run `init`, edit only the mandatory section of `.merit_launch.md`, then run `apply`. `apply` creates `.env.local`, `cfg/flask_deploy.json`, and `cfg/portals.json`; `merit deploy` auto-links Vercel when `.vercel/project.json` is missing.

```powershell
.\merit.ps1 init --path ..\merit-demo
# edit ..\merit-demo\.merit_launch.md
.\merit.ps1 apply --path ..\merit-demo
.\merit.ps1 deploy --path ..\merit-demo
```

### 3. Add Marketing Front-End & Save

Edit the consumer-owned `portal/` folder, publish it when ready, then save the repo with normal Git. Vault operators may add `merit-closeout`; public users do not need vault closeout.

```powershell
# edit ..\merit-demo\portal\
.\merit.ps1 portal --path ..\merit-demo
git -C ..\merit-demo add .
git -C ..\merit-demo commit -m "launch: update Portal"
git -C ..\merit-demo push
```

---

## What is free without any account

You can validate MERIT freemium **without** GitHub login, Vercel, here.now, or Supabase:

| Action | Accounts needed |
|--------|-----------------|
| `git clone` public `merit-agent-skills` or `merit-demo` | **None** (anonymous HTTPS read) |
| `merit apply` + `verify` | **None** |
| Open `play/index.html` locally (static PAR from CDN) | **None** |
| `scripts/smoke-freemium.ps1` / `scripts/smoke-freemium.sh` | **None** |
| `merit-demo`: `npm install`, `npm run verify`, `npm run e2e` (PAR CDN HEAD) | **None** (network only) |

**GitHub account is optional** for Tier-2. Use it only when you **fork**, **push** your own remote, open PRs, or use `gh` against private repos. Cloning and working locally does not require signing in.

## When skills are downloaded and installed

There are two separate actions:

| Action | When | Command |
|--------|------|---------|
| Clone/download repo | Always first, because it brings down the skills, docs, templates, and `merit.ps1` / `merit.sh` CLI | `git clone --branch skills-v0.3.50 https://github.com/AgentDraven/merit-agent-skills.git` |
| Install skills into an AI IDE host | Optional, only when you want the host to see skill instructions as installed skills | Windows `.\install.ps1 -Target Cursor|ClaudeCode|Codex|VSCode`; Linux/macOS `./install.sh -Target …` (aliases: `Claude`, `Agents`; `Project` needs `-Path`) |

You can run `merit.ps1` / `merit.sh` directly from the cloned repo without installing skills. Install is for agent authoring convenience, not for runtime deployment.

---

## E2E Testing Using Playwright (optional)

Run this against both public proof consumers:

- `merit-demo` is the canonical Hello World showcase.
- `merit-test` is the independent clean-clone proof and must report consumer ID `merit-test`.

The dinner-path baseline only needs `merit verify`. Full screenshot validation is optional and requires Node dependencies in the consumer repo:

```powershell
cd ..\merit-demo
npm install
.\merit.ps1 e2e
```

Linux/macOS:

```bash
cd ../merit-demo
npm install
./merit.sh e2e
```

What gets installed: `npm install` reads `merit-demo/package.json` and installs the declared dev tooling, including `@playwright/test`; the repo postinstall attempts to install the Chromium browser used for screenshots. The E2E wrapper checks local demo routes, hosted provider links, metered-source boundaries, and responsive screenshots under `merit-demo docs/evidence/`.

If `npm install` has not been run, the MERIT wrapper still performs non-visual checks and reports that Playwright screenshots were skipped. That is acceptable for a lightweight first pass, but not for launch proof.

---

## Accounts — what needs one and when

| Service | Required for | Tier / angle | Who creates it |
|---------|--------------|--------------|----------------|
| **Git** (CLI) | Clone, local commits | Tier 2+ | Install only — no cloud account |
| **GitHub** | Fork, push, PRs | Optional until you publish source | You |
| **MERIT package route** (`merit-prod.vercel.app/pkg/meritutils`) | Free workbench/journal widgets | Angle 1 — always public | **Nobody** — MERIT provider CDN behind gateway |
| **Vercel** | Live app at `*.vercel.app` | Tier 4 / deploy | You (BYOK) |
| **here.now** | Marketing at `{slug}.here.now` | Angle 2 / portal publish | You (BYOK `HERENOW_API_KEY`) |
| **Supabase** | Persistent journal/AMA + meritsubs data on **your** deploy | Full merit-demo deploy | You (consumer project) |
| **meritstore tenant** | Checkout under **your** `consumer_id` | Angle 4 — operator provision | MERIT platform (after integration cert) |
| **Square** (or tenant payment provider) | **Payout** from Plus subscriptions to you | After meritstore tenant + onboarding | You via platform tenant config |

You do **not** need all three of here.now, Vercel, and Supabase to **start** Tier-2. They unlock different surfaces:

```text
Tier 2 local only     →  git clone + merit + verify       (0 cloud accounts)
Angle 1 play          →  PAR CDN only                     (0 cloud accounts)
Angle 2 marketing     →  + here.now                       (1 account)
Live consumer app     →  + Vercel                         (1 account)
Full merit-demo stack →  + Vercel + Supabase              (2 accounts)
Paid commerce         →  + meritstore tenant + payment    (platform onboarding)
```

---

## Platform vs BYOK — what MERIT hosts for you

| Layer | Hosted by MERIT (freemium) | You bring (BYOK) |
|-------|---------------------------|------------------|
| **Skill templates + merit CLI** | Public GitHub OSS | — |
| **PAR packages** `@0.4.x` / `@0.2.x` | `merit-prod.vercel.app/pkg/meritutils` | — |
| **MERIT registration UI** | `merit-prod.vercel.app/store/{consumer_id}/register` for **provisioned** tenants | Your `consumer_id` must be provisioned (not automatic on clone) |
| **Checkout / Square** | Platform meritstore runs payment UI | Per-tenant payment provider + payout onboarding |
| **meritsubs / usage API** | Hosted MERIT authority for usage, credits, and entitlements | Your app calls the hosted provider; do not fork billing logic |
| **Journal / AMA / subscriber DB** | **Not** a shared MERIT Supabase for your app | **Your** Supabase project (consumer-scoped data plane) |
| **Marketing portal** | — | here.now + your `portal/` content |

### What “the utils hide” actually means

**Correct:** Free PAR widgets (`merit_workbench`, `journal`) load from the public CDN. A vanilla clone can render `/play/` without you operating a package registry.

**Not correct:** Supabase and Square are **not** silently replaced by a MERIT backend for your product’s data and payouts.

- **Supabase** stores **your** consumer’s journal entries, AMA activity, and meritsubs subscriber rows when you deploy. merit-demo’s SQL migrations run on **your** project.
- **Square** runs on **meritstore** for subscriber checkout. Revenue attribution to **you** requires a provisioned meritstore tenant and linked payment provider — not merely cloning OSS.

For **local-only** try bundles, journal/AMA may render static UI, but metered utility calls use production MERIT provider mounts. Public clones must not ship local usage-metering stubs.

---

## Validation tiers

Aligned with vault `docs/vault_usage.md` § merit-agent-skills validation.

| Tier | Goal | GitHub login? | Typical accounts |
|------|------|---------------|------------------|
| **1** | `smoke-freemium.ps1` in temp dir | No | None |
| **2** | Isolated folder: clone @ tag + scaffold or merit-demo verify/e2e | **No** | None for local; optional deploy accounts later |
| **3** | Vault `skills verify` (operators only) | N/A | Vault access |
| **4** | Production host + optional portals | Only if pushing your fork | Vercel ± here.now ± Supabase |

### Tier 2 — vanilla start (recommended)

```powershell
mkdir C:\MeritValidate
cd C:\MeritValidate

git clone --branch skills-v0.3.50 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills

mkdir ..\my-app
.\merit.ps1 init --path ..\my-app
# edit ..\my-app\.merit_launch.md
.\merit.ps1 apply --path ..\my-app
.\merit.ps1 verify --path ..\my-app
```

Linux/macOS:

```bash
mkdir -p ~/MeritValidate
cd ~/MeritValidate

git clone --branch skills-v0.3.50 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills

mkdir -p ../my-app
./merit.sh init --path ../my-app
# edit ../my-app/.merit_launch.md
./merit.sh apply --path ../my-app
./merit.sh verify --path ../my-app
```

Optional canonical consumer (still no GitHub login):

```powershell
cd C:\MeritValidate
git clone https://github.com/Mr-PI-Bala/merit-demo.git
cd merit-demo
npm install
npm run verify
npm run e2e
```

Avoid on Tier 2: private operator runtimes, vault `merit.ps1 env out`, or Vercel scopes you do not own.

---

## Commerce and payouts (guest → creator → subscriber)

### Attribution for later paid conversion

Optional non-secret cfg: copy [`cfg/consumer_attribution.json.template`](../cfg/consumer_attribution.json.template) into your consumer as `cfg/consumer_attribution.json`.

| Field | Role |
|-------|------|
| `consumer_id` | Stable consumer / tenant id |
| `affiliate_code` | Checkout attribution on **meritstore** register URLs |
| `default_promocode` | Usually `MERITAGENT` (platform-enforced) |
| `partner_kind` | Marketing hint only (`affiliate` \| `design_partner`) — cohort is granted on **meritsubs** |

Register URL shape (gateway → meritstore for a provisioned app):

```text
https://merit-prod.vercel.app/store/{consumer_id}/register?affiliate={affiliate_code}&utm_source=…&utm_medium=…&utm_campaign=…
```

Skill: [`skills/merit-affiliate`](../skills/merit-affiliate/SKILL.md) · Portal recipe: [`docs/recipes/affiliate-portal.md`](recipes/affiliate-portal.md).

**Ecosystem overview (for humans):** [merit-prod.vercel.app/portal/partners.html](https://merit-prod.vercel.app/portal/partners.html) — join is mailto / operator invite; attribution uses the gateway register URL above.

**Do not confuse:** `affiliate_code` (attribution) ≠ meritsubs `partner_kinds` (cohort) ≠ runtime `MERIT_AFFILIATE` (operator folder).

Three roles — do not conflate them:

| Role | Who | Pays / earns |
|------|-----|--------------|
| **Guest** | Visitor on `/play/`, `/journal/`, `/ama/` | Nothing — freemium caps |
| **End subscriber** | Registers via meritstore, buys Plus | Pays platform checkout (Square on meritstore) |
| **Creator (you)** | Owns `consumer_id` + consumer host | Earns after tenant provision + payment provider onboarding |

### Funnel (provisioned consumer)

1. **Guest** — OSS PAR loads from CDN; daily caps (`cfg/freemium_limits.json`).
2. **Free register** — `merit-prod.vercel.app/store/{consumer_id}/register` (platform-hosted UI for that tenant).
3. **Cap hit** — UI prompts Plus upgrade.
4. **Paid** — hosted meritstore checkout → hosted usage/entitlement update → uncapped features (+ commercial PAR line in Phase 3).

### Money and KYC

- **Cloning OSS does not open a payout account.** Apache-2.0 skills are free; revenue is a **platform commerce** concern.
- **Plus payments** are collected through **meritstore** (Square in production today). Platform fee and tenant payout rules are per `consumer_id` (see product PRD FR-COM-09/10 in vault).
- **Intro usage** defaults to promo `MERITAGENT`; the hosted provider controls the credit amount, currently $25 by default.
- **Your share** flows to the **tenant payment provider** configured for your meritstore tenant — after MERIT provisions the tenant (integration cert minimum) and you complete payment-provider onboarding (KYC as required by Square or successor).
- Until that onboarding: subscribers may still pay on **existing provisioned demos** (e.g. `merit-demo`, `auravybe`); a **new** cloner does not automatically receive those funds.

**Angle 4 (operator)** — not self-service in pre-GA `skills-v0.3.x`:

```text
Fork merit-demo pattern → MERIT assigns consumer_id → integration cert → meritstore tenant → payment provider link
```

See `cfg/meritstore_tenant.json` (`status: pending_platform_provision`) on merit-demo.

---

## merit commands

```powershell
.\merit.ps1 init --path <dir>
.\merit.ps1 apply --path <dir>
.\merit.ps1 verify --path <dir>
.\merit.ps1 deploy --path <dir>
.\merit.ps1 portal --path <dir>
.\merit.ps1 all --path <dir>
.\merit.ps1 closeout --path <dir>
.\merit.ps1 apps publish --path <dir>
.\merit.ps1 apps refresh --path <dir>
.\merit.ps1 apps remove --path <dir> --yes [--tenant-all] [--with-portal]
.\merit.ps1 apps remove --consumer-id <id> --yes [--tenant-all]
```

### Refresh rails without touching `app_logic/` (`apps refresh`)

When the platform catalog, UserGuide, or play shell move, do **not** delete+create (that would risk `app_logic/`). From **skills-v0.3.50+**:

```powershell
.\merit.ps1 apps refresh --path ..\<app>
```

What it does:

1. Re-activates the free-community store catalog (`POST …/tenants/<id>/activate`).
2. Writes missing baseline community cfg only.
3. Syncs `docs/UserGuide.md` when the `MERIT_SCAFFOLD:user-guide` marker is present (skip with `docs/.merit-userguide-keep`).
4. Publishes `play/` + `cfg/` to merit-prod.
5. **Never** reads or writes `app_logic/`.

### Leave platform and start over (`apps remove`)

Public Portal SSOT (subscribe-dogfood):  
https://merit-prod.vercel.app/portal/developers/troubleshooting/#start-over

```powershell
.\merit.ps1 apps remove --path ..\<app> --yes --tenant-all --with-portal
Remove-Item -Recurse -Force ..\<app>
.\merit.ps1 create --path ..\<app> --profile fullstack-consumer
```

**`--with-portal` and here.now 404:** `cfg/portals.json` often lists several surfaces (`main`, `journal`, `ama`, `subs`). Create may publish only the main marketing site (sometimes a random live slug from `portal/.herenow/state.json`, e.g. `mindful-…`). Secondary slugs (`<app>-journal`, …) may never have been published. DELETE then returns **404 Not Found**. Treat that as **already gone** — if you already saw `apps remove OK` for the gateway, platform leave succeeded; continue delete folder + create. From **skills-v0.3.44+** the CLI treats 404 as OK and does not abort the rest of the leave.

| Message | Meaning | Next step |
|---------|---------|-----------|
| `apps remove OK: consumer_id=…` | merit-prod `/apps/<id>` (and optional tenant rows) cleared | Proceed with folder delete + create |
| `here.now deleted: https://…` | That marketing slug was removed | None |
| `here.now: … already gone (404) - OK` | slug never existed or was already deleted | Ignore; continue start-over |
| `here.now delete failed …` (auth / 5xx) | Credentials or here.now outage on a **live** slug | Fix `HERENOW_API_KEY` / `~/.herenow/credentials`, re-run `--with-portal` or delete leftover sites in the here.now console; platform leave still OK if `apps remove OK` printed |
| `Unexpected token 'Removing'` / `'/' operator` on any verb including `create` | Double-quoted strings in `merit.ps1` with `($Gateway/api/…)` or `(… or …)` parse as subexpressions on Windows PowerShell 5.1 — whole file fails to load (fixed **skills-v0.3.45+**) | `git fetch --tags; git checkout skills-v0.3.45` then re-run. Not your app path |

---

Linux/macOS equivalents use the shell wrapper:

```bash
./merit.sh init --path <dir>
./merit.sh apply --path <dir>
./merit.sh verify --path <dir>
./merit.sh deploy --path <dir>
./merit.sh closeout --path <dir>
```

Install skills to Cursor: Windows `.\install.ps1 -Target Cursor`; Linux/macOS `./install.sh -Target Cursor`.

Smokes: Windows `.\scripts\smoke-freemium.ps1`; Linux/macOS `./scripts/smoke-freemium.sh`.

---

## FAQ

**Do I need a GitHub account for Tier 2?**  
No. `git clone` of public repos works without login. Add GitHub when you fork or push.

**Do I need here.now, Vercel, and Supabase together?**  
No. They are independent unlocks: local PAR (none), marketing (here.now), live app (Vercel), persistent app DB (Supabase on your deploy).

**Does MERIT run Supabase and Square for me in the background?**  
PAR CDN and meritstore **registration/checkout UI** are platform-hosted for provisioned tenants. **Your app database** is your Supabase. **Your payouts** require tenant provision and payment-provider onboarding — not included in a vanilla clone.

**Can I collect Plus revenue right after clone?**  
No. You need a provisioned `consumer_id`, production MERIT metered-provider mounts, and meritstore tenant payment config. Until then, use live demos (e.g. merit-demo) to see the subscriber path.

**Where is the full deploy checklist?**  
[merit-demo OPERATOR_PROVISION.md](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/OPERATOR_PROVISION.md)

**Operator validation?**
MERIT vault operators run private validation separately. Public users should start with `.\scripts\smoke-freemium.ps1` on Windows or `./scripts/smoke-freemium.sh` on Linux/macOS.

