## 0.5.19 - 2026-08-24

### Fixed
- **Hub OC parse:** restore `Set-OcCreatorFace` brace after the DualRail `consumer_id` handoff (0.5.18 tag is unusable).

## 0.5.18 - 2026-08-24

### Fixed
- **OC DualRail register:** PAR scaffold now takes the OC `consumer_id`, so Register free goes to `/store/oc-…/register` instead of showcase `merit-demo` (which redirects to sku-commerce).

## 0.5.17 - 2026-08-24

### Fixed
- **Hub OC helpers:** dot-source `BootStrap/_oss.ps1` at script scope so `Get-OssState` survives `Ensure-HubOssHelpers`. `-Oc` / `-TryIt` no longer die after the helper returns. `MERIT_HUB_NO_ELEVATE=1` skips the interactive close prompt.

## 0.5.16 - 2026-08-24

### Added
- **OC-done:** `merit.ps1 oc --product-name` resyncs DualRail play from PAR, stamps branding, publishes demo `portal/` files through merit-prod `/api/portal/publish` (platform here.now key). Hub OC prints play + register + here.now. Missing platform key is a hard blocker, not a fake URL.

### Changed
- Hub pin **`skills-v0.5.16`** / **`vault-v0.5.8`**.

## 0.5.15 - 2026-08-23

### Added
- **Hub map:** one menu **1 Setup laptop · 2 Install OSS · 3 Try it · OC · 4 Vault · VC · 5 Join MERIT · 0 Stop**. Aliases **J**=2, **V**=4. Drill-in + receipt after each step. Old D/G live inside **2**.
- **OC (OSS in the Cloud):** `merit.ps1 oc` publishes play+cfg and **requires** store `free-community` activate. Prints play + register. Optional `POST merit-prod/api/portal/publish` (platform here.now; laptop never needs a key).
- **VC:** after local vault clone — operator/tenant grade vs freeware OC.

### Removed
- OSS `BootStrap/MERIT_BootStrap.ps1` / `.cmd` / `.sh` and template `MERIT.json`. Internals stay `_oss.ps1` + `oss-bench.json`.

### Changed
- Smoke/closeout: `MERIT_VERIFY_QUIET=1` hides optional community `verify NOTE` lines. Hub pin **`skills-v0.5.15`** / **`vault-v0.5.8`**.

## 0.5.14 - 2026-08-23

### Fixed
- **OSS smoke does not ask for here.now.** Hub **G** / `smoke-freemium` already passed on **merit-prod** PAR (no account). The old footer (`set HERENOW_API_KEY`) was Angle 2 marketing-publish, not freeware validate. Subscriber register stays at `merit-prod.vercel.app/store/{id}/register`. `verify NOTE` community JSON files are optional.

## 0.5.13 - 2026-08-23

