---
name: merit-referral
description: Thin pointer — pin merit_referral from merit-utils for checkout attribution URLs and manifests.
---

# merit-referral (pointer)

**SSOT moved to merit-utils:** PAR package **`merit_referral`**.

```text
https://pkg-meritutils.vercel.app/merit_referral/{version}/merit_referral.mjs
```

## Use

1. Pin `merit_referral` from merit-utils registry (same CDN as `merit_meter`).
2. Copy [`cfg/consumer_attribution.json.template`](https://github.com/AgentDraven/merit-utils/blob/main/cfg/consumer_attribution.json.template) into consumer `cfg/`.
3. Build register URLs with `buildRegisterUrl({ consumerId, referralCode, utm })`.

## With metering

Use **`merit_meter`** for usage events and **`merit_referral`** for `referralCode` on invoice payloads — same provider umbrella.

## Naming guard

| Term | Layer |
|------|-------|
| `merit_referral`, `?referral=` | Marketing / checkout |
| `MERIT_AFFILIATE`, MeritAcme | Operator runtime only — unrelated |

## Non-goals

No tenant admin, payouts, Square, or entitlement bypass. Join program: [merit-prod partners](https://merit-prod.vercel.app/portal/partners.html).

## Docs

- merit-utils [README](https://github.com/AgentDraven/merit-utils/blob/main/README.md)
- Vault rationalization: `merit-private-vault/docs/IAR/MERIT_UTILS_METER_REFERRAL_BRAINSTORM.md`
