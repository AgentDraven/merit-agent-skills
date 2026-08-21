## 0.3.57 - 2026-08-21

### Added
- `TAG_PREFIX` file (`skills-v`) so vault `mXin` against this repo tags `skills-v{VERSION}`.
- Docs: after first clone, use `merit.ps1` / vault `mXin` — not raw git closeout (`bootstrap.design.md`, `bootstrap_pathway.md`).

### Changed
- Public pin → **`skills-v0.3.57`** (pairs with vault **v1.8.72** for operator closeout tooling).

## 0.3.56 - 2026-08-21

### Added
- `docs/bootstrap_pathway.md` — annotated OSS BootStrap flowchart (cold start → **T** / **P** handoff). Explicit: no Tools Python, no affiliate / `runtime out` on the public path. Links from BootStrap README, `bootstrap.design.md`, and README Start-here.
- `docs/bootstrap.design.md` — L1/L2/L3 host-agnostic instruction chain; **`cfg/agent_hosts.json`** registry (Cursor, ClaudeCode, Codex, VSCode, Hermes, OpenClaw, Paperclip, GrokBot, Devin) with auto-detect design.

### Changed
- Public pin → **`skills-v0.3.56`**; menu **P** seeds vault **`v1.8.71`**.

## 0.3.55 - 2026-08-21

### Changed

- Cold-start docs: clone from bench folder (`mkdir C:\MyMeritApp` / `~/MyMeritApp`) in `BootStrap/README.md`, root README, HowTo Over Dinner, deploy, usage.
- Public pin / Portal tip → **`skills-v0.3.55`**; menu **P** seeds vault **`v1.8.69`**.

### Notes

- `git clone` creates `merit-agent-skills` as a child of the current directory — start in the OSS bench folder.

## 0.3.54 - 2026-08-20

### Added

- **OSS device BootStrap** under `BootStrap/` (`MERIT_BootStrap.ps1` / `.cmd` / `.sh`): prereqs, `%MYMERITAPP%` bench (default `C:\MyMeritApp`), demo seed, validate, Private-Vault teaser + menu **P** seed into `~/dev` (pins vault `v1.8.68`).
- Docs: `docs/bootstrap.design.md`; BootStrap section in `docs/design.md`; Start-here row in `README.md`.
- Menu implementations for prereqs / bench skills pin / demo / OSS validate.

### Changed

- Public pin / Portal tip → **`skills-v0.3.54`** (`VERSION`, `merit.ps1`, README, HowTo, deploy, onboard/mm-upgrade skills).
- Bench clone uses tag `skills-v0.3.54` (not floating `main`).

### Notes

- Root `merit.ps1` remains the MERIT CLI. BootStrap does not replace it.
- Cold start: clone this tag → `BootStrap\MERIT_BootStrap.cmd` → menu **T**/**P** with vault GitHub credentials.

## 0.3.53 - 2026-08-17

### Changed

- Pin `merit_ux@0.1.3` in `cfg/par_pins.free.json` (status tooltip + PREVIEW PSCR).
- `apps refresh` resyncs PAR pins + play shell from SSOT (never `app_logic/`).
- UserGuide §12 usage scaffold; `cfg/usage.json` template for community baseline.

## 0.3.52 - 2026-08-13

### Added

- Webpage-shell AP-MA-13: `merit.ps1 verify` / closeout FAIL DIY `merit-ux-brand` without `createAppShell`/`createBrandShell`. Play template carries `data-webpage-shell="createAppShell"`. Smoke asserts marker. Checklist: merit-prod `docs/IAR/plans/WEBPAGE_SHELL_COMPLIANCE.md`.
