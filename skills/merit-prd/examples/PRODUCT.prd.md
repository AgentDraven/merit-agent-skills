# PRODUCT.prd.md — consumer app PRD (MERIT dinner)

Copy this file into your app as `docs/PRODUCT.prd.md` (or `{Name}.prd.md`). Fill every section. This file is the source of truth for:

1. **`/merit-prd`** — bake and refine the brief in your AI IDE  
2. **`/merit-portal`** — turn § Marketing portal into `portal/` copy and publish  
3. **`/merit-applogic`** (dinner Step 4) — implement Must FRs under `app_logic/` on merit-prod rails

Marketing only in `portal/` — no secrets, no app code. Product features only in `app_logic/`. Login, store, and payments stay on `merit-prod.vercel.app` rails (isolated by `consumer_id`).

---

## 0. Identity

| Field | Your value |
|-------|------------|
| Product name | |
| consumer_id (lowercase slug) | |
| One-line promise (≤140 chars) | |
| Primary audience | |
| Vercel scope (team slug) | |
| Live app URL (after create deploy) | |
| Marketing portal URL (after portal publish) | |

## 1. Problem and who

- **Job to be done:**  
- **Today’s pain:**  
- **Why now:**  

## 2. Goals and non-goals

### Target objective (1–5 bullets)

1.  
2.  

### Non-goals (must not touch this release)

-  

### Constraints

- Deadline / stack freezes / compliance:  

## 3. Experience law (Make Art)

- **First viewport:** brand, one headline, one supporting sentence, one CTA group — no dashboard clutter.  
- **Tone:** non-geeky where users see it; geek detail lives in collapsed notes.  
- **Motion / atmosphere:** (optional notes)  
- **Honesty:** do not claim dinner tiers you have not proven (see Portal dinner guide).

## 4. Marketing portal (feeds `/merit-portal`)

Edit `portal/` from this section. Keep CTAs real (app URL, register path when tenant exists).

### Hero

- **Brand / product name (hero-level):**  
- **Headline:**  
- **Supporting sentence:**  
- **Primary CTA** (label → URL):  
- **Secondary CTA** (optional):  

### Story sections (one job each)

| Section title | One sentence | Body bullets |
|---------------|--------------|--------------|
| | | |
| | | |

### Proof / trust (optional)

- What a visitor can believe today (Proven / Preview / Assisted):  

### Footer

- Must remain visibly **MERIT Powered**.  
- Legal links if you ship `portal/legal.html` / `portal/terms.html`.

### Optional companion docs

| File | Use |
|------|-----|
| `*usage.md` | How a human uses the live app (operator + end-user) |
| `*design.md` | Visual / UX intent that portal and app should share |
| This `*prd.md` | Goals, FRs, marketing SSOT |

## 5. Feature requirements (FR matrix)

Stable IDs. Prefer small Musts for the first dinner loop.

| ID | Super-category | Requirement | Surface (`portal` / `app_logic` / rails) | Priority | Acceptance check |
|----|----------------|-------------|------------------------------------------|----------|------------------|
| FR-01 | Onboard | | | Must | |
| FR-02 | Core | | | Must | |
| FR-03 | Growth | | | Should | |
| FR-04 | Polish | | | Could | |

### AGENT_REQ notes (for implementers)

For each Must FR, note later: paths, commands, acceptance checks, and **do-nots**.

## 6. `app_logic/` boundary

**In scope (your code):**

-  

**Out of scope (MERIT rails — do not fork here):**

- Auth / session (meritsubs)  
- Store / checkout / entitlements (meritstore)  
- Provider implementations (Supabase/Square projects stay provider-side until BYOK)

**Register path (when tenant provisioned):** `/store/<consumer_id>/register` on the gateway — never a showcase demo slug.

## 7. Done when (acceptance)

- [ ] § Marketing portal filled; `portal/` matches brand; `merit.ps1 portal` published (or URL noted)  
- [ ] Must FRs listed with acceptance checks  
- [ ] `app_logic/` README still states the boundary  
- [ ] No secrets in `portal/` or this PRD  

## 8. Later / out of band

- BYOK provider cutover, GlossPack theme id, OID assurance — only after baseline product works.  

## 9. Change log (brief)

| Date | Change |
|------|--------|
| | Initial draft from MERIT `PRODUCT.prd.md` template |
