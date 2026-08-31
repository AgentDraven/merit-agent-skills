---
name: merit-closeout
description: MERIT git closeout for merit-agent-skills — validate, ship (OSS), or vault mXin.
---

# merit-closeout

**This repo has no `MERIT.instructions` (vault L1 only).** Binding closeout law for **merit-agent-skills** lives here and in root **`AGENTS.md`**.

## Binding: closeout ≠ `closeout --path` alone

| Step | OSS laptop (no vault) | Operator (vault on disk) |
|------|------------------------|---------------------------|
| 1 Validate | `.\merit.ps1 closeout --path .` | same |
| 2 VERSION/CHANGELOG | bump `VERSION` + `CHANGELOG.md` section | same |
| 3 Git ship | `.\merit.ps1 ship -Message "..."` | `& <vault>\scripts\merit.ps1 mXin -Message "..."` |
| 4 Verify | `git log -1` + tag on remote | `& <vault>\scripts\merit.ps1 git verify` |
| 5 Chat | **3-3** (Done · State · Next) | same |

**`merit.ps1 closeout`** = verify + git whitespace check only. Work is **not done** until step 3 (commit + annotated tag + push).

## OSS ship (default on OSS-only bench)

```powershell
cd %MYMERITAPP%\merit-agent-skills
git checkout main   # ship refuses detached HEAD unless -AllowDetached
.\merit.ps1 closeout --path .
.\merit.ps1 ship -Message "feat: <summary>"
```

`ship` reads `VERSION` + `TAG_PREFIX` → tag `skills-v*`, pushes branch + tag. Idempotent if tag already on HEAD.

If vault `scripts\merit.ps1` exists and you did not set `MERIT_SHIP_OSS=1`, `ship` exits 2 and points to vault `mXin`.

## Operator (vault cloned)

```powershell
$env:MERIT_OPERATOR_CWD = '<skills-repo>'
& '<vault>\scripts\merit.ps1' mXin -Message "feat: <summary>"
& '<vault>\scripts\merit.ps1' git verify
```

## Do not

- End scope after `closeout --path` only
- Raw `git commit` / `git tag` / `git push` as closeout (use `ship` or vault `mXin`)
- Skip 3-3 in chat

Exception: user said **WIP** / **no commit** / **local-only**.
