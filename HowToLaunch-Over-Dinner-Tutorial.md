# HowToLaunch-Over-Dinner-Tutorial

**Introductory tutorial for new Content Creators**  
**Tagline:** Build your app over dinner; let MERIT publicize and promote you overnight.

| | |
|---|---|
| **Audience** | Non-technical creators â€” no prior MERIT, GitHub, or cloud setup |
| **You need tonight** | A laptop, internet, this repo + [merit-demo](https://github.com/Mr-PI-Bala/merit-demo) |
| **You do not need tonight** | GitHub login, Vercel, Supabase, Square, here.now |
| **Advanced docs** | [docs/usage.md](docs/usage.md) Â· [merit-demo OPERATOR_PROVISION](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/OPERATOR_PROVISION.md) |

---

## Introduction

MERIT gives you a **ready-made app** (Journal, AMA, subscriber pages) plus **free tools** in this repo. You personalize in one evening. MERITâ€™s discovery platform finds your audience overnight.

This document is the **only** guide you need for night one. Technical permutations are in the [Advanced section](#advanced-optional) at the end.

### The idea in three steps

| Step | What you do | Accounts |
|------|-------------|----------|
| **1** | Download **merit-agent-skills** (this repo) and **merit-demo** (app shell) | None |
| **2** | Personalize name, story, and Topics of Interest; preview on your laptop | None |
| **3** | Register as Content Creator; submit one ToI pack; pick Journal or AMA for free overnight promotion | Free email signup |

---

## Step 1 â€” Download the toolkit and the app

Use any folder (example: `C:\MyMeritApp`). You are **not** connecting this laptop to any existing MERIT operator setup.

### 1A â€” merit-agent-skills

Tools, `merit` CLI, and optional Cursor agent skills.

```powershell
mkdir C:\MyMeritApp
cd C:\MyMeritApp
git clone --branch skills-v0.3.54 https://github.com/AgentDraven/merit-agent-skills.git
```

Linux/macOS:

```bash
mkdir -p ~/MyMeritApp
cd ~/MyMeritApp
git clone --branch skills-v0.3.54 https://github.com/AgentDraven/merit-agent-skills.git
```

### 1B â€” merit-demo

Pre-scaffolded application: Journal, AMA, portal pages, legal templates, subscriber funnel cfg.

```powershell
cd C:\MyMeritApp
git clone https://github.com/Mr-PI-Bala/merit-demo.git
```

### GitHub account?

**Not required.** Public `git clone` works without logging in. You only need a GitHub account later if you **fork** or **push** your own copy.

### Optional â€” AI IDE skills

Install into your host (`Cursor`, `ClaudeCode`, `Codex`, or `VSCode`; aliases `Claude` / `Agents`):

```powershell
cd C:\MyMeritApp\merit-agent-skills
.\install.ps1 -Target Cursor
# also: -Target ClaudeCode | Codex | VSCode
```

Linux/macOS:

```bash
cd ~/MyMeritApp/merit-agent-skills
./install.sh -Target Cursor
# also: -Target ClaudeCode | Codex | VSCode
```

Open the `merit-demo` folder in your AI IDE and ask it to help edit branding or portal text.

**Step 1 complete.** Two folders on disk. No cloud accounts.

---

## Step 2 â€” Make it yours over dinner

Customize what visitors will see. You are **not** putting the app on the internet yet.

### 2A â€” Product name

File: `merit-demo\cfg\branding.json`  
Change `"product_name"`:

```json
"product_name": "Sunset Reflections"
```

### 2B â€” Welcome story

Folder: `merit-demo\portal\`  
Edit `index.html` (and optionally `portal/journal/`, `portal/ama/`) with your headline and one short paragraph.

If you use Cursor:

> Update my main portal page for a journal about mindful parenting. Keep the MERIT layout.

### 2C â€” Topics of Interest (ToI)

Create `merit-demo\MyTopics.txt` â€” one topic per line, 3â€“5 lines:

```text
Mindful parenting
Evening reflection habits
Community Q&A for new parents
```

Each line can become **one ToI pack** in Step 3. Night one uses **one pack only**.

| Term | Meaning |
|------|---------|
| **ToI** | Topics of Interest â€” what you want to be known for |
| **ToI pack** | One topic written up for MERIT discovery (who you help, tone, promise) |

### 2D â€” Preview locally

Double-click `merit-demo\play\index.html` in your browser.  
Widgets load from MERITâ€™s public package CDN â€” no account.

Optional (Node.js installed):

```powershell
cd C:\MyMeritApp\merit-demo
npm install
npm run verify
```

Linux/macOS:

```bash
cd ~/MyMeritApp/merit-demo
npm install
npm run verify
```

**Step 2 complete.** Named product, your words, topic list, local preview. Still no Vercel, Supabase, or Square.

---

## Step 3 â€” Register; MERIT promotes you overnight

Join as **Content Creator (CC)** on the MERIT platform. Submit **one ToI pack** from your list. Choose **one free surface** (Journal or AMA). MERIT runs discovery while you sleep.

### Overnight flow

```text
Free CC registration
  â†’ you enter one ToI pack (one interest area)
  â†’ Chain of Content (CoC) runs overnight
  â†’ DIRT matches your topic to readers
  â†’ guests land on your Journal or AMA (merit-demo shell)
  â†’ free followers first; paid Plus only when you opt in later
```

| Term | Meaning |
|------|---------|
| **CC** | Content Creator â€” you |
| **CoC** | Chain of Content â€” Topics â†’ Areas â†’ Content â†’ Queue â†’ publish |
| **DIRT** | MERIT discovery engine â€” finds audience for your ToI |

### 3A â€” Free registration

1. Open the creator registration URL for your assigned **consumer id** (MERIT operator provides this after onboarding).
2. Sign up with email â€” **Content Creator** tier (free).
3. No Square, Supabase, or Vercel for this step.

**Pattern example** (canonical demo, not your app):

`https://merit-prod.vercel.app/store/merit-demo/register`

**Your URL** (after MERIT assigns your id):

`https://merit-prod.vercel.app/store/YOUR_ID/register`

### 3B â€” Submit one ToI pack

1. Choose **one** line from `MyTopics.txt`.
2. Complete the short prompts: what you teach, who you help, your voice.
3. Submit as **one ToI pack** â†’ one **interest area** on the platform.

More packs can be added later. Night one: **one pack â†’ one platform surface**.

### 3C â€” Pick one free surface

| Surface | Visitor experience |
|---------|-------------------|
| **Journal** | Daily entries; freemium daily cap; upgrade path later |
| **AMA** | Ask-me-anything; voting; freemium caps |

Both are already in merit-demo. Most creators start with **Journal** or **AMA**.

### 3D â€” Morning

- DIRT routes interested readers to your topic.
- merit-demo is the **face** they see.
- **Guests** and **free subscribers** arrive first.
- **Plus** paid tier and **payouts** require separate setup (see below).

**Step 3 complete.** Registered CC with one live topic lane.

---

## What MERIT hosts vs what you set up later

### MERIT runs for you (no account on night one)

| Piece | What it does |
|-------|----------------|
| **PAR CDN** | Free UI widgets (`merit_workbench`, `journal`) on `/play/` |
| **meritstore** (platform) | Registration and checkout UI for provisioned creators |
| **DIRT + CoC** | Overnight discovery and routing for your ToI |
| **Free guest tier** | Visitors use Journal/AMA with daily freemium caps |

### You set up only when needed (lazy accounts)

| Account | When you actually need it |
|---------|---------------------------|
| **Vercel** | Your own live URL (`you.vercel.app`) |
| **here.now** | Marketing pages (`you.here.now`) |
| **Supabase** | Journal/AMA data saved in **your** cloud database on **your** deploy |
| **Square** | Plus subscription money paid out to **your** bank |

**Important:** MERIT does **not** hide Supabase forever. The platform hosts **widgets and registration**; **your** deployed app uses **your** Supabase for persistent data. Square connects only when you sell Plus and complete payment-provider onboarding (KYC as required by the provider).

### Money and payouts

| Stage | What happens |
|-------|----------------|
| Clone + personalize | No revenue; no payout account |
| Free CC + overnight push | Free guests and subscribers; no creator payout |
| Plus sales (later) | Subscriber pays via meritstore checkout (Square on platform) |
| Creator payout (later) | After meritstore **tenant provision** + **payment provider** link for your consumer id |

Cloning OSS does **not** open a bank account. Revenue from existing demos (e.g. `merit-demo`) flows through those tenants until **your** tenant is provisioned.

---

## Accounts â€” quick reference

| Service | Required for Steps 1â€“3? |
|---------|-------------------------|
| Git CLI | Yes (install only) |
| GitHub login | **No** (unless fork/push) |
| PAR CDN | **No** â€” public |
| Vercel | **No** until live deploy |
| here.now | **No** until marketing publish |
| Supabase | **No** until cloud journal/AMA |
| Square | **No** until Plus payouts |

---

## FAQ

**Can I skip merit-agent-skills and only use merit-demo?**  
Yes for preview. Keep merit-agent-skills for the `merit` helper and Cursor skills when you personalize or deploy.

**Do I need all of here.now, Vercel, and Supabase?**  
No. Each unlocks a different surface. Steps 1â€“3 need none of them.

**Does MERIT run Supabase and Square for me in the background?**  
PAR and platform registration are hosted by MERIT. Supabase is **your** database when you go live. Square is for **checkout and payout** when you enable Plus â€” not on night one.

**When do I get paid?**  
After meritstore tenant provision and payment-provider onboarding for your consumer id â€” not from cloning alone.

---

## Glossary

| Term | Plain English |
|------|----------------|
| **merit-agent-skills** | Free public toolkit and skills (this repo) |
| **merit-demo** | Your app shell |
| **merit** | CLI in this repo (`merit.ps1`) |
| **CC** | Content Creator |
| **ToI** | Topics of Interest |
| **ToI pack** | One topic lane for discovery |
| **CoC** | Chain of Content â€” overnight publish pipeline |
| **DIRT** | Discovery and content intelligence platform |
| **consumer id** | Your MERIT creator key (e.g. `merit-demo`) |
| **PAR** | Shared UI packages from MERIT CDN |

---

## Advanced (optional)

Read only after the three steps.

| Document | Purpose |
|----------|---------|
| [docs/usage.md](docs/usage.md) | Tiers, BYOK, commerce |
| [merit-demo OPERATOR_PROVISION](https://github.com/Mr-PI-Bala/merit-demo/blob/main/merit-demo%20docs/OPERATOR_PROVISION.md) | Vercel + Supabase + meritstore tenant |
| [docs/TRY_BUNDLES.md](docs/TRY_BUNDLES.md) | Angle 1â€“4 bundles |
| [DIRT user guide](https://github.com/AgentDraven/dirt/blob/main/DIRT%20docs/dirt_usage.md) | Full discovery dashboard |

---

## Checklist

- [ ] Step 1 â€” Cloned merit-agent-skills @ `skills-v0.3.54` and merit-demo
- [ ] Step 2 â€” Updated `branding.json`, portal text, `MyTopics.txt`, previewed `play/index.html`
- [ ] Step 3 â€” Registered as CC, one ToI pack, Journal or AMA selected
- [ ] Deferred Vercel, here.now, Supabase, Square until needed

