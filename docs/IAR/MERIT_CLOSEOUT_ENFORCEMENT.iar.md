# MERIT Cross-Harness Closeout Enforcement IAR

**Status:** Implemented adapters; host verification pending  
**Contract:** `cfg/merit_closeout_contract.json` (schema v2)  
**Law:** `merit.ps1 law closeout` -> `merit.ps1 closeout --path <repo>` -> release; 3-3 is `Done / State / Next`.

**Validation checklist:** [MERIT_CLOSEOUT_ENFORCEMENT_CHECKLIST.md](MERIT_CLOSEOUT_ENFORCEMENT_CHECKLIST.md). This is the required worksheet for evidence, status changes, and promotion to `HARD-ENFORCED`.

**IAR navigation and consolidation policy:** [README.md](README.md). This policy and its checklist are the only active closeout-enforcement authority; historical packets remain evidence only.

## Enforcement definitions

- **HARD-ENFORCED:** live host/mode evidence proves hook firing, failed-closeout blocking, successful rerun, recursion termination, and evidence recording.
- **SUPPORTED-BUT-VERIFY:** the host has a documented lifecycle API and MERIT adapter, but live verification is pending.
- **GUIDANCE-ONLY:** no verified lifecycle block; skills, warnings, and the release receipt gate remain active.

No host is hard-enforced because a file exists. Cursor is intentionally `SUPPORTED-BUT-VERIFY`.

## Host matrix

| Host/mode | Status | Adapter | Caveat |
|---|---|---|---|
| Cursor | SUPPORTED-BUT-VERIFY | `merit-closeout-stop.ps1` | Must prove the actual host loads and blocks it |
| VS Code Agent/Copilot | SUPPORTED-BUT-VERIFY | `vscode-merit-closeout.json` | Preview API and version volatility |
| Codex interactive TUI | SUPPORTED-BUT-VERIFY | user hooks adapter | Trust and version-specific behavior |
| Codex `exec` | GUIDANCE-ONLY | none until separately verified | Interactive results cannot be generalized |
| Claude-compatible | SUPPORTED-BUT-VERIFY | compatible schema when verified | Payload/loading differences |
| Roo/Cline/Continue | GUIDANCE-ONLY | rules/command guidance | No verified blocking adapter |
| Hermes/OpenClaw/GrokBot/Devin/Project | GUIDANCE-ONLY | warning receipt | No verified lifecycle API |

## Rationale and gotchas

Prompts, skills, and AGENTS files are advisory. Hooks can run code at a host boundary, but they may consume extra turns/credits, require trust, change under preview APIs, run in a different directory, or loop indefinitely. Runners honor `stop_hook_active`, use explicit Windows/POSIX commands, preserve malformed configs, and never commit/push/deploy/publish.

Hooks can validate repository state and inject a reminder, but cannot guarantee semantically coherent final 3-3 text. Receipts record `threeThreeValidatedBy` as `agent`, `hook`, `operator`, or `unverified`; exceptions are `WIP`, `local-only`, and `no-commit`.

## Verification gate

A host may become `HARD-ENFORCED` only after evidence proves hook firing, failed-closeout blocking, error feedback, successful rerun, recursion termination, evidence receipt, and the exact host/mode. Interactive and headless modes are separate test targets.

## Ownership and evidence write result — 2026-09-06

`merit.ps1 admin ownership status --path C:\DApps\merit-agent-skills` confirmed:

- Owner: `AgentCreator\Draven`
- Current-user Modify ACL: present
- CodexSandboxUsers Modify ACL: present
- Write probe: `PASS`
- Git safe-directory probe: `PASS`

The earlier closeout receipt used the deterministic temp fallback because the specific IAR evidence directory was not writable or available in that execution context. This was distinct from repository-root ownership. A temp fallback is valid evidence, but a future run should create and verify the repository evidence directory before treating repo-local evidence as complete.

## Changelog

- 2026-09-06: Contract v2, portable runners, VS Code adapter template, host classifications, and gotcha register added.
- 2026-09-06: IAR README added; checklist designated as an operational annex rather than a second authority.
