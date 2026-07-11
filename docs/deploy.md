# MERIT deploy PoV

MERIT uses one human-edited deploy profile plus provider-owned machine files.

## Point of view

`MERIT_DEPLOY.md` is the only file a public creator should edit for deploy shape: Vercel scope, project id, production branch, and here.now portal slugs.

Provider CLIs still own a few generated files:

| File | Owner | Why it exists |
|------|-------|---------------|
| `MERIT_DEPLOY.md` | MERIT / human editor | One readable deploy profile and checklist |
| `cfg/flask_deploy.json` | Generated from `MERIT_DEPLOY.md` | `merit-live deploy vercel` needs machine-readable Vercel scope |
| `cfg/portals.json` | Generated from `MERIT_DEPLOY.md` | `merit-live portal publish` needs machine-readable portal surfaces |
| `.vercel/project.json` | Vercel CLI | Created by `npx vercel link`; do not commit |
| `.env.local` | Human / provider dashboard | Secrets and runtime keys; do not commit |

We do not try to replace `.vercel/project.json`; Vercel requires it to remember the linked project/org. The MERIT CLI makes this less annoying by syncing the MERIT profile first and then running the scoped deploy.

## Commands

Windows:

```powershell
.\merit-deploy.ps1 sync --path ..\merit-demo
.\merit-deploy.ps1 vercel --path ..\merit-demo
.\merit-deploy.ps1 portal --path ..\merit-demo --all
.\merit-deploy.ps1 all --path ..\merit-demo --all
```

Linux/macOS:

```bash
./merit-deploy.sh sync --path ../merit-demo
./merit-deploy.sh vercel --path ../merit-demo
./merit-deploy.sh portal --path ../merit-demo --all
./merit-deploy.sh all --path ../merit-demo --all
```

## One-time setup

1. Copy `templates/MERIT_DEPLOY.md` into the consumer repo as `MERIT_DEPLOY.md`.
2. Edit the two JSON blocks in `MERIT_DEPLOY.md`.
3. Run `merit-deploy sync`.
4. Link Vercel once:

```powershell
npx vercel link --scope <your-vercel-scope>
```

5. Add runtime secrets through Vercel CLI/dashboard or `.env.local`.
6. Deploy:

```powershell
.\merit-deploy.ps1 vercel --path <repo>
.\merit-deploy.ps1 portal --path <repo> --all
```

## Credentials

No secrets belong in `MERIT_DEPLOY.md`.

| System | Required for production | Where it belongs |
|--------|--------------------------|------------------|
| Vercel | Authenticated CLI session, linked project, `vercel_scope` | CLI session + `MERIT_DEPLOY.md`; `.vercel/project.json` generated locally |
| here.now | `HERENOW_API_KEY` or `~/.herenow/credentials` | Environment or local credentials file |
| Supabase | `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` | `.env.local` and Vercel env |
| meritsubs | `MERITSUBS_PUBLIC_BASE_URL`, `MERITSUBS_JWT_SECRET`, `MERITSUBS_API_KEY`, `MERITSUBS_ADMIN_KEY` | `.env.local` and Vercel env |
| MeritAdminGate | `OPERATOR_GATE_HASH_SLOT_1` | `.env.local` and Vercel env |

## Closeout boundary

`merit-closeout` does not deploy. Deploy commands are:

- Public/free users: `merit-deploy.ps1` / `merit-deploy.sh`, which delegate to `merit-live`.
- Vault operators: `scripts/merit.ps1 deploy vercel` and `scripts/merit.ps1 portal publish`.
