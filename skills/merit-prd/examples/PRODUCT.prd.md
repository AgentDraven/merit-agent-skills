# PRODUCT.prd.md — consumer app PRD (MERIT dinner)

Copy this file into your app as `docs/PRODUCT.prd.md` (or `{Name}.prd.md`). Fill every section. This file is the source of truth for:

1. **`/merit-prd`** — bake and refine the brief in your AI IDE  
2. **`/merit-portal`** — turn § Marketing portal into `portal/` copy and publish  
3. **`/merit-applogic`** (dinner Step 4) — implement Must FRs under `app_logic/` on merit-prod rails

Marketing only in `portal/` — no secrets, no app code. Product features only in `app_logic/`. Login, store, and payments stay on `merit-prod.vercel.app` rails (isolated by `consumer_id`).

---

## How to fill this file (pick one)

### A) AI IDE (fastest)

Paste into your AI IDE (Cursor / Claude / etc.):

```text
Read docs/PRODUCT.prd.md in this repo.
Fill every section for this product. Keep unknowns as TBD with one question each.
Use .merit_launch.md for product_name / consumer_id when present.
Follow § Experience law (Make Art) and § Anti-patterns.
Write § Marketing portal so /merit-portal can update portal/ without inventing claims.
Add a small Must FR matrix for the first dinner loop.
Do not put secrets in this file or portal/.
```

### B) Human edit

Fill the tables and bullets below. Prefer concrete CTAs and small Must FRs over long essays.

### C) Inspiration only

Skim examples in each section, then dictate answers to the AI IDE and ask it to rewrite this file.

---

## 0. Identity

| Field | Your value | Example |
|-------|------------|---------|
| Product name | {{PRODUCT_NAME}} | Cast |
| consumer_id (lowercase slug) | {{CONSUMER_ID}} | cast |
| One-line promise (≤140 chars) | | “Cast turns dinner ideas into a shareable night plan.” |
| Primary audience | | Busy hosts who want one clear next step |
| Vercel scope (team slug) | | only if using Advanced own-host |
| Live app URL | {{APP_URL}} | https://merit-prod.vercel.app/apps/cast/play |
| Marketing portal URL | {{PORTAL_URL}} | https://cast.here.now |

---

## 1. Problem and who

- **Job to be done:**  
  _Example: Help a host go from “friends are coming” to a simple plan in under 10 minutes._
- **Today’s pain:**  
  _Example: Notes, chats, and tabs scatter the plan._
- **Why now:**  
  _Example: We already have a live MERIT shell; we only need the product story and Must FRs._

---

## 2. Goals and non-goals

### Target objective (1–5 bullets)

1. _Example: Visitor understands the promise in one viewport._
2. _Example: One Must FR works on the live `/apps/<id>/play` URL._

### Non-goals (must not touch this release)

- _Example: Custom payment processor, native mobile apps, multi-tenant admin console._

### Constraints

- Deadline / stack freezes / compliance:  

---

## 3. Experience law (Make Art)

Binding for `portal/` and user-visible `app_logic/` UI:

1. **Best-in-class ambition** — polish is part of the product, not optional garnish.  
2. **Seamless flow** — one obvious next step; fewer clicks; no dead ends.  
3. **Non-geeky voice** — insight first; geek detail one click deeper.  
4. **Every detail obsessed** — type, spacing, empty/error/loading states are designed.  
5. **Proof discipline** — only claim Proven / Preview / Assisted tiers you have evidence for.  
6. **Positive-path onboarding** — say what to do and what you get; park advanced options deeper.  
7. **Cloud First** — the host is the live cloud URL (merit-prod `/apps/` by default).  
8. **Be personal** — “your app / your store / your business”; avoid “tenant” as visitor voice.

### First viewport checklist

- [ ] Brand / product name is hero-level (not only nav text)  
- [ ] One headline + one supporting sentence + one CTA group  
- [ ] No stats strips, card grids, or floating promo badges in the hero  

