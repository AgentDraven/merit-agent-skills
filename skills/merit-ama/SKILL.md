---
name: merit-ama
description: MERIT AMA Q&A leaderboard on journal primitives; privacy modes and freemium caps.
---

# merit-ama

AMA lives on the consumer host at `/ama/` (see **merit-demo**). Uses journal list patterns + merit-demo API for votes and leaderboard.

Privacy modes:
- Anonymous local-only (no leaderboard)
- Registered: leaderboard as anonymous+region, handle only, or handle+region (user choice)
- Region: geo-IP state preferred; profile field; optional fine area (e.g. Bay Area) via opt-in checkbox

Freemium: 2 questions, 2 votes, 2 responses per day; top 25 visible. Plus SKU uncaps.

```powershell
.\merit-live.ps1 subs scaffold --path <consumer-repo>
```

Report abuse: `meritlabs@protonmail.com` (+ operator email if configured in `cfg/branding.json`).

Future: `merit_ama` PAR package when a second consumer adopts AMA.
