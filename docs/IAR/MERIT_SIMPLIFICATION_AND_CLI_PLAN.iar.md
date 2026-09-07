# MERIT Simplification, Unified CLI, Bootstrap, and Vault Precedence Plan

**Status:** Implementation in progress; this IAR remains the controlling simplification plan.

## Goal

Make MERIT easy for new users while preserving two stable public entrypoints:

```powershell
.\Merit-Hub.ps1       # new-laptop setup
.\merit.ps1           # project and day-to-day work
```

IDE installation becomes a `merit.ps1` module. Hub calls that module instead of carrying duplicate installer logic.

## Public command model

```powershell
.\Merit-Hub.ps1
.\merit.ps1 verify
.\merit.ps1 e2e
.\merit.ps1 deploy
.\merit.ps1 portal
.\merit.ps1 closeout
.\merit.ps1 skills list
.\merit.ps1 skills status
.\merit.ps1 skills install --target Cursor
.\merit.ps1 skills remove --target Cursor
```

Direct skill installation requires an explicit target. Hub supplies the target after interactive selection.

## Target structure

```text
merit-agent-skills/
├── Merit-Hub.ps1                 # root first-time launcher
├── merit.ps1                     # root public CLI dispatcher
├── merit.sh
├── merit/
│   ├── merit.blob                # canonical OSS law payload
│   └── modules/
│       ├── Merit.Paths.ps1
│       ├── Merit.Config.ps1
│       ├── Merit.Output.ps1
│       ├── Merit.Git.ps1
│       ├── Merit.Law.ps1
│       ├── Merit.Closeout.ps1
│       ├── Merit.Admin.ps1
│       ├── Merit.Cloud.ps1
│       ├── Merit.Scaffold.ps1
│       └── Merit.Skills.ps1
├── Merit-Hub/
│   ├── README.md
│   └── modules/
│       ├── Hub.Bootstrap.ps1
│       ├── Hub.Menu.ps1
│       ├── Hub.Surface.ps1
│       ├── Hub.Install.ps1
│       ├── Hub.Cleanup.ps1
│       └── Hub.Prerequisites.ps1
├── BootStrap/                    # Hub compatibility internals; removal pending caller migration
├── cfg/
├── hooks/
├── skills/
├── templates/
├── scripts/
└── docs/
```

Root launchers remain stable public APIs; internal modules are not user-facing commands.

## Bootstrap and law migration

`merit/modules/Merit.SurfaceImpl.ps1`, `_oss.ps1`, and `_law.ps1` move into the appropriate Hub/MERIT modules. The new modules become authoritative. Bootstrap files remain silent compatibility shims for one release, then `BootStrap/` is removed.

Move the public law payload from `merit.blob` to `merit/merit.blob`. For one migration release, the root location is a warning-only fallback. `cfg/merit_closeout_contract.json` remains the machine-readable closeout contract. No business logic is duplicated across blob, JSON, Bootstrap, and CLI modules.

## Unified IDE installation

`merit/modules/Merit.Skills.ps1` becomes the only installer implementation. It owns host detection, install paths, safe configuration merging, hooks, receipts, enforcement classification, versions, and unsupported-host warnings.

Hub invokes:

```powershell
& "<skills-root>\merit.ps1" skills install --target <Host>
```

## Installer transition

The root `merit.ps1 skills install` and `merit.sh skills install` wrappers have now been removed. The canonical command is `merit.ps1 skills install`; implementation lives in `merit/modules/Merit.SkillsInstall.ps1`.

## Vault precedence

The public CLI is never blindly replaced by the vault CLI. The resolver checks `MERIT_VAULT_ROOT`, the MERIT surface map, and the standard sibling vault location, then reports the active plane and CLI paths.

