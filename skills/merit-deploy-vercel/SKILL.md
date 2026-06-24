---
name: merit-deploy-vercel
description: Scoped MERIT consumer Vercel production deploy (Flask and static variants).
---

# merit-deploy-vercel

```powershell
.\scripts\merit.ps1 deploy vercel -Project <catalog-id> [--sync-env] [--smoke]
```

Requires `cfg/flask_deploy.json` scope and `.vercel/project.json`. Never bare `vercel --prod`. Static: `npm run build` then `npx vercel --prod --scope agentdraven`.
