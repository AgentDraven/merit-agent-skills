---
name: merit-closeout
description: MERIT git closeout — run merit.ps1 law closeout, validate, release closeout (OSS) or vault mXin.
---

# merit-closeout

**Binding law:** `.\merit.ps1 law closeout` (from plane **B**). No `MERIT.instructions` file in this repo — law is in `merit.blob`.

The machine-readable contract is `cfg/merit_closeout_contract.json`. Skill installation emits `.merit-closeout.json`; validation emits `closeout-validation.json`. A release must not proceed without a recent valid validation receipt.

## Sequence

```powershell
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 law closeout          # print full law for this machine
git checkout main                 # release closeout refuses detached HEAD
.\merit.ps1 closeout             # release closeout: current repo, validate + commit + push
.\merit.ps1 closeout               # OSS git release → branch + skills-v* tag
.\merit.ps1 closeout --path . --validate-only  # validation-only exception
```

When plane **C** (vault) exists: prefer `& <operatorMeritCli> mXin` — resolve via `.\merit.ps1 where`.

## Do not

- Stop after `closeout --validate-only` when release was requested
- Raw `git commit` / `tag` / `push`
- Skip chat **3-3**

Exception: user said **WIP** / **no commit** / **local-only**.

## Host enforcement boundary

Read `docs/IAR/MERIT_CLOSEOUT_ENFORCEMENT.iar.md` and `.merit-hook-install.json` before claiming hook enforcement. `SUPPORTED-BUT-VERIFY` is not hard enforcement. Codex interactive and `codex exec` are separate modes. Hooks cannot semantically validate final 3-3 text.
