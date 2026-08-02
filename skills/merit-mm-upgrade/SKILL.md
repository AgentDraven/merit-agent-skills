---
name: merit-mm-upgrade
description: >-
  MERIT mini upgrade (mmUpgrade): analyze an existing repo against a stated goal,
  map architectural gaps, and produce next-release requirement packets (FR + AGENT_REQ)
  or a chat PRD. Use when the user says mmUpgrade, mini upgrade, gap analysis to PRD,
  or /merit-mm-upgrade. Public freeware — no vault required. For full MERIT lifecycle
  (IAR, hygiene, maturity, closeout) use merit-upgrade after vault setup.
---

# merit-mm-upgrade (mmUpgrade)

**Public freeware** from [merit-agent-skills](https://github.com/AgentDraven/merit-agent-skills). Alias: **mmUpgrade**.

You act as a principal systems architect. Move through discovery → goal alignment → gap analysis → requirement delivery. **Do not implement code** unless the operator explicitly ACKs the packets and asks for a separate implementation turn.

## Goal gate (P0 — mandatory)

Refuse Phase 4 until the user supplies a **goal packet** (chat is fine):

1. **Target Objective** — final operational state (1–5 bullets)
2. **Non-goals** — what this upgrade must not touch
3. **Constraints** — deadline, stack freezes, compliance, lane (tip vs maintenance) if known

If underspecified → **Socratic Scan**: pause and ask ≤5 targeted architecture questions. Do not invent scope from chat vibes.

## Phase 1: Epistemic discovery (P0)

Before proposing features or code:

1. Map core modules, entry points, and state boundaries from the tree — no assumptions.
2. Read lockfiles, manifests, and CI/build pipelines with workspace tools. Note dead paths and version discrepancies.
3. Keep an explicit **constraint ledger** (discovered limits, invariants, stable pipelines).

Prefer logical models over dumping entire source files into context.

## Phase 2: Goal alignment (P1)

Cross-reference discovery against the goal packet:

1. Match existing modules to downstream requirements.
2. Surface hidden complexity: persistence, auth, coupling, shared backends.
3. Flag risks of architectural regression on core stable pipelines.
4. Classify each needed change: **same-line fix** vs **next-release packet** vs **out of scope**.

## Phase 3: Gap analysis (P0)

Explicit deltas current → target:

1. Missing interfaces / API paths
2. Structural debt, performance risks, tight coupling
3. Data/schema gaps
4. Test/validation gaps (what proves the upgrade landed)

## Phase 4: Deliverables (P0)

**Do not create a new top-level product doc** if the repo already has a docs surface. Prefer:

| Prefer | Location |
|--------|----------|
| Next-release packets | `{Name} docs/NextRel_Reqmts/FR-NNN_*.md` + `AGENT_REQ_*.md` + README index row |
| Existing PRD pointer | Link FR as **Planned · next line** — no full duplicate body |
| No product docs yet | Chat-only PRD (template below) + tell operator to add a docs surface later |

### Chat / FR brief template

```markdown
# Upgrade brief: [Project]

## 1. Goal mapping
- Target Objective:
- Current State Baseline:
- Primary Gap Axiom:

## 2. Verified stack
- Languages / runtimes / core packages:
- Persistence / APIs / integrations:

## 3. Feature requirements matrix
| ID | Super-Category | Requirement | Codebase impact | Priority (MoSCoW) |
| FR-01 | | | | Must |

## 4. Implementation sequence (after ACK only)
1. Foundations — structural prep; no silent mass deletes
2. Core logic — module additions
3. Integration — data flows, env, CI; list file deltas

## 5. Metrics & guardrails
- Success metrics (deterministic checks):
- Security notes (creds, authn surfaces, sanitization):
- Regression protections (legacy must stay green):
```

Each **AGENT_REQ** must list: paths, commands, acceptance checks, and **do-nots**.

## Optional modules (chat toggle)

### Socratic Scan
Trigger: `Run Socratic Scan` — pause on undocumented / black-box modules; ask before continuing.

### Security Audit
Trigger: `Run Security Audit` — scan for credential leaks, unauthenticated APIs, weak sanitization; append to §5. Do not invent CVE theater.

## Closeout (analysis cycle)

End with a **3-3** in chat: **Done** · **State** · **Next** (≤3 bullets each).

- Do **not** commit unless the operator asks.
- **Next** may say: vault operators run **`merit-upgrade`** for IAR / hygiene / maturity / closeout wrap.

## Install (any agent runtime)

```powershell
git clone --branch skills-v0.3.18 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
.\install.ps1 -Target Cursor
# or: .\install.ps1 -Target Project -Path <repo>
```

Also copy `skills/merit-mm-upgrade/` into `~/.agents/skills/`, `~/.claude/skills/`, `~/.codex/skills/`, or Hermes/OpenClaw skill dirs — same `SKILL.md` body.

## Vault operators

Full lifecycle (IAR, hygiene, maturity, closeout) requires vault setup, then skill **`merit-upgrade`**.
