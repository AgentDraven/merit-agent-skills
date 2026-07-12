# merit-agent-skills — usage

Public guide for the **OSS** path: `merit.ps1`, skills, and freemium try bundles.
Operator-only vault workflows are optional and not required for a first-time public user.

**Related:** [TRY_BUNDLES.md](TRY_BUNDLES.md) · [README](../README.md) · [LICENSING.md](../LICENSING.md) · canonical consumer [merit-demo usage](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/merit_demo_usage.md)

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
git clone --branch skills-v0.3.11 https://github.com/AgentDraven/merit-agent-skills.git
git clone https://github.com/Mr-PI-Bala/merit-demo.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
.\merit.ps1 verify --path ..\merit-demo
```

### 2. Initialize The Repository

Run `init`, edit only the mandatory section of `.merit_launch.md`, then run `apply`. `apply` creates `.env.local`, `cfg/flask_deploy.json`, and `cfg/portals.json`; Vercel still requires its own one-time `npx vercel link` before the first deploy.

```powershell
.\merit.ps1 init --path ..\merit-demo
# edit ..\merit-demo\.merit_launch.md
.\merit.ps1 apply --path ..\merit-demo
npx vercel link --scope <your-vercel-scope>
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

git clone --branch skills-v0.3.11 https://github.com/AgentDraven/merit-agent-skills.git
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

git clone --branch skills-v0.3.11 https://github.com/AgentDraven/merit-agent-skills.git
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
```

Linux/macOS equivalents use the shell wrapper:

```bash
./merit.sh init --path <dir>
./merit.sh apply --path <dir>
./merit.sh verify --path <dir>
./merit.sh deploy --path <dir>
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
