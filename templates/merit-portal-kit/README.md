# MERIT portal kit skeleton

Minimal marketing publish root for new MERIT consumers.

**Living reference (full):** m4fi [`portal/`](../../portal/)  
**Agent guide:** [MERIT_PORTAL_KIT_AGENT_GUIDE.md](../../m4fi%20docs/IAR/MERIT_PORTAL_KIT_AGENT_GUIDE.md)  
**Contract:** [PORTAL_KIT.md](../../m4fi%20docs/IAR/PORTAL_KIT.md)

## Quick start

1. Copy this folder to `{consumer}/portal/` (or merge into an empty `portal/`).
2. Edit `portal.json`: `marque.copy`, `marque.appBaseUrl`, `brand`, tiers.
3. Add `img/logo.jpg` (and optional banner / flank / plans).
4. Fix `try.html` / `join.html` redirect URLs (replace `EXAMPLE.vercel.app`).
5. Rewrite `legal.html` / `terms.html` / `security.html`.
6. Publish **only** `portal/` to here.now.

## Layout

| Path | Role |
|------|------|
| `js/portal-surface.js` | Marketing vs app base URLs |
| `js/portal-pathway.js` | Pills + now/next/next2 from `tier_ladder` |
| `js/portal-core.js` | Theme, copy, CTAs, boot |
| `login.html.example` / `upgrade.html.example` | Optional shells — not live |

## CTAs

`ctas.layout`: `pair_plus_prompt` (default) · `triple_row` · `stack` · `primary_only`  
Max 3 enabled. Always falls back to `ctas.default` if none enabled.
