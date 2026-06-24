---
name: merit-deploy-vercel
description: Scoped MERIT consumer Vercel production deploy (Flask and static variants).
---

# merit-deploy-vercel

```powershell
.\merit-live.ps1 deploy vercel --path <consumer-repo>
```

Requires `cfg/flask_deploy.json` with `vercel_scope` and `.vercel/project.json`. Never bare `vercel --prod` without scope.

Vault operators (sync env, smokes):

```powershell
.\scripts\merit.ps1 deploy vercel -Project <catalog-id> [--sync-env] [--smoke]
```

Angle-4 operators deploy to **their own** Vercel team scope.
