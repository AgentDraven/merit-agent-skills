# Try bundles — merit freemium angles

Each bundle maps to a **merit** command sequence. **Accounts, tiers, payouts:** [usage.md](usage.md). Full stack: clone [Mr-PI-Bala/merit-demo](https://github.com/Mr-PI-Bala/merit-demo).

| Bundle | Command(s) | Angle | Outcome |
|--------|------------|-------|---------|
| **try-workbench** | `par scaffold --variant workbench` | 1 | `/play/` loads `merit_workbench@0.4.x` |
| **try-workbench-journal** | `par scaffold --variant workbench-journal` | 1 | `/play/` + `journal@0.2.x` |
| **try-portal** | `branding scaffold` + edit `portal/` + `portal publish --surface main` | 2 | `{slug}.here.now` marketing |
| **try-multi-portal** | `subs scaffold` + `portal publish --all` | 2 | Hub + journal/ama/subs slugs (`cfg/portals.json`) |
| **try-subs** | `subs scaffold` + production meritsubs mount reference | 3 → paid | hosted meritsubs + meritstore register CTA |
| **try-admin-gate** | `admin gate demo-init` | 2 / 4 | `/admin/` MeritAdminGate demo |
| **try-full-shell** | Clone merit-demo + `verify` | 1–4 | All surfaces |
| **try-live-demo** | Visit deployed merit-demo | 3 | Guest → register → Plus |

## Angle 1 — developer (GitHub only)

```powershell
mkdir my-merit-app; cd my-merit-app
git init
..\merit-agent-skills\merit.ps1 par scaffold --variant workbench-journal
..\merit-agent-skills\merit.ps1 branding scaffold
..\merit-agent-skills\merit.ps1 verify
```

Open `play/index.html` locally or run `merit.ps1 deploy --path <repo>` after launch setup.

## Angle 2 — creator (marketing + app)

Angle 1 + create or edit the consumer-owned `portal/` + set `HERENOW_API_KEY` + `merit.ps1 portal --path <repo>`.

## Angle 3 — subscriber (live demos)

| Demo | Guest play | Register |
|------|------------|----------|
| **merit-demo** (canonical) | [merit-demo](https://github.com/Mr-PI-Bala/merit-demo) deploy URL | `merit-prod.vercel.app/store/merit-demo/register` |
| AURAVYBE (portfolio) | AURAVYBE `/play/` | `merit-prod.vercel.app/store/auravybe/register` |
| SomaTune (portfolio) | SomaTune `/play/` | `merit-prod.vercel.app/store/somatune/register` |

Freemium caps: journal 2/day; AMA 2 ask/vote/response/day. Upgrade **Plus** $10.79/mo.

## Angle 4 — operator

Fork merit-demo pattern → MERIT assigns `consumer_id` → integration cert → meritstore tenant → vault `merit.ps1`.

## Conversion funnel (guest → paid)

1. **Guest** — OSS PAR on `/play/`, `/journal/`, `/ama/` with daily caps  
2. **Free register** — meritstore free SKU / OAuth → meritsubs guest+registered tier  
3. **Cap hit** — UI CTA to Plus  
4. **Paid** — `merit-prod.vercel.app/store/{consumer_id}/register` → meritsubs Plus entitlements → uncapped + `@1.0.x` PAR (Phase 3)

See `cfg/freemium_limits.json` and `cfg/plus_sku.json` on consumer repos.
