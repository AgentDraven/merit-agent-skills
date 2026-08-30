---
name: merit-affiliate
description: MERIT Affiliate & Design Partner funnel — attribution cfg, portal CTAs, what stays on platform (no secrets/billing).
---

# merit-affiliate

Free OSS marketing package for the MERIT **Affiliate & Design Partner** program.

`requires_vault: false` — anyone can publicize without a private vault.

## What this skill covers

1. Attribution cfg template (`cfg/consumer_attribution.json.template`)
2. Register URL shape on the **merit-prod gateway** (`/store/{consumer_id}/register` → meritstore)
3. Portal CTA recipes (join vs attribute)
4. Hard non-goals (no payout/admin/entitlement bypass)

## Naming guard

| Term | Meaning |
|------|---------|
| `partner_kinds` | Cohort on **meritsubs** (`affiliate` \| `design_partner`) |
| `affiliate_code` | Checkout attribution string on **meritstore** |
| `MERIT_AFFILIATE` | Operator runtime folder (default **MeritAcme**) — **unrelated** to this skill |

## Join vs attribute (do not mix)

| Intent | Public path |
|--------|-------------|
| **Join the program** | [merit-prod partners page](https://merit-prod.vercel.app/portal/partners.html) — mailto / operator invite (not self-serve plan checkout) |
| **Attribute a referral checkout** | Gateway register URL below |

Operator-provisioned plans (`affiliate-join`, `design-partner-join`, `partner-revenue-share`) remain on meritstore/meritsubs for admin grant paths — **not** public HTML CTAs. Do not deep-link `/store/meritsubs/register?plan=affiliate-join` (gateway redirects to partners).

## Attribute register URL shape

```text
https://merit-prod.vercel.app/store/{consumer_id}/register?affiliate=YOUR_CODE&utm_source=…&utm_medium=…&utm_campaign=…
```

Canonical entry is the MERIT production gateway; `/store/{consumer_id}/…` rewrites to meritstore for provisioned apps.

## Apply attribution (non-secret)

```powershell
# After merit init / apply — copy template into consumer cfg/
Copy-Item cfg\consumer_attribution.json.template <consumer>\cfg\consumer_attribution.json
# Edit consumer_id, affiliate_code, optional partner_kind hint
```

## Hard non-goals (FR-AFF-OSS-05 / FR-COM-03)

Forking or copying this skill **MUST NOT** grant:

- Tenant admin or secrets
- Payout destination control
- Entitlement or partner cohort bypass
- Square / ledger / billing access

Paid surfaces stay on **meritstore** + **meritsubs**. See [docs/recipes/affiliate-portal.md](../../docs/recipes/affiliate-portal.md).

## Related

- **Ecosystem overview (start here):** [merit-prod.vercel.app/portal/partners.html](https://merit-prod.vercel.app/portal/partners.html)
- Secondary provider landing: meritstore `portal/`
- Cohort + JWT: meritsubs `partner_kinds`
- Money accrual: meritstore ledger `partner_share_cents`
