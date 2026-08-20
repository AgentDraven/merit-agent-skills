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

## Cursor Cloud specific instructions

The entire CLI is PowerShell. `merit.sh`, `install.sh`, and `scripts/smoke-freemium.sh` are thin bash wrappers that `exec pwsh`, so **PowerShell (`pwsh`) is the one required runtime**. It is provided by the base environment (installed via the Microsoft apt repo); if a fresh pod is missing it, the startup update script self-heals. There is no `package.json`/lockfile in this repo — Node is not needed here. The Playwright E2E suite referenced in the README lives in the separate `merit-demo`/`merit-test` repos, not here.

Prefer the `./merit.sh …` wrappers (they pick `pwsh`) over calling `pwsh ./merit.ps1` directly.

- Lint / validate (same as CI `validate.yml`): `./merit.sh closeout --path .`
- Smoke test (same as CI): `./scripts/smoke-freemium.sh` — scaffolds into a temp dir and verifies the generated play shell; also does a live HEAD to `merit-prod.vercel.app` (network egress works; it degrades to a warning if offline).
- Full "create a consumer app" flow (do it in a scratch dir outside this repo, e.g. `/tmp/my-app`): `./merit.sh init --path <dir>` → edit `<dir>/.merit_launch.md` → `./merit.sh par scaffold --path <dir> --variant workbench-journal` → `branding scaffold` → `subs scaffold` → `community scaffold` → `./merit.sh apply --path <dir>` → `./merit.sh verify --path <dir>`.

Non-obvious gotchas:
- `apply` requires non-empty `vercel_scope`, `supabase_url`, `supabase_anon_key`, and `supabase_service_role_key` in `.merit_launch.md` even for a local-only run (it writes `.env.local`/`cfg/flask_deploy.json`); placeholder values are fine for local scaffold/verify.
- `verify` FAILS until the PAR shell + branding exist (`missing cfg/par_pins.json` / `cfg/branding.json`). Run `par scaffold` + `branding scaffold` before `verify`; `init`+`apply` alone are not enough.
- `verify` prints NOTEs for missing `cfg/community.json` / `collab_schedule.json` / `alerts.json`; those are non-fatal (run `community scaffold` to clear them).
- To preview the generated product, serve the scaffold dir statically and open `play/index.html` (e.g. `python3 -m http.server` from the app dir); the page pulls PAR widgets from `merit-prod.vercel.app`.

