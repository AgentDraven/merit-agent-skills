---
name: merit-par-workbench
description: Scaffold DualRail Gloss play (merit_ux createAppShell + Value Tour) with Advanced merit_workbench and optional journal from the MERIT package gateway.
---

# merit-par-workbench

```powershell
.\merit.ps1 par scaffold --path <consumer-repo> --variant workbench
.\merit.ps1 par scaffold --path <consumer-repo> --variant workbench-journal
.\merit.ps1 par scaffold --path <consumer-repo> --variant workbench-journal --theme gloss-aurora
```

Writes `cfg/par_pins.json` and `play/index.html` with SRI pins (`merit_ux@0.1.3` GlossPack, `merit_workbench@0.4.x`, optional `journal@0.2.x`).

**Play default:** DualRail Gloss — Value Tour (Ask / Meet / Book / Journal) first; FR-MPD-29 workbench under Advanced geek only. Themes: `gloss-aurora` (default), `gloss-graphite`, `gloss-daylight`.
