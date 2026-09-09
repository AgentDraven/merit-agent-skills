# MERIT with `merit.ps1`

This is the friendly first guide for students, families, and new builders. MERIT helps you try a small app, check your work, and share it when you are ready. You can start without knowing Git, servers, Vercel, databases, or private operator tools.

Use the Hub for the first visit. Use `merit.ps1` when you want a named command. The Hub and the CLI use the same public `merit-agent-skills` release.

## The three-step journey

Every pathway uses **Start → Make progress → Finish**. Read the evidence line before moving on.

### Start: open MERIT

- **You do:** download `Merit-Hub.ps1`, open PowerShell, and run `./Merit-Hub.ps1` from its folder.
- **MERIT does:** checks the laptop and offers `1` to set up folders, then `2` to install the pinned free tools.
- **Look for:** a receipt showing the tools folder, the selected release, and any setup warning. Choose `0` only when you want to stop.

### Make progress: try a local app

- **You do:** choose `3` in the Hub, or run `./merit.ps1 serve` from a consumer folder.
- **MERIT does:** reuses the local demo, starts an HTTP server, and opens `/play/`.
- **Look for:** **Hosted Ready**, a mounted workbench, working navigation, and a local URL such as `http://localhost:3000/play/`. Use HTTP; opening HTML with `file://` skips the normal server checks.

### Finish: validate and share

- **You do:** run the Hub's `3V` check. When the local proof is good, choose `OC` and then `OCV` for hosted validation.
- **MERIT does:** checks routes, records URLs, and keeps the provider profile visible in the receipt.
- **Look for:** a passing verification receipt, a hosted `/play/` page, and a working **Register free** link before inviting another person.

## Pick a persona

- **Learner:** Hub `1 → 2 → 3`, then read the local `/play/` page.
- **Builder:** `./merit.ps1 init --path ../my-app`, edit `.merit_launch.md`, then `apply` and `verify`.
- **Tester:** run `verify`, `e2e`, or Hub `3V`; save the receipt and screenshots when a check fails.
- **Publisher:** run `OC` after local checks, or use `deploy`/`portal` with your own credentials for a consumer you own.
- **Caretaker:** run `where`, `version`, `ecosystem list`, and `closeout --validate-only` before changing a release.

## Command map

Start with `./merit.ps1 help`. The usual commands are grouped below.

### Learn

- `help`, `version`, and `where` explain the installed CLI, version, and active paths.
- `ecosystem list` shows the provider profiles available to this release.
- `ecosystem use <id> --path <consumer>` selects a profile for one consumer; use `--allow-nonlive` only when deliberately testing a profile that is not live.

### Build

- `init --path <consumer>` creates a small launch profile.
- `apply --path <consumer>` applies that profile.
- `par scaffold` and `subs scaffold` add the optional public workbench or subscription example.
- `create --path <consumer>` creates a new Cloud First consumer when its required account details are available.

### Check

- `verify --path <consumer>` checks the consumer files and configuration.
- `serve --path <consumer>` starts the local HTTP proof.
- `e2e --path <consumer>` runs the optional browser checks when Playwright is installed.
- `e2e:playwright` is the explicit browser route used by the full demo check.

### Publish

- `deploy --path <consumer>` deploys a consumer through its chosen provider flow.
- `portal --path <consumer>` publishes only `portal/` through your own BYOK account.
- `all --path <consumer>` runs the supported publish sequence when its prerequisites are present.
- Hub `OC` is the guided public demo route; Hub `OCV` checks the hosted result.

### Finish and maintain

- `closeout --validate-only` checks release evidence without publishing.
- `closeout` runs the consumer release gate after the required checks pass.
- `apps refresh` and `apps remove --yes` maintain optional app integrations. Read the prompt carefully before removal.
- `law`, `vault`, and `admin` are operator or policy paths. They are not needed for a first student journey.

For every command, use this pattern: **you choose an action → MERIT prints what it did → you check the receipt or URL**.

## Provider profiles

The default public provider is **v00** at `https://merit-prod.vercel.app`. The release may also list **v01** at `https://merit-prodv01.vercel.app`; it is selectable only when its profile is marked live, unless you explicitly pass `--allow-nonlive` for testing. The guide and the CLI do not hardcode a consumer's identity. A consumer chooses its provider profile locally, and the provider owns registration and hosted behavior.

Check before a hosted run:

```powershell
./merit.ps1 ecosystem list
./merit.ps1 ecosystem use v00 --path ../my-app
```

Switching is per consumer. The default remains v00 until the provider publishes a live v01 profile.

## Safety and paths

- Run `./merit.ps1` from the public skills checkout, or use the installed copy selected by the Hub.
- Use `./merit.ps1 where` to discover the active app and tools folders; do not assume `C:\MyMeritApp`.
- Keep consumer settings in the consumer repository. Do not put consumer IDs, secrets, or private provider data into this generic skills repository.
- Never commit `.env.local`, credentials, or generated receipts that contain secrets.
- Use `--yes` only for a deliberate destructive action such as `apps remove`.

## When a check fails

Run `help`, then `where`, then `verify`. Read the first failing line in the receipt. A local URL proves the local consumer path; an `OCV` receipt is needed for a hosted claim. If a provider profile is not live, leave the default on v00 and report the profile status instead of bypassing the gate.

## More help

- [MERIT public README](../README.md) — the visual adventure map.
- [Merit-Hub guide](../Merit-Hub/README.md) — menu keys and receipts.
- [Full usage guide](usage.md) — accounts, hosting, and command detail.
- [Build over dinner](howto/launch-over-dinner.md) — a guided creative exercise.
- [Try bundles](TRY_BUNDLES.md) — choose a route by outcome.

## Ready checklist

You are ready to show a first alpha when you can:

1. start the Hub and reach `/play/` over HTTP;
2. run `verify` and save a passing receipt; and
3. explain whether your evidence is local (`3V`) or hosted (`OCV`).
