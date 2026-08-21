## Unreleased

### Added

- **OSS device BootStrap** under `BootStrap/` (`MERIT_BootStrap.ps1` / `.cmd` / `.sh`): prereqs, `%MYMERITAPP%` bench (default `C:\MyMeritApp`), demo seed, validate, Private-Vault teaser + menu **P** seed into `~/dev`.
- Docs: `docs/bootstrap.design.md`; BootStrap section in `docs/design.md`; Start-here row in `README.md`.

### Notes

- Root `merit.ps1` remains the MERIT CLI. BootStrap does not replace it.
- One-time land from detached tag checkout → branch `bootstrap/oss-bootstrap` (see `docs/bootstrap.design.md`).

## 0.3.53 - 2026-08-17

### Changed

- Pin `merit_ux@0.1.3` in `cfg/par_pins.free.json` (status tooltip + PREVIEW PSCR).
- `apps refresh` resyncs PAR pins + play shell from SSOT (never `app_logic/`).
- UserGuide §12 usage scaffold; `cfg/usage.json` template for community baseline.

## 0.3.52 - 2026-08-13

### Added

- Webpage-shell AP-MA-13: `merit.ps1 verify` / closeout FAIL DIY `merit-ux-brand` without `createAppShell`/`createBrandShell`. Play template carries `data-webpage-shell="createAppShell"`. Smoke asserts marker. Checklist: merit-prod `docs/IAR/plans/WEBPAGE_SHELL_COMPLIANCE.md`.
