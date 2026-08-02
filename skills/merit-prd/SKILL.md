---
name: merit-prd
description: >-
  Draft or refine a consumer-app PRD from *prd.md (and optional *usage.md /
  *design.md). Use when the user says /merit-prd, bake the PRD, fill PRODUCT.prd.md,
  or prepare marketing copy before merit-portal. Public freeware — no vault required.
  Feeds portal/ marketing; then /merit-applogic implements Must FRs under app_logic/.
---

# merit-prd

**Public freeware** from [merit-agent-skills](https://github.com/AgentDraven/merit-agent-skills).

Help the builder **write the product story first** (dinner Step 3 → Step 4). You do **not** implement `app_logic/` here unless the user explicitly asks after the PRD is ACK’d.

## When to use

- User says `/merit-prd`, “write the PRD”, “bake the product brief”, or “fill `*prd.md`”.
- After AutoMagic `create` success, before or while shaping `portal/`.
- Before `/merit-portal` so marketing copy has a single source of truth.

## Inputs (read in this order)

1. Repo root `*prd.md` or `docs/*prd.md` (prefer `docs/PRODUCT.prd.md`).
2. Optional companions: `*usage.md`, `*design.md`, chat notes, existing `portal/portal.json` / `portal/index.html`.
3. If no PRD exists — copy the outline from [`examples/PRODUCT.prd.md`](examples/PRODUCT.prd.md) into the consumer repo, then fill it with the user (Socratic ≤5 questions if underspecified).

## Workflow

1. **Discover** — product name, `consumer_id`, who it’s for, one-sentence promise.
2. **Fill the PRD** — complete every section in the template; leave unknowns as `TBD` with a question, do not invent launch claims.
3. **Marketing slice** — § Marketing portal must be concrete enough for `/merit-portal` (hero, headline, supporting line, CTAs, section copy). No secrets, no provider keys.
4. **FR matrix** — MoSCoW rows with stable IDs (`FR-01`…). Prefer small, testable Musts for dinner; park Coulds.
5. **Boundary** — § `app_logic/` lists only product features; auth/store/payments stay on MERIT rails (`merit-prod.vercel.app`).
6. **Handoff** — tweak `portal/` with `/merit-portal` (or `.\merit.ps1 portal`), then implement Must FRs with **`/merit-applogic`**.

## Do / don’t

| Do | Don’t |
|----|--------|
| Keep one PRD as SSOT for marketing + feature intent | Duplicate a second PRD body in chat without writing the file |
| Align portal claims with dinner tier honesty | Claim Plus/commerce “over dinner” if still operator-assisted |
| Point `/merit-portal` at § Marketing portal | Put secrets or app code in `portal/` |
| Keep FR IDs stable across edits | Implement code in this skill turn unless user ACK’d |

## Related skills

- **`merit-portal`** — push marketing from the PRD into `portal/` and publish (portal folder only).
- **`merit-applogic`** — implement Must FRs under `app_logic/` on merit-prod rails.
- **`merit-mm-upgrade`** — gap → FR packets for an *existing* codebase (different trigger).
- Dinner guide: https://merit-prod.vercel.app/portal/developers/full-app/
