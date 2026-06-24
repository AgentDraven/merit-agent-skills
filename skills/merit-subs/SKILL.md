---
name: merit-subs
description: meritsubs embed scaffold, meritstore registration funnel, freemium caps and Plus SKU.
---

# merit-subs

meritsubs provides **subscriber_identity** on the consumer host (`/api/meritsubs`). Not a PAR package.

```powershell
.\merit-live.ps1 subs scaffold --path <consumer-repo>
```

Edit `cfg/merit-sync.json`: set `consumer_id` and `meritstore_register_url`.

Freemium caps: `cfg/freemium_limits.json` (journal 2/day; AMA 2 ask/vote/response/day; top 25 leaderboard).

Plus SKU default: **$10.79/mo** ($2.49/wk, round up); 20% off 6-month; 50% off annual. ~90% to operator after 4% + $0.50 processing.

Reference: **Mr-PI-Bala/merit-demo** + `meritstore.vercel.app/merit-demo/register`.

## Legal (required for operators)

| Page | Path | Source |
|------|------|--------|
| Privacy + OSS notices | `/legal.html` | `portal/legal.html` — include `THIRD_PARTY_NOTICES` for merit-agent-skills (Apache-2.0) |
| Plus subscription terms | `/legal/terms` | `portal/terms.html` — meritstore pricing from `cfg/plus_sku.json` |

Vault templates: `merit-private-vault/templates/legal/MERIT_FREEMIUM_LEGAL.html`, `MERIT_SUBSCRIPTION_TERMS.html`.

**Production meritsubs embed:**

```powershell
# From meritsubs repo
.\scripts\embed-merit-demo.ps1
# Or from consumer
.\scripts\embed-meritsubs.ps1
```

See `api/meritsubs/README.md` on merit-demo.

**Product fork:** Apache-2.0 adoption on skills; monetization via meritstore — not license royalties.

Vault operators provision tenant after integration cert.
