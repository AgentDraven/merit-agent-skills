---
name: merit-applogic
description: >-
  Implement consumer product features under app_logic/ from a filled PRODUCT.prd.md
  and portal marketing promise. Use when the user says /merit-applogic, implement
  app_logic from PRD, or scaffold Must FRs after /merit-prd and /merit-portal.
  Public freeware — Cloud First on merit-prod rails; no vault required.
---

# merit-applogic

**Public freeware** from [merit-agent-skills](https://github.com/AgentDraven/merit-agent-skills).

Turn the **already-written PRD + portal promise** into **Make Art** product code under `app_logic/` only. Auth, store, payments, and providers stay on **merit-prod** rails.

## When to use

- User says `/merit-applogic`, “implement app_logic from PRD”, or “scaffold Must FRs”.
- After `/merit-prd` (Must FRs filled) and preferably after `/merit-portal` (marketing live or stubbed).
- Dinner Step 4 — cloud app from create already at `https://merit-prod.vercel.app/apps/<consumer_id>/play`.

## Inputs (read in this order)

1. `docs/PRODUCT.prd.md` or `*prd.md` — Must rows in § Feature requirements (stable `FR-*` IDs + acceptance checks).
2. Marketing slice — PRD § Marketing portal and/or `portal/` / `portal.json` (tone, CTAs, promise).
3. Consumer context — `consumer_id` from `.merit_launch.md` / `cfg/merit-sync.json`; live app URL from create success banner.
4. Optional: `*usage.md`, `*design.md`.
5. Platform map — `GET https://merit-prod.vercel.app/api/health` (routes / rails). Do not invent hosts.

**Gate:** if Must FRs are empty or still template blanks, stop and send the user to `/merit-prd`. Do not invent product features.

## Layout SSOT

```
app_logic/
  README.md                 # boundary + how to prove Musts
  FR_MAP.md                 # FR-ID → module path → acceptance
  <feature-slug>/           # one Must (or tight Must cluster) per folder
    README.md               # intent, UX notes, acceptance
    index.js                # or .mjs / framework file the play shell can load
```

- Prefer `app_logic/<feature-slug>/` over a flat dump of files.
- Wire into the existing play / workbench shell with the smallest mount (import, script tag, or documented hook) — extend; do not replace MERIT chrome.
- New FRs add modules; leave rails alone.

## Workflow

### 1. Read & gate

- Confirm PRD Musts have IDs, requirement text, and acceptance checks.
- Confirm `consumer_id` and that create already published a cloud app URL (Cloud First).
- Skim portal promise so user-visible strings match marketing tone.

### 2. Map FRs → modules (ACK)

- Propose the `app_logic/` tree and `FR_MAP.md` rows (Musts first).
- Ask for an explicit ACK: “implement Must FRs” (or adjust the map once).
- Park Should/Could unless the user expands scope.

### 3. Implement Musts

- Write code **only** under `app_logic/`.
- Consume meritsubs / meritstore / meritutils / gateway URLs from cfg + merit-prod health — compose rails; do not copy provider implementations into the consumer.
- Fail closed on missing entitlement; ship clear empty / error states.
- Match Make Art: seamless flow, few clicks, non-geeky user-facing copy aligned with the portal.

### 4. Acceptance

- For each Must, record how to prove the acceptance check in `FR_MAP.md` / module README.
- Run or describe verify steps against the **cloud** app URL.
- Gaps become Should/Could — do not silently drop Musts.

### 5. Handoff

- Dinner Step 5 when commerce/Plus needs a provisioned store tenant.
- Point back to `/merit-prd` if the FR matrix changes.

## Scaffold files (first pass)

If `app_logic/` is empty or only the create stub README, create:

1. `app_logic/README.md` — from [`examples/app_logic.README.md`](examples/app_logic.README.md) (fill consumer_id).
2. `app_logic/FR_MAP.md` — from [`examples/FR_MAP.md`](examples/FR_MAP.md) populated from Must FRs.
3. One folder per Must (or approved cluster) with `README.md` + starter `index.js` that mounts safely (no-op UI until feature logic lands).

Then implement the Must bodies after ACK.

## Do / don’t

| Do | Don’t |
|----|--------|
| Put product features in `app_logic/` | Fork meritsubs / meritstore / Square / Supabase provider code into the app |
| Use merit-prod cloud URL for proof | Treat laptop `npx serve` as the product host |
| Align strings with portal / PRD tone | Invent Must FRs the PRD does not list |
| Fail closed on entitlement gaps | Soft-fail into unpaid Plus features |
| Keep FR IDs stable in `FR_MAP.md` | Rewrite auth/store/payments “just for dinner” |

## Related skills

- **`merit-prd`** — bake PRD + FR matrix first.
- **`merit-portal`** — marketing `portal/` only.
- **`merit-mm-upgrade`** — gap analysis on an *existing* codebase (different trigger).
- Dinner guide: https://merit-prod.vercel.app/portal/developers/full-app/