### Removed
- **Leftover live OSS BootStrap copy.** Hub never creates `%MYMERITAPP%\BootStrap\` or `%MYMERITAPP%\MERIT_BootStrap.cmd`. Those were a second on-disk product from the old BootStrap installer (36 KB menu, keys 1–4, schema-1 `MERIT.json` pinned to an old tag). They drifted from git and looked like starting over. PHASE 2 lives only in the clone: `%MYMERITAPP%\merit-agent-skills\BootStrap\_oss.ps1`. Hub **J** / **2** / Pristine delete the retired live copy if it reappears. Laptop status is `%MYMERITAPP%\oss-bench.json` only.

### Changed
- Docs and Hub pin: **`skills-v0.5.13`** / **`vault-v0.5.7`**. Cold start is Merit-Hub only. `BootStrap/MERIT_BootStrap.md` (old live-copy table) deleted.

## 0.5.12 - 2026-08-23

### Changed
- **One script, three phases:** Merit-Hub stays the only user entry. OSS BootStrap is internal `_oss.ps1` (PHASE 2, green keys D/G/F/U; PHASE 3 vault is key 3). Laptop menu is PHASE 1 (cyan).
- **OSS status file:** `%MYMERITAPP%\oss-bench.json` uses human names (`benchFolder`, `skillsFolder`, `skillsPin`, `lastValidateOk`, …). Old `MERIT.json` fields are migrated.
- **Agents:** closeout + 3-3 is binding (`AGENTS.md`, alwaysApply rule). Hub config `agentCloseoutRequired`.

## 0.5.11 - 2026-08-23

### Fixed
- **Prereq prompt:** Hub and OSS BootStrap now print **MERIT Python venv MISSING/OK** and separate **Environment** vs **Tools** before asking. `y` lists exactly what will be installed or SET (User `MYMERIT*`).
- **OSS BootStrap Python path:** venv is `%MYMERITTOOLS%\merit-venv` (default `C:\Tools`), not hardcoded `C:\Tools`. Hub already followed the env; BootStrap does now too.

## 0.5.10 - 2026-08-23

### Fixed
- **`$HOME` collision:** leftover scan used `$home = …` which PowerShell treats as the read-only automatic `$HOME`. Scan roots are `C:\`, `C:\Users\<name>`, and `~/dev` only — the profile folder itself is never assigned or deleted.

## 0.5.9 - 2026-08-23

### Added
- **Run history:** `Start-Transcript -Append` to `%MYMERITTOOLS%\backups\Merit-Hub-history.log` (same backups folder as snapshots).
- **Press Enter to close** so the elevated window does not vanish when work finishes.

## 0.5.8 - 2026-08-23

### Fixed
- **Pristine env:** MYMERIT* User/Process/Machine are **cleared on purpose**. Menu now prints Process/User/Machine scopes and explains that the next run will prompt again (Enter = defaults).
- **Stuck deletes:** attrib -R -A -S -H, takeown/icacls when elevated, locking-process insight, then retry — not a silent give-up.

### Changed
- Auto-relaunch via UAC (`Start-Process -Verb RunAs`) when not Administrator (same pattern as other MERIT launchers). Does not bail.
- After Pristine, scan leftover folders (`HumanBala`, `DravenCode.OLD`, `Code`, `*Merit*` under `C:\` and each `C:\Users\<name>`) and **double-confirm** (`DELETE`) before removing.
- Hub pin: **`skills-v0.5.8`** / **`vault-v0.5.6`**.

## 0.5.7 - 2026-08-23

### Fixed
- **Pristine:** remove leftover `%MYMERITTOOLS%\Merit-Hub\` folder (retired cmd/json/HTML-save layout). Always wipe the default OSS bench (`C:\MyMeritApp`) even if `MYMERITAPP` was pointed at Tools (old code kept a child named `Merit-Hub` and never touched MyMeritApp).

### Changed
- Download / README copy: the full `pwsh -NoProfile -ExecutionPolicy Bypass -File C:\Tools\Merit-Hub.ps1` line is **required**. Double-click and `.\Merit-Hub.ps1` are called out as blocked for internet downloads.
- Hub pin: **`skills-v0.5.7`** / **`vault-v0.5.7`**.

## 0.5.6 - 2026-08-23

### Changed
- **Merit-Hub is one file again.** Removed `Merit-Hub.cmd`. Windows entry is a single command: `pwsh -NoProfile -ExecutionPolicy Bypass -File …` (`Bypass` is this process only; script self-`Unblock-File`s after start).
- README name map: public `merit.ps1` vs vault `scripts/merit.ps1` vs `BootStrap/MERIT.json` vs `~/dev/MERIT.json`.
- Hub pin: **`skills-v0.5.6`** / **`vault-v0.5.6`**.

## 0.5.5 - 2026-08-23

### Added
- **`Merit-Hub.cmd`:** Windows launcher next to the `.ps1` — `Unblock-File` (Mark of the Web) + `-ExecutionPolicy Bypass` for this process only. Fixes `not digitally signed` / `PSSecurityException` from `.\Merit-Hub.ps1` after a browser download.

### Changed
- Docs: browser “harmful file” warnings are expected; run the `.cmd`. Do not set machine ExecutionPolicy to Unrestricted.
- Hub pin: **`skills-v0.5.5`** / **`vault-v0.5.5`**.

## 0.5.4 - 2026-08-22

### Fixed
- **Merit-Hub parse:** mojibake em-dashes in double-quoted strings, here-string backticks, and `$Script:IsWindows` colliding with PowerShell's read-only `$IsWindows` — first-run no longer `ParserError` / exit.
- **StrictMode:** Windows detection uses `PSVersionTable.ContainsKey('PSPlatform')` (`$Script:HubOnWindows`).

### Changed
- First interactive run **prompts** for `MYMERITTOOLS` / `MYMERITAPP` when unset; **Enter** accepts defaults (`C:\Tools`, `C:\MyMeritApp`).
- README: download via **Raw** only; ParserError symptom = saved HTML.
- Hub pin: **`skills-v0.5.4`** / **`vault-v0.5.4`**.

## 0.5.3 - 2026-08-22

### Added
- **Merit-Hub menu I / `-InstallSkills`:** built-in skills install (same as `install.ps1`) for Cursor, Codex, Hermes, OpenClaw, Grok, Devin, etc.
- **pwsh guide + portable install:** menu **1** prints download links; optional portable pwsh to `%MYMERITTOOLS%\pwsh\` + `pwsh.cmd` shim.

### Changed
- Merit-Hub **J** prompts for skills install; README documents pwsh requirement and host install paths.
- Hub pin: **`skills-v0.5.3`** / **`vault-v0.5.3`**.

## 0.5.2 - 2026-08-22

### Added
- **`install.ps1` targets:** Hermes, OpenClaw, GrokBot (alias Grok), Devin — promoted to **supported** in `cfg/agent_hosts.json`.
- **Collaboration** section in README — email [meritlabs@protonmail.com](mailto:meritlabs@protonmail.com?subject=MERIT%20host%20suggestion) to suggest AI IDEs / agent harnesses.

### Changed
- **Merit-Hub:** single standalone **`Merit-Hub.ps1`** only (embedded pins; no `.cmd`/`.sh`/`.json`/`install.ps1`).
- README tagline and multi-runtime table list all supported + research hosts; GitHub repo description updated.
- Hub pins: **`skills-v0.5.2`** / **`vault-v0.5.3`**.

## 0.5.1 - 2026-08-21

### Added
- **`Merit-Hub/`** — laptop hub (`Merit-Hub.ps1` / `.cmd` / `.sh` / `.json`) for Pristine v2 cleanup, OSS/vault jumpstart, and MYMERITTOOLS prereqs. Copy to `%MYMERITTOOLS%\Merit-Hub` (default `C:\Tools\Merit-Hub`); run `Merit-Hub.cmd`.
- **`Merit-Hub/install.ps1`** — one-shot copy from repo to local tools root.

### Changed
- README + `docs/bootstrap_pathway.md`: Merit-Hub documented as the easiest cold-start path before/alongside full skills clone.
- Hub pins: **`skills-v0.5.1`** / **`vault-v0.5.2`**.

## 0.5.0 - 2026-08-21

### Changed
- **Alpha baseline (HumanBala-approved MINOR):** product VERSION re-baselined to **0.5.0**. Public pin **`skills-v0.5.0`** (TAG_PREFIX `skills-v`, L1 section E.0).
- Cold-start / BootStrap / README / HowTo / deploy / onboard / mm-upgrade pins scrubbed to `skills-v0.5.0`.
- Partner Private-Vault pin for menu **P** / docs: **`vault-v0.5.0`** (vault new numbering scheme).

### Notes
- Historical `skills-v0.3.*` tags remain valid checkouts; tip for new clones is `skills-v0.5.0`.
- Pairs with vault alpha **vault-v0.5.0**.
## 0.3.58 - 2026-08-21

### Changed
- OSS BootStrap menu **1** installs laptop-shared **`C:\Tools\merit-venv`** (same path as Private-Vault) â€” not assumed pre-installed; helps merit-demo / Flask while public `merit.ps1` stays PowerShell-first.
- Docs: `bootstrap_pathway.md` / BootStrap README / design note.

### Notes
- Pairs with vault **v1.8.73** Tools Python policy.

## 0.3.57 - 2026-08-21

### Added
- `TAG_PREFIX` file (`skills-v`) so vault `mXin` against this repo tags `skills-v{VERSION}`.
- Docs: after first clone, use `merit.ps1` / vault `mXin` â€” not raw git closeout (`bootstrap.design.md`, `bootstrap_pathway.md`).

### Changed
- Public pin â†’ **`skills-v0.3.57`** (pairs with vault **v1.8.72** for operator closeout tooling).

## 0.3.56 - 2026-08-21

### Added
- `docs/bootstrap_pathway.md` â€” annotated OSS BootStrap flowchart (cold start â†’ **T** / **P** handoff). Explicit: no Tools Python, no affiliate / `runtime out` on the public path. Links from BootStrap README, `bootstrap.design.md`, and README Start-here.
- `docs/bootstrap.design.md` â€” L1/L2/L3 host-agnostic instruction chain; **`cfg/agent_hosts.json`** registry (Cursor, ClaudeCode, Codex, VSCode, Hermes, OpenClaw, Paperclip, GrokBot, Devin) with auto-detect design.

### Changed
- Public pin â†’ **`skills-v0.3.56`**; menu **P** seeds vault **`v1.8.71`**.

## 0.3.55 - 2026-08-21

### Changed

- Cold-start docs: clone from bench folder (`mkdir C:\MyMeritApp` / `~/MyMeritApp`) in `BootStrap/README.md`, root README, HowTo Over Dinner, deploy, usage.
- Public pin / Portal tip â†’ **`skills-v0.3.55`**; menu **P** seeds vault **`v1.8.69`**.

### Notes

- `git clone` creates `merit-agent-skills` as a child of the current directory â€” start in the OSS bench folder.

## 0.3.54 - 2026-08-20

### Added

- **OSS device BootStrap** under `BootStrap/` (`MERIT_BootStrap.ps1` / `.cmd` / `.sh`): prereqs, `%MYMERITAPP%` bench (default `C:\MyMeritApp`), demo seed, validate, Private-Vault teaser + menu **P** seed into `~/dev` (pins vault `v1.8.68`).
- Docs: `docs/bootstrap.design.md`; BootStrap section in `docs/design.md`; Start-here row in `README.md`.
- Menu implementations for prereqs / bench skills pin / demo / OSS validate.

### Changed

- Public pin / Portal tip â†’ **`skills-v0.3.54`** (`VERSION`, `merit.ps1`, README, HowTo, deploy, onboard/mm-upgrade skills).
- Bench clone uses tag `skills-v0.3.54` (not floating `main`).

### Notes

- Root `merit.ps1` remains the MERIT CLI. BootStrap does not replace it.
- Cold start: clone this tag â†’ `BootStrap\MERIT_BootStrap.cmd` â†’ menu **T**/**P** with vault GitHub credentials.

## 0.3.53 - 2026-08-17

### Changed

- Pin `merit_ux@0.1.3` in `cfg/par_pins.free.json` (status tooltip + PREVIEW PSCR).
- `apps refresh` resyncs PAR pins + play shell from SSOT (never `app_logic/`).
- UserGuide Â§12 usage scaffold; `cfg/usage.json` template for community baseline.

## 0.3.52 - 2026-08-13

### Added

- Webpage-shell AP-MA-13: `merit.ps1 verify` / closeout FAIL DIY `merit-ux-brand` without `createAppShell`/`createBrandShell`. Play template carries `data-webpage-shell="createAppShell"`. Smoke asserts marker. Checklist: merit-prod `docs/IAR/plans/WEBPAGE_SHELL_COMPLIANCE.md`.
