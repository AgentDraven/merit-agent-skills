# AGENTS.md

L3: **merit-agent-skills** — public MERIT skills and CLI distribution.

## Closeout (binding — never skip)

Work is **not done** until closeout + **3-3**. Do not end a completed scope with only a chat summary.

1. Operator ship of this repo: vault `scripts/merit.ps1` `mXin` then `git verify` (never raw git commit/tag/push).
2. Consumer apps: `.\merit.ps1 closeout --path .`
3. Chat **3-3**: **Done** · **State** (include `VERSION` / tag) · **Next** (≤3 bullets each).

Exception only if the user said **WIP** / **no commit** / **local-only**.

## Maniacal focus

- Own public skills under `skills/`.
- Own the single public CLI: `merit.ps1` and `merit.sh`.
- Own small configuration/play-shell templates needed by the public CLI.
- Do not ship product implementations, running Portals, provider backends, private vault policy, or consumer app source.

## Boundaries

- `skills/` contains agent instructions.
- `templates/` contains only small bootstrap templates, not reference products.
- `scripts/` contains validation helpers only.
- The production Portal belongs in `merit-prod/public/portal/`.