| Command | No vault | Vault present |
|---|---|---|
| `init`, `apply`, `verify`, `create` | Public OSS | Public OSS |
| `e2e`, `deploy`, `portal`, `apps` | Public OSS | Public OSS unless operator-scoped |
| `law` | Public blob | Public law unless explicitly vault-requested |
| `closeout` | Public OSS release | Vault policy for vault-owned repos |
| `mXin`, `mXout`, `runtime`, `env`, `cert` | Clear unavailable message | Delegate to vault |
| `where`, `surface` | OSS surface | Combined OSS/vault surface |
| `admin ownership` | Public CLI | Public CLI |

## Closeout requirements

`merit.ps1 closeout` validates, checks intended files and secrets, requires `VERSION` and `CHANGELOG`, commits, pushes, tags, emits a receipt, and emits 3-3. The receipt records `plane`, `publicCli`, `vaultCli`, `delegated`, `delegationReason`, `version`, `tag`, and `branch`. Exceptions are explicit: `WIP`, `local-only`, and `no-commit`.

## Documentation consolidation

Primary public docs remain `README.md`, `docs/howto/launch-over-dinner.md`, `docs/usage.md`, `docs/deploy.md`, and `Merit-Hub/README.md`.

Architecture/IAR authority remains `docs/design.md`, `docs/IAR/README.md`, `MERIT_AGENT_SKILLS_LLD_MAP.md`, `MERIT_DEPENDENCY_HIERARCHY.iar.md`, `MERIT_CLOSEOUT_ENFORCEMENT.iar.md`, and its checklist. Candidate merges are bootstrap design/pathway into design/usage, surface matrix into design, and beginner bundle content into the dinner guide. Historical proof packets remain immutable evidence.

## IAR updates

This file is the consolidated implementation plan. `docs/IAR/README.md` must list it as the review baseline. `MERIT_DEPENDENCY_HIERARCHY.iar.md` must link here and carry the final wrapper, module, law, vault, and closeout rules. `AGENTS.md` must say to use root launchers, never call internal modules directly, use `merit.ps1 skills install`, and report the active plane during closeout.

## Phased implementation

1. Write this IAR and inventory callers; no behavior change.
2. Add root `Merit-Hub.ps1` launcher.
3. Extract `merit.ps1` into modules while preserving syntax, output, and exit codes.
4. Add `skills list/status/install/remove` and route Hub through it.
5. Migrate Bootstrap helpers into modules with one-release shims.
6. Move the law payload to `merit/merit.blob` with temporary fallback.
7. Add explicit vault command delegation and test no-vault, OSS+vault, and vault-only contexts.
8. Remove `BootStrap/`, installer shims, and law fallback after compatibility releases.
9. Run release closeout and 3-3 for each phase release.

## Acceptance tests

- Root `Merit-Hub.ps1` works from a clean clone and preserves Windows PowerShell 5.1/PowerShell 7 behavior.
- `merit.ps1 help` and all existing public commands remain compatible.
- Skill installation works through the shared module and Hub delegation.
- `merit/merit.blob` is authoritative; legacy fallback only warns.
- No-vault commands never call vault scripts; vault commands delegate only when appropriate.
- Closeout records plane, CLI, version, branch, tag, and delegation.
- Beginner docs mention only root launchers.
- Every phase passes version/changelog, commit, push, tag, receipt, and 3-3 checks.

## Assumptions

- Root `Merit-Hub.ps1` and `merit.ps1` are permanent public APIs.
- Internal modules are not user commands.
- `merit.ps1 skills install --target <Host>` is canonical.
- The legacy installer wrappers are removed; use `merit.ps1 skills install`.
- `BootStrap/` is temporary migration infrastructure.
- `merit/merit.blob` becomes the canonical public law location.
- Vault delegation is explicit by command ownership.

## Phase status

