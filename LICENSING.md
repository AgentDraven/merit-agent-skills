# Licensing — merit-agent-skills

MERIT uses a **product fork**: open adoption for skills, commercial terms for platform runtime.

## Apache 2.0 (this repository)

| You may | You may not (license alone) |
|---------|----------------------------|
| Clone, use, and modify **SKILL.md** recipes and **merit-live** scripts | Access **merit-private-vault**, cert registry write, or operator env SSOT |
| Redistribute with attribution and a copy of Apache-2.0 | Use **MERIT** trademarks beyond reasonable attribution (see `NOTICE`) |
| Build products that **call** merit-live or follow skill recipes | Imply MERIT endorsement without agreement |

**Derivatives:** Apache 2.0 **allows** derivative works of this repo’s source. Monetization is **not** via restricting forks — it is via **meritstore**, **meritsubs**, and paid PAR pins on **your** consumer host.

## meritstore / meritsubs (commercial)

| Capability | License |
|------------|---------|
| Guest `/play/`, OSS PAR pins (`@0.4.x`, `@0.2.x`) | No account; Apache skills + your deploy |
| **Plus** journal / AMA / premium PAR | **meritstore** checkout → **meritsubs** tier on **your** `consumer_id` |
| Operator revenue share | Per tenant agreement (~90% to operator after processing) |

Paid features are governed by **subscription terms** on the consumer host (`/legal/terms`) and **meritstore** registration — not by the GitHub Apache license alone.

## Operator obligations

If you ship a product based on merit-agent-skills:

1. Copy **`THIRD_PARTY_NOTICES.md`** (or the vault template) into your repo and **portal/legal.html**.
2. Keep **MERIT Powered** footer when using MERIT platform components (see `cfg/branding.json`).
3. Publish **subscription terms** at `/legal/terms` for paying subscribers.
4. Do not commit vault secrets, operator-gate phrases, or production meritstore credentials.

## Reference consumer

[Mr-PI-Bala/merit-demo](https://github.com/Mr-PI-Bala/merit-demo) — `portal/legal.html`, `portal/terms.html`, `cfg/meritstore_tenant.json`.

## Questions

Commercial licensing: contact MERIT LLC via `meritlabs@protonmail.com`.
