# merit-agent-skills — design

`merit-agent-skills` is the free public skills package for attracting new builders into the MERIT ecosystem.

## Maniacal focus

This repo owns:

- Public skill instructions.
- Public templates.
- The single public command surface: `merit.ps1` / `merit.sh`.
- The “3 Steps Over Dinner” onboarding path.

This repo does not own:

- Running production provider code.
- Billing or usage-metering source.
- Vault registries or private operator policy.
- Consumer-specific portal implementations.

## Command surface

Use one command family:

| Command | Purpose |
|---|---|
| `merit init` | Create `.merit_launch.md` and protect local files |
| `merit apply` | Generate local machine files from `.merit_launch.md` |
| `merit verify` | Validate the local MERIT scaffold |
| `merit deploy` | Apply, Vercel-link when needed, and production deploy |
| `merit portal` | Publish configured portal surfaces when here.now credentials exist |
| `merit closeout` | Verify, run git whitespace hygiene, print baseline |

Legacy `merit-live` and `merit-*` shim scripts are intentionally not part of the GA surface.

## Provider boundary

The public skills call hosted MERIT providers through `https://merit-prod.vercel.app`. Public clones must not ship local usage-metering or Square billing bypass logic.

The default promo path is `MERITAGENT`; the hosted provider owns credit budget, entitlement, Square configuration, and tenant separation.
