---
name: merit-par-workbench
description: Scaffold OSS PAR play shell loading merit_workbench and optional journal from pkg-meritutils CDN.
---

# merit-par-workbench

```powershell
.\merit-live.ps1 par scaffold --path <consumer-repo> --variant workbench
.\merit-live.ps1 par scaffold --path <consumer-repo> --variant workbench-journal
```

Writes `cfg/par_pins.json` and `play/index.html` with SRI pins from the free OSS line (`merit_workbench@0.4.x`, `journal@0.2.x`).
