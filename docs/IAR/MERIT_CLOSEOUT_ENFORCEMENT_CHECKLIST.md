# MERIT Closeout Enforcement Validation Checklist

**Authority:** `MERIT_CLOSEOUT_ENFORCEMENT.iar.md`  
**Purpose:** executable checklist for upgrading a host/mode from `SUPPORTED-BUT-VERIFY` to `HARD-ENFORCED`, or recording `GUIDANCE-ONLY`.  
**Rule:** do not claim hard enforcement from configuration presence alone.

## Status values

- `OPEN` — not tested.
- `PASS` — evidence attached and independently reproducible.
- `FAIL` — test ran and enforcement did not meet the criterion.
- `BLOCKED` — environment/tool limitation prevented the test.
- `N/A` — explicitly not applicable, with rationale.

## Evidence convention

Store command output, hook input/output, screenshots, and receipts under:

`<repo>\docs\IAR\evidence\closeout-enforcement\<host>\<mode>\`

Required receipts include `.merit-hook-install.json`, hook logs, `closeout-validation.json`, and the final 3-3 response evidence where the host exposes it.

## Gate 0 — Contract and runner readiness

| ID | Check | Command/action | Expected | Evidence | Status | Remediation |
|---|---|---|---|---|---|---|
| CE-0001 | Contract parses | `Get-Content cfg/merit_closeout_contract.json -Raw \| ConvertFrom-Json` | JSON parses; schema v2; 3-3 required | contract output | OPEN | Repair contract |
| CE-0002 | Law prints | `pwsh .\merit.ps1 law closeout` | Binding sequence and 3-3 requirement shown | law transcript | OPEN | Repair law pack |
| CE-0003 | Local validation writes receipt | `pwsh .\merit.ps1 closeout --path <repo>` | Exit 0 and `closeout-validation.json` | receipt | OPEN | Repair repo or ACL |
| CE-0004 | Release gate rejects stale/missing receipt | Run `ship` against a controlled fixture | Release refused | command transcript | OPEN | Repair gate |
| CE-0005 | Windows runner parses | PowerShell parser check on `hooks/merit-closeout.vscode.ps1` | No parse errors | parser output | OPEN | Repair runner |
| CE-0006 | POSIX runner syntax | `bash -n hooks/merit-closeout.sh` | Exit 0 | command output | OPEN | Repair runner |

## Host checklist template

Complete one copy of this table for every host and mode. Do not combine interactive and headless evidence.

| ID | Host/mode | Check | Command/action | Expected | Evidence path | Status | Remediation |
|---|---|---|---|---|---|---|---|
| CE-H01 | `<host>/<mode>` | Installation receipt | Run installer; inspect `.merit-hook-install.json` | Correct adapter, event, mode, classification, timestamp | `<evidence>/install.json` | OPEN | Reinstall or fix metadata |
| CE-H02 | `<host>/<mode>` | Hook configuration loads | Restart host; inspect host hook/debug log | Hook is discovered without config error | `<evidence>/load.txt` | OPEN | Fix path/schema/feature flag |
| CE-H03 | `<host>/<mode>` | Hook fires | Trigger a harmless test turn | Hook log contains event and session id | `<evidence>/fire.jsonl` | OPEN | Fix event registration |
| CE-H04 | `<host>/<mode>` | Failed closeout blocks | Use fixture with intentional validation failure | Agent cannot finish; receives remediation | `<evidence>/blocked.txt` | OPEN | Fix exit/output contract |
| CE-H05 | `<host>/<mode>` | Passing rerun completes | Repair fixture and rerun | Agent can complete after validation passes | `<evidence>/pass.txt` | OPEN | Fix continuation behavior |
| CE-H06 | `<host>/<mode>` | Recursion guard | Reproduce a blocked stop twice | No infinite continuation; guard is recorded | `<evidence>/recursion.txt` | OPEN | Honor `stop_hook_active` |
| CE-H07 | `<host>/<mode>` | Evidence receipt | Inspect repository evidence | Hook/validation receipt exists or fallback is explained | `<evidence>/receipts/` | OPEN | Fix write path/ACL |
| CE-H08 | `<host>/<mode>` | 3-3 limitation recorded | Inspect final response/evidence | `Done / State / Next` requirement is recorded; semantic validation claim is absent unless supported | `<evidence>/three-three.txt` | OPEN | Update guidance/receipt |
| CE-H09 | `<host>/<mode>` | Existing config preserved | Install with unrelated valid hooks | Unrelated hooks remain byte/semantically intact | `<evidence>/merge.json` | OPEN | Fix safe merge |
| CE-H10 | `<host>/<mode>` | Malformed config preserved | Install with malformed hook file | Installer refuses merge and preserves original | `<evidence>/malformed.txt` | OPEN | Fail closed |
| CE-H11 | `<host>/<mode>` | OS/path behavior | Run from repository and non-repository cwd | Correct repo resolution or actionable warning | `<evidence>/path.txt` | OPEN | Fix path handling |
| CE-H12 | `<host>/<mode>` | Credit/preview warning | Inspect install and failure output | Preview/trust/credit caveats visible | `<evidence>/warnings.txt` | OPEN | Add warning |

## Host-specific execution cards

### Cursor

Run the host interactively with the installed Cursor hook. Prove CE-H02 through CE-H08. Until all pass, retain `SUPPORTED-BUT-VERIFY`.

### VS Code Agent/Copilot

Open the project with `.github/hooks/merit-closeout.json`. Confirm preview hook loading, Windows/POSIX command selection, and `Stop` blocking. Prove CE-H02 through CE-H12. Record VS Code version and whether hooks are enabled by policy.

### Codex interactive TUI

Install the user hook configuration, enable the required hook feature if prompted, approve trust, and test in an interactive TUI session. Prove CE-H02 through CE-H08 and record Codex version.

### Codex `exec`

Run the same fixture in headless mode. Until Stop-hook firing and blocking are independently proven, mark `GUIDANCE-ONLY`; do not reuse interactive evidence.

### Guidance-only hosts

Confirm `.merit-hook-warning.json`, law/3-3 skill guidance, and release-gate behavior. Mark CE-H02–CE-H06 `N/A` with the reason “no verified lifecycle API,” and retain `GUIDANCE-ONLY`.

## Promotion rule

A host/mode may be promoted to `HARD-ENFORCED` only when CE-0001–CE-0006 and CE-H01–CE-H08 are `PASS`, CE-H09–CE-H12 are `PASS` or explicitly accepted `N/A`, and the evidence directory is linked from the controlling IAR. Any `BLOCKED`, missing evidence, or unverified mode keeps the prior classification.

## Closeout record

| Host/mode | Final classification | Test date/version | Evidence index | Reviewer | Notes |
|---|---|---|---|---|---|
| Cursor | SUPPORTED-BUT-VERIFY | — | — | — | — |
| VS Code Agent/Copilot | SUPPORTED-BUT-VERIFY | — | — | — | Preview |
| Codex interactive TUI | SUPPORTED-BUT-VERIFY | — | — | — | — |
| Codex `exec` | GUIDANCE-ONLY | — | — | — | Separate mode |
| Claude-compatible | SUPPORTED-BUT-VERIFY | — | — | — | — |

## Changelog

- 2026-09-06: Initial executable host/mode checklist created.
