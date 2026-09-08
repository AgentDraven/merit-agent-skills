# Use MERIT in plain English 🧭

This guide explains what the free tools do, when an account is actually needed, and what to do after the Hub opens your first demo. You do not need private operator tools for a first-time public experience.

**Related:** [Choose a try path](TRY_BUNDLES.md) · [Start here](../README.md) · [Licensing](../LICENSING.md) · [merit-demo walkthrough](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/merit_demo_usage.md)

## Document map

| Section | Topic |
|---------|--------|
| [What is free without any account](#what-is-free-without-any-account) | Hub setup, local demo, and checks |
| [Accounts — what needs one and when](#accounts--what-needs-one-and-when) | GitHub, Vercel, here.now, Supabase, commerce |
| [Platform vs BYOK](#platform-vs-byok-what-merit-hosts-for-you) | PAR CDN, meritstore, meritsubs, data plane |
| [Ways to check your work](#ways-to-check-your-work) | From a quick laptop check to a live site |
| [Commerce and payouts](#commerce-and-payouts-guest--creator--subscriber) | Who pays whom, KYC, Square |
| [Attribution](#attribution-for-later-paid-conversion) | Optional consumer id, affiliate, promo |
| [merit commands](#merit-commands) | CLI reference |
| [Launch profile](deploy.md) | One local `.merit_launch.md` PoV for Vercel, here.now, and secrets |
| [FAQ](#faq) | Common misconceptions |

---

## Your first three steps

### 1. Let the Hub prepare your laptop

Run the Hub and choose **Set up this laptop (1)**, **Get the free MERIT tools (2)**, then **Try it (3)**. It prepares folders, downloads `merit-demo`, and opens the local experience. No release tag or Git command is needed:

```powershell
cd C:\Tools
.\Merit-Hub.ps1
# Choose: Set up this laptop, Get the free MERIT tools, then Try it
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
| The Hub downloads the free tools and then opens the demo | **None** |
| `merit apply` + `verify` | **None** |
| Open `play/index.html` locally (static PAR from CDN) | **None** |
| Optional automatic check (`scripts/smoke-freemium.ps1` / `.sh`) | **None** — ignore an optional community-file note; do **not** create a here.now account |
| `merit-demo`: `npm install`, `npm run verify`, `npm run e2e` (PAR CDN HEAD) | **None** (network only) |

**A GitHub account is optional.** You need one only to save your own copy online, send a pull request, or work with a private repository. The normal local Hub path works without signing in.

## When skills are downloaded and installed

There are two separate actions:

| Action | When | Command |
|--------|------|---------|
| Download the free tools | Choose **Get the free MERIT tools (2)** after setup | The Hub chooses the tested-together version automatically; no Git command or tag choice |
| Add helpful skills to an AI editor | Optional, only when you want your editor to see the MERIT helpers | Choose **Install skills in my AI editor (I)** or use the named command for your editor |

After **Get the free MERIT tools (2)**, run `merit.ps1` / `merit.sh` from the downloaded tools folder when the Hub or a guide asks for a named check. Adding skills to an editor is optional help for writing; it does not run or publish your app.

---

## Optional picture-check lab 📸

You can finish the beginner journey without installing Node or running `npm`. The Hub and `merit verify` already perform the useful no-account checks.

The main example is `merit-demo`. A separate `merit-test` example is used by maintainers for extra service checks.

Choose this extra lab only when you want screenshots of every page. `npm install` downloads the small testing tools listed by the demo; it does **not** install MERIT, change your app, or create an account:

```powershell
cd ..\merit-demo
npm install
npm run e2e:playwright
```

Linux/macOS:

```bash
cd ../merit-demo
npm install
npm run e2e:playwright
```

What happens: the package manager reads `package.json`, downloads the declared Playwright test tool, and the picture-check command opens a temporary local browser. It checks the same routes a visitor sees and saves pictures under `merit-demo docs/evidence/`.

If `npm install` fails or you skip it, nothing is broken. Run `merit verify` (or the Hub’s **Validate my local demo (3V)**) for the normal proof. Screenshots are a bonus, not a requirement for trying MERIT.

---

## Accounts — what needs one and when

| Service | What it is for | When you need it | Who creates it |
|---------|--------------|--------------|----------------|
| **Git** (CLI) | Saving versions on your laptop | Only if you choose to use source-control commands | Install only — no cloud account |
| **GitHub** | Fork, push, PRs | Optional until you publish source | You |
| **MERIT package route** (`merit-prod.vercel.app/pkg/meritutils`) | Free workbench and journal widgets | Always available for the local demo | **Nobody** — MERIT provides it |
| **Vercel** | Your own live app at `*.vercel.app` | Only when you choose to run your own live site | You |
| **here.now** | **Your** marketing site at `{slug}.here.now` | Only when you choose your own marketing host | You. **OC does not need a here.now account:** **OSS in Cloud (OC)** publishes your marketing page on MERIT hosting and prints its link. |
| **Supabase** | Persistent journal/AMA + meritsubs data on **your** deploy | Full merit-demo deploy | You (consumer project) |
| **meritstore tenant** | Checkout under **your** `consumer_id` | Later, when you sell through MERIT | MERIT platform after onboarding |
| **Square** (or tenant payment provider) | **Payout** from Plus subscriptions to you | After meritstore tenant + onboarding | You via platform tenant config |

You do **not** need here.now, Vercel, or Supabase to begin. They unlock different things later:

```text
Local demo            →  Hub setup → tools → demo         (0 cloud accounts)
Free hosted showcase  →  OSS in Cloud (OC)                (0 cloud accounts)
Your marketing site   →  + here.now                       (1 account)
Your live app         →  + Vercel                         (1 account)
Live journal or AMA   →  + Vercel + Supabase              (2 accounts)
Paid checkout         →  + meritstore onboarding + payment (later)
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

## Ways to check your work

Start with the simplest check that matches what you are doing.

| Check | Goal | GitHub login? | Typical accounts |
|------|------|---------------|------------------|
| **Quick** | Optional automatic check in a temporary folder | No | None |
| **Local** | Hub-installed tools: build or check `merit-demo` | **No** | None; optional hosting later |
| **Private operator** | Private operator checks | N/A | Private access |
| **Live site** | Your production host and optional pages | Only if you save your own source online | Vercel, here.now, or Supabase as needed |

### Local start (recommended)

```powershell
# First choose Set up this laptop (1) and Get the free MERIT tools (2).
cd $env:MYMERITAPP\merit-agent-skills

mkdir ..\my-app -Force
.\merit.ps1 init --path ..\my-app
# edit ..\my-app\.merit_launch.md
.\merit.ps1 apply --path ..\my-app
.\merit.ps1 verify --path ..\my-app
```

Linux/macOS:

```bash
# First choose Set up this laptop (1) and Get the free MERIT tools (2).
cd "$MYMERITAPP/merit-agent-skills"

mkdir -p ../my-app
./merit.sh init --path ../my-app
# edit ../my-app/.merit_launch.md
./merit.sh apply --path ../my-app
./merit.sh verify --path ../my-app
```

Optional example app (still no GitHub login):

```powershell
# First choose Try it (3); it downloads the example demo.
cd $env:MYMERITAPP\merit-demo
npm install
npm run verify
npm run e2e
```

For this local path, skip private operator tools and hosting settings you do not own.

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

Skill: [`skills/merit-referral`](../skills/merit-referral/SKILL.md) · Portal recipe: [`docs/recipes/referral-portal.md`](recipes/referral-portal.md).

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

**Selling through your own MERIT checkout** is a later, assisted path:

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

When the platform catalog, UserGuide, or play shell move, do **not** delete+create (that would risk `app_logic/`). With the current Hub-installed release:

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

Install skills to Cursor: Windows `.\merit.ps1 skills install --target Cursor`; Linux/macOS `./merit.sh skills install --target Cursor`.

Smokes: Windows `.\scripts\smoke-freemium.ps1`; Linux/macOS `./scripts/smoke-freemium.sh`.

---

## FAQ

### 🌟 The easy, hosted path

**Can I get my own MERIT app without becoming a cloud administrator?**
Yes. Run the Hub, open the demo, and choose **OSS in Cloud (OC)**. MERIT gives your app a `consumer_id`, publishes the play page and creator-facing pages on `merit-prod.vercel.app`, and prints the three links. You can share those links without opening a Vercel project or managing a server.

**What does “my own app” mean here?**
Your app has its own name, words, settings, and `consumer_id`. MERIT hosts the shared building blocks and keeps each consumer’s routes and registration link separate. You are customizing your own front door, not copying somebody else’s identity.

**Does MERIT quietly set up Vercel, Supabase, Square, or here.now accounts for me?**
No extra account is required for the normal hosted path. MERIT operates the shared hosting, package delivery, registration, and usage rails behind the scenes. The Hub never asks a beginner for a Vercel token, a Supabase project, a Square account, or a here.now key just to try or share the hosted showcase.

**Can I stay on MERIT hosting forever?**
Yes—this is the recommended path for creators, affiliates, and subscribers who want a simple managed experience. Keep using the MERIT-hosted consumer URL while MERIT manages the common platform pieces. Move to your own providers only when you have a specific reason, such as owning infrastructure, custom data storage, or a separate deployment policy.

**How does the free-to-paid journey work?**
Visitors start in the free guest experience, can register through the MERIT-hosted page, and see clear limits when they reach a free-use cap. If you enable a paid offering, MERIT’s hosted checkout and entitlement rails handle the platform flow for your provisioned consumer. Any platform fee, creator share, and payout terms are shown during onboarding; cloning the public demo alone does not create a payout account.

**Why would I ever choose Vercel, Supabase, Square, or here.now?**
Those are advanced “bring your own service” choices, not homework for a beginner. Choose them only when you want your own live infrastructure, your own application database, your own payment-provider relationship, or your own marketing host. The hosted OC path remains available for learning and sharing.

**What is the difference between OC and OCV?**
**OC** publishes your free OSS showcase. **OCV** is the guided tour afterward: it opens the hosted play, registration, and marketing pages one at a time and tells you what each page should show. If OC has not succeeded, finish the local check first and rerun OC.

**Do I need a GitHub account for a local demo?**
No. Hub downloads the public tools and demo without login. Add GitHub only when you decide to fork or push your own remote.

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
# Hosted OC tutorial boundary

The planned `OC-Tutorial.ps1` is a reusable skills/Hub workflow for validating
an already-published OC receipt. It should open hosted play, registration, and
marketing URLs, explain each result, and write evidence. It must not embed a
consumer's branding or replace the consumer application.

Implementation decision: the orchestration belongs in `merit-agent-skills`
(reusable skill + Hub adapter); `merit-demo` may provide the optional branded
launchpad page and content cards. This keeps the validation logic reusable while
letting each consumer explain its own features.
