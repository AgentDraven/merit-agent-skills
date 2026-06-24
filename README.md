# merit-agent-skills

Free **Cursor Agent Skills** for MERIT-shaped product repos. Operational recipes only — they teach your agent which shell commands to run; they do not include private vault policy, cert registry write access, or production secrets.

**Authoritative product PRD** (private): `AgentDraven/merit-private-vault` → `docs/IAR/PRD_MERIT_AGENT_SKILLS_PLATFORM.md`

## Quick install

```powershell
git clone https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
```

Project-scoped install:

```powershell
.\install.ps1 -Target Project -Path C:\path\to\your-repo
```

Then in Cursor: ask the agent to use a skill by name (e.g. `meritcert`, `merit-closeout`, `merit-deploy-vercel`).

## What's included (free)

| Skill | Purpose |
|-------|---------|
| `meritcert` | Certification vocabulary (`cert foundation`, `integration`, `status`, `validate`) |
| `merit-closeout` | `mXin`, hygiene, 3-3 report |
| `merit-iar` | IAR acceptance ID format and handoff rules |
| `merit-deploy-vercel` | Scoped Vercel consumer deploy (Flask + static variants) |
| `merit-operator-gate` | Vault operator gate hash workflow (operators only) |
| `merit-onboard` | Persona, repo onboard, foundation cert |
| `merit-portal` | here.now marketing portal publish |

Also: `templates/cfg/flask_deploy.json.template` for scoped Vercel deploy.

## What's not included (paid / private)

| Service | How you get it |
|---------|----------------|
| Full `merit.ps1` + cert registry | MERIT vault / invited operator access |
| meritstore checkout | Production tenant on `meritstore.vercel.app` keyed by `consumer_id` |
| meritsubs tiers | Embedded on **your** `{product}.vercel.app/api/meritsubs` |
| PAR packages (`merit_workbench@1.0.x`) | meritsubs entitlement + pin on consumer host |

Commerce identity is **`consumer_id`** (catalog project id), not your GitHub login.

## Portability

Skills are **authored for Cursor** (`~/.cursor/skills/`). The portable contract is documented PowerShell commands; other agent hosts can use the same text as runbook or system prompt.

## Releases

Pin to tags (e.g. `skills-v1.0.0`), not floating `main`, for production closeout.

## Sync from vault

This repo is exported from `merit-private-vault/templates/skills/` at release time. Do not fork certification logic into skills.
