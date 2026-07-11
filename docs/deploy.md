# MERIT deploy PoV

MERIT uses one local launch file plus provider-owned machine files.

## Point of view

`.merit_launch.md` is the only file a public creator should edit for launch and deploy setup. It is local-only, gitignored, and may contain secrets.

Provider CLIs still own a few generated files:

| File | Owner | Why it exists |
|------|-------|---------------|
| `.merit_launch.md` | Human editor | One local protected launch file |
| `.env.local` | Generated from `.merit_launch.md` | Runtime secrets for local/dev use; do not commit |
| `cfg/flask_deploy.json` | Generated from `.merit_launch.md` | Vercel scope for machine deploy |
| `cfg/portals.json` | Generated from `.merit_launch.md` | here.now portal surfaces |
| `.vercel/project.json` | Vercel CLI | Created by `npx vercel link`; do not commit |

We do not try to replace `.vercel/project.json`; Vercel requires it to remember the linked project/org. The MERIT CLI makes this less annoying by syncing the MERIT profile first and then running the scoped deploy.

## Commands

Windows:

```powershell
.\merit.ps1 init --path ..\merit-demo
# edit ..\merit-demo\.merit_launch.md
.\merit.ps1 apply --path ..\merit-demo
.\merit.ps1 deploy --path ..\merit-demo
.\merit.ps1 portal --path ..\merit-demo
```

Linux/macOS:

```bash
./merit.sh init --path ../merit-demo
# edit ../merit-demo/.merit_launch.md
./merit.sh apply --path ../merit-demo
./merit.sh deploy --path ../merit-demo
./merit.sh portal --path ../merit-demo
```

## One-time setup

1. Run `merit init --path <repo>`.
2. Edit the mandatory section at the top of `.merit_launch.md`.
3. Run `merit apply --path <repo>`.
4. Link Vercel once:

```powershell
npx vercel link --scope <your-vercel-scope>
```

5. Add runtime secrets through Vercel CLI/dashboard or `.env.local`.
6. Deploy:

```powershell
.\merit.ps1 deploy --path <repo>
.\merit.ps1 portal --path <repo>
```

## Credentials

Secrets are allowed only in local `.merit_launch.md` and generated `.env.local`. Both are gitignored.

| System | Required for production | Where it belongs |
|--------|--------------------------|------------------|
| Vercel | Authenticated CLI session, linked project, `vercel_scope` | CLI session + `.merit_launch.md`; `.vercel/project.json` generated locally |
| here.now | `HERENOW_API_KEY` or `~/.herenow/credentials` | `.merit_launch.md` or local credentials file |
| Supabase | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` | `.merit_launch.md` |
| meritsubs | Optional secrets; generated when blank | `.merit_launch.md` / generated `.env.local` |
| MeritAdminGate | `OPERATOR_GATE_HASH_SLOT_1` | Advanced field in `.merit_launch.md` |

## Billing and usage authority

The public consumer repo is not the billing or usage-metering authority.

- Usage credits, promo validation, and Square checkout live behind hosted MERIT services such as `meritstore.vercel.app`.
- The default intro promo is `MERITAGENT`.
- The default intro credit budget is $25, controlled by hosted provider configuration.
- A consumer may display usage state, but changing local repo code must not create paid entitlements or bypass hosted metering.

## Closeout boundary

`merit-closeout` does not deploy. Deploy commands are:

- Public/free users: `merit.ps1` / `merit.sh`.
- Vault operators: `scripts/merit.ps1 deploy vercel` and `scripts/merit.ps1 portal publish`.
