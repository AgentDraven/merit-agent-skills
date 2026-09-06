# MERIT IAR Usage and Consolidation Policy

This directory is an evidence and architecture surface, not a dumping ground. Keep the active set small and use the following roles:

| File | Use | Authority |
|---|---|---|
| `MERIT_CLOSEOUT_ENFORCEMENT.iar.md` | Controlling policy, host matrix, gotchas, and promotion rules | Skills-plane authority |
| `MERIT_CLOSEOUT_ENFORCEMENT_CHECKLIST.md` | Executable validation worksheet and evidence index | Operational annex to the policy |
| `MERIT_AGENT_SKILLS_LLD_MAP.md` | Stable architecture and dependency map | Design reference |
| `MERIT_SIMPLIFICATION_AND_CLI_PLAN.iar.md` | Consolidated review baseline for CLI, Hub, Bootstrap, law payload, and vault precedence | Current implementation plan |
| `MAS-IAR-HUB-PP-*.md` | Historical Hub proof packets | Evidence only; do not duplicate policy |
| `merit_demo_cloud_recovery.iar.md` | Historical recovery handoff | Evidence only; link to current policy |

## Consolidation rules

1. Add new requirements to the controlling IAR before creating a new file.
2. Add executable rows to an existing checklist before creating another checklist.
3. A new file requires a written rationale in this README stating why an existing IAR cannot contain it.
4. A new subfolder is justified only when evidence volume or lifecycle ownership makes a flat file impractical; the subfolder must have its own README and no second authority.
5. Historical proof packets remain immutable evidence, but current status belongs in the controlling IAR.

## Vault handoff

When `merit-private-vault` and `MERIT.instructions` are activated, port this policy, the controlling contract, and the checklist as one vault IAR package. The vault version may add protected operator evidence, but must not create a parallel consumer authority.

## Status discipline

Use `OPEN`, `PASS`, `FAIL`, `BLOCKED`, or `N/A` in checklists. Keep implementation claims, evidence links, and host classifications synchronized across the controlling IAR and the consumer IAR.
