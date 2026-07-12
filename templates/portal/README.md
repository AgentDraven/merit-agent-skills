# Portal

Portal is the standard MERIT marketing and onboarding surface for a consumer or provider.

Start by editing `portal.json`. Most teams only need to update the brand, base URL, provider cards, and calls to action.

```powershell
.\merit-live.ps1 portal scaffold --path <repo>
```

The generated `portal/` folder is safe to publish as a static site and must not contain secrets.