| Phase | Status | Evidence |
|---|---|---|
| 1. IAR and inventory | PASS | This plan, IAR navigation link, dependency-hierarchy link; release `skills-v0.5.98` |
| 2. Root Hub launcher | PASS | Root `Merit-Hub.ps1 -Help` smoke test; implementation remains under `Merit-Hub/`; release `skills-v0.5.99` |
| 3. CLI extraction | IN PROGRESS | `merit/modules/Merit.Core.ps1` owns shared primitives; `merit.ps1 help` and `verify` parity pass; remaining command families still being extracted |
| 4. Unified IDE installer | PASS | Implementation moved to `merit/modules/Merit.SkillsInstall.ps1`; root wrappers removed; install/remove/reinstall acceptance passed; release `skills-v0.5.123` |
| 5. Bootstrap migration | PASS | OSS/law/surface helpers moved into `merit/modules`; templates moved into `cfg`; Hub smoke, law, surface, and verify tests pass; `BootStrap/` removed |
| 6. Law relocation | PASS | Canonical `merit/merit.blob` is authoritative; legacy root payload removed; law tests pass; release `skills-v0.5.110` |
| 7. Vault delegation | PASS | Clean AgentDraven vault checkout at `C:\DApps\merit-private-vault`; allow-listed delegation and `mXin --help` live test pass; vault tree unchanged; surface now reports `oss+ide+vault`; release `skills-v0.5.120` |
| 8. Compatibility cleanup | IN PROGRESS | Root installer wrappers and `BootStrap/` removed; remaining documentation references require cleanup and final consumer review |

Law migration note: the resolver now uses canonical `merit/merit.blob`; the legacy root blob has been removed after migration validation.

## Implementation result and acceptance record

This section records what was actually implemented and tested, rather than leaving the plan as prose-only intent.

### Release trail

| Release | Result |
|---|---|
| `skills-v0.5.98` | IAR baseline and inventory established |
| `skills-v0.5.99` | Root `Merit-Hub.ps1` launcher released |
| `skills-v0.5.100`–`skills-v0.5.108` | Shared CLI core helpers extracted |
| `skills-v0.5.109`–`skills-v0.5.110` | Canonical law payload migration completed |
| `skills-v0.5.111`–`skills-v0.5.114` | Law/surface compatibility modules and IAR status updates released |
| `skills-v0.5.115` | Explicit allow-listed vault delegation released |
| `skills-v0.5.116`–`skills-v0.5.117` | Compatibility documentation and guarded skill removal released |
| `skills-v0.5.118`–`skills-v0.5.123` | Installer implementation moved to `merit/modules/Merit.SkillsInstall.ps1`; root wrappers then removed |
| `skills-v0.5.119` | Read-only AgentDraven vault checkout and sibling discovery released |
| `skills-v0.5.120` | Surface vault display fix and final acceptance release |

### Acceptance evidence

| Check | Result | Evidence |
|---|---|---|
| Law pack tests | PASS | `scripts/test-merit-law.ps1`: 9 passed, 0 failed |
| Surface tests | PASS | `scripts/test-merit-surface.ps1`: 6 passed, 0 failed |
| Skills repository verify | PASS | `merit.ps1 verify --path .` |
| CLI skill install | PASS | `merit.ps1 skills install --target Cursor` |
| Canonical skills installer | PASS | `merit.ps1 skills install --target Cursor` |
| Guarded skill removal | PASS | `merit.ps1 skills remove --target Cursor --yes` |
| Vault discovery display | PASS | `merit.ps1 where` reports `oss+ide+vault` and `C:\DApps\merit-private-vault` when configured |
| Vault delegation | PASS | `merit.ps1 vault mXin --help` delegates to the read-only checkout |
| Vault mutation safety | PASS | `git status --short` remains clean in `C:\DApps\merit-private-vault` |
| Consumer verify | PASS | `C:\DApps\merit-demo\merit.ps1 verify --path .` |
| Consumer static E2E | PASS | `merit-demo` E2E smoke completed successfully |
| Consumer Playwright E2E | PASS | Routes, Hosted Ready, mount, Register, mobile/desktop screenshots, provider checks |
| Release closeout | PASS | Latest commit `57e03c7`, tag `skills-v0.5.120`, main pushed |

