# AGENTS.md

L3: **merit-agent-skills** — public MERIT skills and CLI distribution.

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

