# merit-law

OSS L1 law router — unpack merit.blob via public CLI (no plaintext MERIT.instructions in repo).

## Always start here

```powershell
cd %MYMERITAPP%\merit-agent-skills
.\merit.ps1 law list
.\merit.ps1 law closeout      # full binding closeout sequence
.\merit.ps1 law edition       # OSS ship vs vault mXin for this machine
.\merit.ps1 law --for-skill merit-portal
```

Law unpacks **in memory only** from `merit.blob` beside `merit.ps1`. Full L1 SSOT remains in vault `instructions/MERIT.instructions`.

## Closeout reminder

| Step | Command |
|------|---------|
| Validate | `.\merit.ps1 closeout --path .` |
| Law | `.\merit.ps1 law closeout` |
| Release | `.\merit.ps1 ship -Message "..."` or vault `mXin` when plane **C** |

See **merit-closeout** for the closeout entry card.
