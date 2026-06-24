# merit-agent-skills

Free **Cursor Agent Skills** and **`merit-live`** CLI for MERIT-shaped product repos. Operational recipes teach agents which commands to run; they do not include private vault policy, cert registry write access, or production secrets.

**Start here (full stack):** [Mr-PI-Bala/merit-demo](https://github.com/Mr-PI-Bala/merit-demo)

**PRD** (private): `AgentDraven/merit-private-vault` → `docs/IAR/PRD_MERIT_AGENT_SKILLS_PLATFORM.md`

## Quick install

```powershell
git clone https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
```

## merit-live (public CLI)

```powershell
.\merit-live.ps1 par scaffold --path ..\merit-demo --variant workbench-journal
.\merit-live.ps1 branding scaffold --path ..\merit-demo
.\merit-live.ps1 subs scaffold --path ..\merit-demo
.\merit-live.ps1 deploy vercel --path ..\merit-demo
.\merit-live.ps1 portal publish --path ..\merit-demo --all
.\merit-live.ps1 verify --path ..\merit-demo
```

Linux/macOS: `./merit-live.sh` (requires `pwsh` or PowerShell).

## Skills

| Skill | Purpose |
|-------|---------|
| `merit-live` / `merit-par-workbench` | PAR play shell (`merit_workbench@0.4.x`, `journal@0.2.x`) |
| `merit-portal` | here.now marketing (`portal/` only); multi-surface |
| `merit-subs` | meritsubs + meritstore funnel, freemium caps |
| `merit-ama` | AMA Q&A + leaderboard (merit-demo) |
| `merit-admin-gate` | MeritAdminGate phrase auth |
| `merit-deploy-vercel` | Scoped Vercel deploy (your team scope) |
| `merit-onboard` | OSS quickstart → merit-demo |
| `meritcert`, `merit-closeout`, `merit-iar` | Vocabulary; vault operators run writes |

All OSS skills use **`.\merit-live.ps1`** first; vault **`.\scripts\merit.ps1`** only in operator fallback blocks.

## Freemium vs Plus

| | Free | Plus ($10.79/mo) |
|---|------|------------------|
| Journal | 2 entries/day | Uncapped |
| AMA | 2 ask/vote/response/day; top 25 | Uncapped |
| PAR | OSS `@0.4.x` / `@0.2.x` | Commercial `@1.0.x` (when live) |

Plus billing: $2.49/wk equivalent, monthly **$10.79** (round up); 20% off 6-month; 50% off annual. ~90% to operator after **4% + $0.50** processing.

## Releases

Pre-GA: **`skills-v0.x.y`** (minor bumps in this program). GA **`1.0.0`** when HumanBala approves. Pin to tags, not floating `main`.

Current: **`skills-v0.3.0`** (merit-live 0.3.0 + merit-demo consumer app reference).

## Sync from vault

Exported from `merit-private-vault/templates/skills/` at release time.
