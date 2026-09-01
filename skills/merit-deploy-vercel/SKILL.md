---
name: merit-deploy-vercel
description: Scoped MERIT consumer Vercel production deploy (Flask and static variants).
---

# merit-deploy-vercel

## Law

```powershell
.\merit.ps1 law --for-skill merit-deploy-vercel
```

## OSS (always)

```powershell
.\merit.ps1 deploy --path <consumer-repo>
```

Requires `cfg/flask_deploy.json` with `vercel_scope`. Never bare `vercel --prod` without scope.

## Operator (plane C only)

Resolve: `.\merit.ps1 where` → `operatorMeritCli`.

```powershell
& '<vault>\scripts\merit.ps1' deploy vercel -Project <catalog-id> [--sync-env] [--smoke]
```

Angle-4 operators deploy to **their own** Vercel team scope.