### Final operating boundary

The implementation now has one public CLI, a root Hub launcher, a canonical law payload, shared skill installation/removal, explicit vault delegation, and recorded acceptance evidence. `BootStrap/` remains only as an internal Hub compatibility surface until its active callers are migrated; it is not a second user-facing product.

Closeout evidence receipts are currently written to the deterministic temporary fallback under `C:\Users\Draven\AppData\Local\Temp\merit-closeout\...` because the repository evidence directory is not writable in this environment. This is an evidence-storage limitation, not a validation failure.

## Document-sprawl guardrail

### MAS-HUB-URI-01 — launcher diagnosis correction and regression proof (0.5.178)

The reported `Invalid URI: The hostname could not be parsed` came from
`"$url?v=$cacheBust"`: PowerShell parses `url?v` as the variable name. With an
unset variable and nonce `123`, the expression evaluates to `=123`. Reproduced
with AST variable inspection and evaluation on Windows PowerShell 5.1.26100.9168
and PowerShell 7.6.5. The previous claims that plain URLs in the screenshot were
Markdown-wrapped, that the filename `Merit-Hub-B.ps1` caused failure, or that
PowerShell 5.1 cannot use query strings were incorrect. `${url}?v=123` is valid;
the shipped downloader uses a direct URI and no-cache header instead.

The root launcher now announces revision 0.5.178 before network activity,
always refreshes, reads the skills pin from the actual downloaded script,
stages and parses UTF-8-with-BOM before replacement, and stops on download or
parse failure without executing a cached copy. The Hub's OCV downloader also
uses a direct URI; there is no `$url?v` request expression in either launcher.

Acceptance results: `scripts/test-hub-launcher.ps1` passed on both hosts for
fresh download, refresh, preserved arguments, and network/HTML/syntax rejection
with old-file preservation and no stale execution. `-LiveDownload` passed
against GitHub on Windows PowerShell 5.1 (downloaded Hub 0.5.177 before release,
UTF-8 BOM and parser verified). The fixture exercises child invocation; the live
check intentionally does not start the interactive Hub or publish an OC app.

Repeat with `powershell.exe -NoProfile -File scripts/test-hub-launcher.ps1`
and add `-LiveDownload` for GitHub transport and parse verification. Replace the
root launcher once on affected devices; deleting only its child folder leaves
the faulty expression in the root launcher. Current CompatSet: 0.5.178.

### MAS-HUB-ID-01 — release identity alignment (0.5.179)

**Verdict: the earlier `script-version=0.5.138` beside
`MERIT launcher 0.5.178` was harmless to execution but unacceptable as a
beginner-facing receipt.** They are distinct layers: the root launcher obtains
the Hub, the Hub is the running menu, and the CompatSet pin is the payload that
Hub 2 installs. They may differ only when an advanced user deliberately selects
an approved rollback through **K**.

Default release rule: launcher revision = Hub revision = repository `VERSION`;
the first supported CompatSet and new `oss-bench.json` template use
`skills-v<VERSION>`. Hub now prints an explicit aligned/mismatch verdict and
explains the only expected divergence (an approved K rollback). A mismatch
requires refreshing the root launcher and rerunning Hub 2 before relying on
the default documentation or installed payload.

Acceptance: `scripts/test-hub-launcher.ps1` asserts all five identity links
(root launcher, Hub menu, Hub payload, first CompatSet, and bench template)
under both PowerShell hosts, in addition to launcher transport recovery tests.

### MAS-HUB-ID-02 — one public release label (0.5.180)

**Decision:** beginner-facing Hub output uses one release label only:
`MERIT Skills <VERSION>`. The matching `skills-v<VERSION>` is Git tag syntax,
not a parallel product version. `hubVersion` is deprecated and removed;
file-write timestamps, vault pins, portable-PowerShell versions, component
pins, and the obsolete vault CompatSet date are not release labels and must not
appear on the normal menu path.

