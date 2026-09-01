# AGENTS.md

**merit-agent-skills** — public MERIT skills and CLI distribution.

## Law authority (no plaintext L1 in repo)

Full vault L1 (`MERIT.instructions`) is **not** shipped here. OSS law lives in **`merit.blob`** (obfuscated pack) unpacked only by **`merit.ps1 law`**.

| Need | Command |
|------|---------|
| Full closeout law | `.\merit.ps1 law closeout` |
| Section | `.\merit.ps1 law --section VIII.F` |
| Skill slice | `.\merit.ps1 law --for-skill <name>` |
| Edition tier | `.\merit.ps1 law edition` |

Skills are **index cards** pointing at `merit.ps1 law`. See skill **merit-law**.

## Closeout (binding — never skip)

Work is **not done** until **validate + git ship + 3-3**.

| Step | OSS laptop (no vault) | Operator (vault on disk) |
|------|------------------------|---------------------------|
| Law | `.\merit.ps1 law closeout` | same |
| Validate | `.\merit.ps1 closeout --path .` | same |
| Git release | `.\merit.ps1 ship -Message "..."` | vault `scripts\merit.ps1` **`mXin`** + **`git verify`** |

The CLI verb **`closeout`** = validate only — not MERIT closeout.

Before `ship`: checkout a branch (`main`).

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
