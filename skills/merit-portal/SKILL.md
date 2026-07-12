---
name: merit-portal
description: Publish MERIT marketing portal to here.now (portal/ only); multi-surface support.
---

# merit-portal

here.now only — not Vercel app deploy. Operator white-label branding in `portal/` + `cfg/branding.json`.

```powershell
.\merit.ps1 portal --path <consumer-repo>
.\merit.ps1 portal --path <consumer-repo> --all
```

BYOK: `HERENOW_API_KEY` or `~/.herenow/credentials`. Multi-slug manifest: `cfg/portals.json`.

Vault operators:

```powershell
.\scripts\merit.ps1 portal publish
```

Footer must include **MERIT Powered**; operator branding in header (SomaTune shell pattern).

Include **`portal/legal.html`** and **`portal/terms.html`** in the consumer or vault-owned `portal/` folder. This skill does not bundle a Portal implementation; it operates on the caller's own Portal.
