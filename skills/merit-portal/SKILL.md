---
name: merit-portal
description: Publish MERIT marketing portal to here.now (portal/ only); multi-surface support.
---

# merit-portal

here.now only — not Vercel app deploy. Operator white-label branding in `portal/` + `cfg/branding.json`.

```powershell
.\merit-live.ps1 portal publish --path <consumer-repo>
.\merit-live.ps1 portal publish --path <consumer-repo> --all
```

BYOK: `HERENOW_API_KEY` or `~/.herenow/credentials`. Multi-slug manifest: `cfg/portals.json`.

Vault operators:

```powershell
.\scripts\merit.ps1 portal publish
```

Footer must include **MERIT Powered**; operator branding in header (SomaTune shell pattern).
