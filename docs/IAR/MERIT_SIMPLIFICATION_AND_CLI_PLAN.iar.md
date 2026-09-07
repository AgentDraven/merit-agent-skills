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
├── BootStrap/                    # temporary migration area only
├── cfg/
├── hooks/
├── skills/
├── templates/
├── scripts/
└── docs/
```

Root launchers remain stable public APIs; internal modules are not user-facing commands.

## Bootstrap and law migration

`BootStrap/_resolve.ps1`, `_oss.ps1`, and `_law.ps1` move into the appropriate Hub/MERIT modules. The new modules become authoritative. Bootstrap files remain silent compatibility shims for one release, then `BootStrap/` is removed.

Move the public law payload from `merit.blob` to `merit/merit.blob`. For one migration release, the root location is a warning-only fallback. `cfg/merit_closeout_contract.json` remains the machine-readable closeout contract. No business logic is duplicated across blob, JSON, Bootstrap, and CLI modules.

## Unified IDE installation

`merit/modules/Merit.Skills.ps1` becomes the only installer implementation. It owns host detection, install paths, safe configuration merging, hooks, receipts, enforcement classification, versions, and unsupported-host warnings.

Hub invokes:

```powershell
& "<skills-root>\merit.ps1" skills install --target <Host>
```

## `install.ps1` transition

For one compatibility release, root `install.ps1` and `install.sh` become forwarding shims that direct users to `merit.ps1 skills install`. They contain no separate implementation. In the following release they are removed, with Hub, docs, tests, and changelog updated.

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
- `install.ps1` and `install.sh` are deprecated for one compatibility release.
- `BootStrap/` is temporary migration infrastructure.
- `merit/merit.blob` becomes the canonical public law location.
- Vault delegation is explicit by command ownership.

## Phase status

| Phase | Status | Evidence |
|---|---|---|
| 1. IAR and inventory | PASS | This plan, IAR navigation link, dependency-hierarchy link; release `skills-v0.5.98` |
| 2. Root Hub launcher | PASS | Root `Merit-Hub.ps1 -Help` smoke test; implementation remains under `Merit-Hub/`; release `skills-v0.5.99` |
| 3. CLI extraction | IN PROGRESS | `merit/modules/Merit.Core.ps1` owns shared primitives; `merit.ps1 help` and `verify` parity pass; remaining command families still being extracted |
| 4. Unified IDE installer | IN PROGRESS | `merit/modules/Merit.Skills.ps1` exposes `skills list/status/install/remove`; Hub routes IDE installs through the public CLI; install implementation remains compatibility-owned |
| 5. Bootstrap migration | IN PROGRESS | `Merit.Surface.ps1` is authoritative for CLI and Hub surface loading; legacy `_resolve.ps1` remains fallback |
| 6. Law relocation | PASS | Canonical `merit/merit.blob` is authoritative; legacy root payload removed; law tests pass; release `skills-v0.5.110` |
| 7. Vault delegation | IN PROGRESS | Added explicit allow-listed `merit.ps1 vault` delegation with clear no-vault failure; live vault integration test remains pending |
| 8. Compatibility cleanup | IN PROGRESS | Canonical law references and Hub surface loading updated; installer and legacy Bootstrap shims remain until downstream callers are migrated and one compatibility release is complete |

Law migration note: the resolver now uses canonical `merit/merit.blob`; the legacy root blob has been removed after migration validation.
