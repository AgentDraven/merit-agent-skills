---
name: merit-closeout
description: MERIT git closeout — run merit.ps1 law closeout, validate, ship (OSS) or vault mXin.
---

# merit-closeout

**Binding law:** `.\merit.ps1 law closeout` (from plane **B**). No `MERIT.instructions` file in this repo — law is in `merit.blob`.

## Sequence

```powershell
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 law closeout          # print full law for this machine
git checkout main                 # ship refuses detached HEAD
.\merit.ps1 closeout --path .    # validate only
.\merit.ps1 ship -Message "..."   # OSS git release → skills-v*
```

When plane **C** (vault) exists: prefer `& <operatorMeritCli> mXin` — resolve via `.\merit.ps1 where`.

## Do not

- Stop after `closeout --path` (validate only)
- Raw `git commit` / `tag` / `push`
- Skip chat **3-3**

Exception: user said **WIP** / **no commit** / **local-only**.
