# MERIT OSS BootStrap

Public freeware **device BootStrap** for this repo.  
Not the same as root **`merit.ps1`** (that is the MERIT **CLI**: `init` / `apply` / `verify` / …).

## OSS experience (easy path)

```powershell
git clone https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills\BootStrap
.\MERIT_BootStrap.cmd
```

On first run you are asked for the **OSS bench folder** (saved as User env **`MYMERITAPP`**).  
Default: `C:\MyMeritApp`. Pick any drive/path you want.

That:

1. Saves `MYMERITAPP` for later sessions  
2. Copies live BootStrap to `%MYMERITAPP%\BootStrap\`  
3. Adds `%MYMERITAPP%\MERIT_BootStrap.cmd`  

Later:

```powershell
# if MYMERITAPP is set, or from the bench root:
%MYMERITAPP%\MERIT_BootStrap.cmd
```

Change the folder anytime: menu **M**.

You do **not** need the private vault for OSS freemium.

| Piece | Role |
|-------|------|
| Root `merit.ps1` | CLI for apps |
| `BootStrap/MERIT_BootStrap.*` | Device setup menu |
| `%MYMERITAPP%` | Your OSS bench (default `C:\MyMeritApp`) |

## Menu

1. Prerequisites  
2. Ensure `%MYMERITAPP%\merit-agent-skills`  
3. Seed `merit-demo` under `%MYMERITAPP%`  
4. Validate (`closeout` + `smoke`)  
5. Guidelines  
6. Show `MERIT.json`  
**M** — Set / change `MYMERITAPP`  
**T** — Private-Vault teaser  
**P** — Seed Private-Vault BootStrap into `~/dev` (needs vault GitHub access)

## Private-Vault teaser (menu P)

Public facts only: AgentDraven account, private repo `merit-private-vault`, and its `BootStrap` install to `~/dev`. No vault product law in this OSS folder.

## License

Same as parent repo (`LICENSE` / `LICENSING.md`).
