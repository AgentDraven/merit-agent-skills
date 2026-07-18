---
name: merit-livealpha
description: >-
  Elevate a MERIT consumer from demoware to production-worthy live alpha (Baseline App):
  MERIT Research floors (≥10 categories × ≥10 APA refs, ≥50 cross-refs), MeritSubs identity,
  dual dataplane, legal/diag surfaces, freemium, alerts, managed rooms. Use when the user
  invokes /merit-livealpha, says live alpha, no demoware, Baseline App, design-partner pilot,
  or runs merit.ps1 livealpha.
disable-model-invocation: true
---

# merit-livealpha

Slash-first skill. User typically runs:

```text
/merit-livealpha review brainstorming, IAR docs and build
```

Local scaffold (no chat):

```powershell
.\merit.ps1 livealpha --path <consumer-repo>
.\merit.ps1 baseline --path <consumer-repo>   # alias
```

**SSOT:** `AgentDraven/merit-agent-skills` only. Do not author in Mr-PI-Bala clean test trees.

## Goal

Ship a **production-worthy alpha** consumers can put in front of design partners — not localStorage demoware marketed as multi-user sync, scheduled email, or managed video.

## Before coding

1. Read consumer `cfg/merit-sync.json` (`consumer_id`, gateway URLs).
2. Read `docs/IAR/SOTU.md`, PRD, design, usage (or branded docs equivalents).
3. If missing, run `merit.ps1 livealpha --path <repo>` to scaffold Research + Baseline cfg.
4. Confirm Research floors in `cfg/research_crossrefs.json`: categories ≥10, refs/category ≥10, edges ≥50.

## Agent checklist (repo-specific)

Execute in order; skip only with explicit honest-defer labeled in docs/UI.

### 0) Policy

- Vault L1: MERIT Research floors + no-demoware / production-worthy alpha (operator may own vault edit).
- Consumer `AGENTS.md`: never claim local demo as multi-user sync, scheduled email, or managed video.

### 1) MERIT Research pack

- `docs/IAR/{consumer_id}_BASELINE_RESEARCH.md` (or title-case product name): **Full** tier.
- Ten categories, each with `#ref-{cat}-01` … `#ref-{cat}-10` and real APA 7 entries (no invented citations):
  `a11y`, `pwa`, `privacy`, `identity`, `freemium`, `community`, `rooms`, `alerts`, `safety`, `tenancy`
- `cfg/research_crossrefs.json`: ≥50 distinct `(claim_id, primary_ref)` edges; multi-domain claims use supporting refs from ≥2 categories.
- PRD = Summary cites; design = Technical SSOT + `#ref-*` why links; usage/SOTU must not contradict Research.
- Extend consumer `verify` to fail if floors unmet or `#ref-*` unresolved.

### 2) Identity + freemium

- MeritSubs guest/email onboard via gateway `meritsubs_base`; JWT + `GET entitlements` Bearer.
- `cfg/freemium_limits.json` + `cfg/plus_sku.json`; server-side caps → **402** → storefront register CTA.
- No dark-pattern upgrade copy.

### 3) Dual dataplane (1C)

- **Primary:** consumer-owned API + Supabase RLS (`consumer_id`); migrate community/AMA/journal off localStorage SSOT (local = offline cache only, labeled).
- **Platform:** restore/verify gateway `/api/ama`, `/api/journal`, `/api/leaderboard` with `consumer_id` + freemium.
- Never reuse platform Supabase keys in the consumer.

### 4) L1 surfaces

- `/legal.html`, `/legal/terms`, `/diag/` (public meta, no secrets), `/test/`, `/admin/` (keyed).
- Export/delete-my-data path for journal privacy baseline.

### 5) Alerts + rooms (full pilot)

- Resend email + VAPID Web Push + SW handler + unsubscribe; gate live claims on diag flags.
- Managed room **records** (schedule, capacity, hosts, consent); moderator gate; Jitsi for media with honest bound (MERIT roster/policy ≠ signed Jaas unless secrets exist).

### 6) Validate + SOTU

- `merit.ps1 verify` / consumer `e2e` (local + production URL when claiming deploy).
- SOTU → **ACCEPT for public pilot alpha** only if Research floors PASS and honesty bounds hold.
- List remaining OPS inputs (domain, VAPID, Resend, Christina roster/legal owner) without fake-done.

## Honesty bounds (never waive)

| Claim | Required truth |
|-------|----------------|
| Multi-user community | Tenant API/DB, not unnamed localStorage |
| Email / push | Provider configured + delivery path; else prefs-only label |
| Live rooms | Managed records + explicit media provider bound |
| Offline | Banner: offline / not synced |

## Reference patterns

- MeritSubs onboard: SomaTune play host
- AMA/journal fetch: merit-demo → `merit-prod.vercel.app`
- Legal templates: vault `templates/legal/*` + merit-subs skill
