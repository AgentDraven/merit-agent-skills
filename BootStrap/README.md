# MERIT OSS BootStrap

Public freeware **device BootStrap** for this repo.  
Not the same as root **`merit.ps1`** (that is the MERIT **CLI**: `init` / `apply` / `verify` / …).

**Baseline pin:** parent repo tag **`skills-v0.3.56`** (or current `skills-v*` — see repo `VERSION` / tags).

**Pathway flowchart (annotated):** [docs/bootstrap_pathway.md](../docs/bootstrap_pathway.md) — OSS cold start → **T** / **P** handoff. Affiliate **MAD**, Tools Python, and `~/dev` populate are Private-Vault only.

## OSS experience (easy path)

Start in the OSS bench folder (recommended: `C:\MyMeritApp`). `git clone` creates `merit-agent-skills` **inside** whatever directory you are in.

```powershell
mkdir C:\MyMeritApp
cd C:\MyMeritApp
git clone --branch skills-v0.3.56 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills\BootStrap
.\MERIT_BootStrap.cmd
```

Linux/macOS:

```bash
mkdir -p ~/MyMeritApp
cd ~/MyMeritApp
git clone --branch skills-v0.3.56 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills/BootStrap
./MERIT_BootStrap.sh
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

Menu **P** clones the vault pin and launches Private-Vault BootStrap. After that, operators continue with edition **V**, Tools Python, affiliate **MAD** (default), then persona/repo populate — documented in the private vault `docs/vault_usage.md` §7c (not in this public repo).

## License

Same as parent repo (`LICENSE` / `LICENSING.md`).
