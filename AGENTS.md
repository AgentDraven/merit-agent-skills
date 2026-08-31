# AGENTS.md

**merit-agent-skills** — public MERIT skills and CLI distribution.

## Closeout (binding — never skip)

**There is no `MERIT.instructions` in this repo** (vault L1 only). This section + skill **`merit-closeout`** are the binding closeout law for **merit-agent-skills**.

Work is **not done** until **validate + git ship + 3-3**. The CLI verb `closeout` is **validate only** — not the full closeout.

| Step | OSS laptop (no vault) | Operator (vault on disk) |
|------|------------------------|---------------------------|
| Validate | `.\merit.ps1 closeout --path .` | same |
| Git release | `.\merit.ps1 ship -Message "..."` | vault `scripts\merit.ps1` **`mXin`** + **`git verify`** |
| Chat | **3-3**: Done · State (VERSION/tag) · Next | same |

Before `ship`: checkout a branch (`main`) — detached HEAD is refused unless `-AllowDetached`.

Diagnostic (optional): `.\merit.ps1 where` or Hub `-Surface` / menu **W**.

Exception only if the user said **WIP** / **no commit** / **local-only**.

## Path resolution (agents)

Do **not** assume `~/dev` or Cursor workspace paths.

1. `MYMERITAPP` / `MYMERITTOOLS` env vars
2. `%MYMERITAPP%\oss-bench.json`
3. `.\merit.ps1 where` or `Merit-Hub.ps1 -Surface`

See skill **merit-surface** for the A×B×C matrix.

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