---

## 4. Anti-patterns (do not)

| Anti-pattern | Do this instead |
|--------------|-----------------|
| Laundry list of absences (“no Vercel, no Square…”) on the happy path | State the green path and the live URL |
| “You are not wiring…” framing | “MERIT provides X; you write Y in `app_logic/`” |
| Dashboard first viewport | One composition: brand, headline, sentence, CTA |
| Secrets or app code in `portal/` | Marketing only; keys stay in local env / rails |
| Fork auth/store/payments into `app_logic/` | Call merit-prod rails by `consumer_id` |
| Inventing Plus/commerce as dinner-done | Mark Assisted until store tenant is live |
| Impersonal “tenant” copy | “your app” / “your store” |

---

## 5. Marketing portal (feeds `/merit-portal`)

Edit `portal/` from this section. Keep CTAs real (app URL, register path when your store is live).

### Hero

- **Brand / product name (hero-level):** {{PRODUCT_NAME}}
- **Headline:**  
- **Supporting sentence:**  
- **Primary CTA** (label → URL): Open the app → {{APP_URL}}
- **Secondary CTA** (optional):  

### Story sections (one job each)

| Section title | One sentence | Body bullets |
|---------------|--------------|--------------|
| How it works | | |
| Who it’s for | | |
| What’s next | | |

### Proof / trust (optional)

- What a visitor can believe today (Proven / Preview / Assisted):  

### Footer

- Must remain visibly **MERIT Powered**.  
- Legal links if you ship `portal/legal.html` / `portal/terms.html`.

### Optional companion docs

| File | Use |
|------|-----|
| `*usage.md` | How a human uses the live app |
| `*design.md` | Visual / UX intent shared by portal + app |
| This `*prd.md` | Goals, FRs, marketing SSOT |

### After marketing is filled

```text
/merit-portal
.\merit.ps1 portal --path ..\<app>
```

---

## 6. Feature requirements (FR matrix)

Stable IDs. Prefer small Musts for the first dinner loop.

| ID | Super-category | Requirement | Surface (`portal` / `app_logic` / rails) | Priority | Acceptance check |
|----|----------------|-------------|------------------------------------------|----------|------------------|
| FR-01 | Onboard | Visitor opens live app and understands the promise | portal + app_logic | Must | |
| FR-02 | Core | | app_logic | Must | |
| FR-03 | Growth | | app_logic / rails | Should | |
| FR-04 | Polish | | portal / app_logic | Could | |

### AGENT_REQ notes (for implementers)

For each Must FR, note later: paths, commands, acceptance checks, and **do-nots**.

### Implement with

```text
/merit-applogic
```

Prove on {{APP_URL}}.

---

## 7. `app_logic/` boundary

**In scope (your code):**

- Product features and UI that express the PRD Must FRs  

**Out of scope (MERIT rails — do not fork here):**

- Auth / session (meritsubs)  
- Store / checkout / entitlements (meritstore)  
- Provider implementations (Supabase/Square projects stay provider-side until BYOK)

**Register path (when your store is live):** `/store/<consumer_id>/register` on the gateway — never a showcase demo slug.

---

## 8. Done when (acceptance)

- [ ] § Marketing portal filled; `portal/` matches brand; `merit.ps1 portal` published (or URL noted)  
- [ ] Must FRs listed with acceptance checks  
- [ ] `app_logic/` README still states the boundary  
- [ ] No secrets in `portal/` or this PRD  
- [ ] Live app URL opens on merit-prod  

---

## 9. Later / out of band

- BYOK provider cutover, GlossPack theme id, OID assurance — only after baseline product works.  

---

## 10. Change log (brief)

| Date | Change |
|------|--------|
| | Initial draft from MERIT `PRODUCT.prd.md` template (Make Art + anti-patterns + AI fill path) |
