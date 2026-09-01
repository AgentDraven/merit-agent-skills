---
name: merit-subs
description: meritsubs embed scaffold, meritstore registration funnel, freemium caps and Plus SKU.
---

# merit-subs

## Law

```powershell
.\merit.ps1 law --for-skill merit-subs
```

## OSS (always)

```powershell
.\merit.ps1 subs scaffold --path <consumer-repo>
```

Freemium caps: `cfg/freemium_limits.json`. Plus SKU: `cfg/plus_sku.json`.

Use hosted `merit-prod.vercel.app` MERIT provider endpoints — no local `/api/meritsubs` stubs in production builds.

Legal pages: `portal/legal.html`, `portal/terms.html`.

## Operator (plane C only)

Vault legal templates when provisioning tenants. Resolve CLI via `.\merit.ps1 where`.

Reference consumer: **Mr-PI-Bala/merit-demo**.
