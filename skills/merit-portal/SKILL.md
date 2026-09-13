---
name: merit-portal
description: >-
  Shape and publish MERIT marketing portal to here.now (portal/ only); multi-surface
  support. Prefer copy from docs/PRODUCT.prd.md § Marketing portal (see /merit-prd).
---

# merit-portal

here.now only — not Vercel app deploy. Operator white-label branding in `portal/` + `cfg/branding.json`. Public MERIT visual guidance is in [`docs/MERIT_BRAND_SYSTEM.md`](../../docs/MERIT_BRAND_SYSTEM.md); use it for every MERIT-powered OSS portal.

## Law

```powershell
.\merit.ps1 law --for-skill merit-portal
```

## OSS (always — plane B)

1. Prefer filled `docs/PRODUCT.prd.md` — use **`/merit-prd`** if empty.
2. Map § Marketing portal into `portal/` / `cfg/portals.json`.

```powershell
.\merit.ps1 portal --path <consumer-repo>
```

BYOK: `HERENOW_API_KEY` or `~/.herenow/credentials`.

Footer: **MERIT Powered**. Include `portal/legal.html` and `portal/terms.html`. Apply the shared dark MERIT palette, card/divider system, responsive layout, visible legal-link separators, and small legalese block defined in `docs/MERIT_BRAND_SYSTEM.md` and the private footer IAR. When shared CSS or image assets change, cache-bust their URLs or use immutable filenames in the same release.

## Operator (plane C only)

Resolve vault CLI: `.\merit.ps1 where` → use `operatorMeritCli`.

```powershell
& '<vault>\scripts\merit.ps1' portal publish
```

Never use `.\scripts\merit.ps1` from merit-agent-skills (that path does not exist on plane B).