The only intentional exception is menu **K**. It can select a supported older
CompatSet for a session, and only then Hub says that an approved alternate
payload is active. A Hub release that differs from repository `VERSION` is a
real update warning: refresh the root launcher and rerun Hub 2. The regression
suite continues to require launcher, Hub release, default payload, CompatSet,
and bench-template alignment.

### MAS-HUB-UX-01 — concise default, diagnostic opt-in (0.5.181)

Hub's default output is limited to the current release, action outcome,
failure/recovery notices, concise menu, and next action. `-Verbose` is the
standard PowerShell diagnostic switch; `-v` is the equivalent Hub shortcut.
Verbose output adds paths, environment scopes, full map, drill-ins, transcript
metadata, and other details needed for support without making a first run feel
like a log dump. Relaunch arguments preserve the requested level.

## NextRel FR — README three-step explainability (Peel-The-Onion)

**Peel-The-Onion** is the MERIT teaching model: reveal the smallest useful action first, then progressively expose evidence and advanced detail. A beginner can pause after any layer with a clear success signal.

**FR-NEXTREL-README-3X3 (B; feeds L1 `MERIT.instructions` when the vault is
available):** Every beginner-facing pathway in a README must use the same
three-column pattern: **1. Start → 2. Make progress → 3. Finish**. Under each
column, provide at least three concrete sub-bullets describing what the user,
Hub, and hosted system do. The row/table, detailed bullets, and diagram must
cross-link to one another. A one-line command summary alone is insufficient.

Acceptance: a new user can follow any persona row without guessing the next
action, and each step names its command, expected result, and evidence.

**Porting note:** add this FR to vault L1 `MERIT.instructions` and regenerate
the canonical `merit.blob` from the law-pack source during the vault merge.

This IAR is the single controlling plan for CLI simplification, Hub/Bootstrap migration, law placement, installer ownership, vault precedence, implementation status, and acceptance results. New findings and future-release requirements must be added as sections or tables here unless the existing IAR index explicitly approves a separate artifact.

The active IAR set is intentionally small:

1. `MERIT_SIMPLIFICATION_AND_CLI_PLAN.iar.md` — implementation and acceptance authority.
2. `MERIT_CLOSEOUT_ENFORCEMENT.iar.md` — cross-harness closeout policy.
3. `MERIT_CLOSEOUT_ENFORCEMENT_CHECKLIST.md` — executable enforcement checklist.
4. `MERIT_DEPENDENCY_HIERARCHY.iar.md` — cross-repository ownership map.
5. `MERIT_AGENT_SKILLS_LLD_MAP.md` — stable architecture reference.

Historical proof packets remain evidence only. A new IAR or checklist requires a written rationale in `docs/IAR/README.md`; otherwise, consolidate into one of the files above.

## Root Hub launcher contract

`Merit-Hub.ps1` at repository root is the stable first-touch launcher. When the full clone is present, it forwards to `Merit-Hub/Merit-Hub.ps1`. When downloaded alone, it creates the adjacent `Merit-Hub/` folder, downloads the pinned implementation from the public repository, and then forwards all arguments. The implementation owns prerequisite checks and reports missing `pwsh`, `git`, or `gh`; the root launcher does not duplicate that logic. A standalone smoke test passed from `C:\Temp\merit-hub-root-smoke`.

`Merit-Hub/oc-bench.ps1` remains an advanced multi-creator bench utility. It is not part of the beginner path and should be linked only from advanced Hub documentation.

The Hub prerequisite contract now covers Windows portable PowerShell and POSIX package-manager installation. POSIX installation is opt-in, package-manager detected, and followed by a re-launch under `pwsh`; unsupported systems receive platform guidance instead of a silent failure.
