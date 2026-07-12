---
name: merit-subs
description: meritsubs production mount reference, meritstore registration funnel, freemium caps and Plus SKU.
---

# merit-subs

meritsubs provides **subscriber_identity** and entitlement state through production MERIT Vercel mounts. Public consumers must not expose local `/api/meritsubs` stubs, relays, or embedded provider billing/usage-metering source code.

```powershell
.\merit.ps1 subs scaffold --path <consumer-repo>
```

Edit `.merit_launch.md`: set `consumer_id`, keep the production metered-provider defaults unless MERIT gives you dedicated URLs, and run `merit apply` to generate consumer config.

Freemium caps: `cfg/freemium_limits.json` (journal 2/day; AMA 2 ask/vote/response/day; top 25 leaderboard).

Plus SKU default: **$10.79/mo** ($2.49/wk, round up); 20% off 6-month; 50% off annual. ~90% to operator after 4% + $0.50 processing.

Reference: **Mr-PI-Bala/merit-demo** + `merit-prod.vercel.app/store/merit-demo/register`.

## Legal (required for operators)

| Page | Path | Source |
|------|------|--------|
| Privacy + OSS notices | `/legal.html` | `portal/legal.html` — include `THIRD_PARTY_NOTICES` for merit-agent-skills (Apache-2.0) |
| Plus subscription terms | `/legal/terms` | `portal/terms.html` — meritstore pricing from `cfg/plus_sku.json` |

Vault templates: `merit-private-vault/templates/legal/MERIT_FREEMIUM_LEGAL.html`, `MERIT_SUBSCRIPTION_TERMS.html`.

**Production boundary:**

Use hosted `merit-prod.vercel.app` MERIT provider endpoints for usage credits, promo validation, entitlements, and Square checkout. Default intro promo is `MERITAGENT`; hosted provider config owns the default $25 credit.

For public `merit-demo`, verify no `api/meritsubs`, `api/ama`, or `api/journal` metered handlers are shipped.

**Product fork:** Apache-2.0 adoption on skills; monetization via meritstore — not license royalties.

Vault operators provision tenant after integration cert.
