# MERIT CLI student guide

**Document ID:** MAS-DOC-CLI-001
**Audience:** Students, families, first-time builders, and classroom mentors
**Surface:** Public `merit-agent-skills` Hub and CLI
**Owner:** `merit-agent-skills`

MERIT gives you a safe path from a first local app to a checked hosted demo. You can start without Git, Vercel, databases, or private operator tools. The Hub is the easiest first step; `merit.ps1` is the named command surface when you want to build or check your own consumer.

<a id="choose-a-path"></a>
<table><tr><td bgcolor="#1f6feb"><strong><big>🧭 Choose a path</big></strong></td></tr></table>

> Choose one row and read from **Start** to **Make progress** to **Finish**. The evidence column tells you what must be visible before you continue.

| Persona | Start | Make progress | Finish | Evidence |
|---|---|---|---|---|
| **Learner** | Run `Merit-Hub.ps1`; choose **Set up this laptop** (`1`), then **Get the free MERIT tools** (`2`) | Choose **Try it** (`3`) to open the demo | Run **Validate my local demo** (`3V`) | Local `/play/` over HTTP, **Hosted Ready**, and a receipt |
| **Builder** | `merit.ps1 init --path <consumer>` | Edit `.merit_launch.md`; run `apply` | Run `verify` | Consumer config and `verify OK` |
| **Tester** | Resolve the repo with `where` | Run `verify`, `e2e`, and browser E2E | Save the failing or passing receipt | Expected result, observed result, and remediation |
| **Publisher** | Pass local checks | Run `oc`, `deploy`, `portal`, or `all` as applicable | Run hosted `OCV` from the Hub | Hosted URL and provider profile are recorded |
| **Caretaker** | Run `version` and `ecosystem list` | Review the release pin and evidence | Run `closeout --validate-only` | Release version, tag, and validation receipt |

<a id="first-trip"></a>
<table><tr><td bgcolor="#0d9488"><strong><big>🚀 First trip: Set up → Install → Try → Validate</big></strong></td></tr></table>

### Start — prepare the laptop

1. Download the [Hub script](../Merit-Hub/Merit-Hub.ps1) to a tools folder such as `C:\Tools`.
2. Open PowerShell in that folder and run:

   ```powershell
   .\Merit-Hub.ps1
   ```

3. Choose **Set up this laptop** (`1`), then **Get the free MERIT tools** (`2`).

The Hub checks the laptop, installs the tested public skills release, and writes a receipt. The receipt must identify the tools path and release pin. `0` exits the Hub.

### Make progress — open the demo

Choose **Try it** (`3`). The Hub reuses the selected consumer folder, starts the local HTTP path, and opens `/play/`.

Look for:

- a URL beginning with `http://`, not `file://`;
- **Hosted Ready** and a mounted workbench; and
- a visible **Register free** route or a labeled fallback state.

### Finish — validate the local proof

Choose **Validate my local demo** (`3V`). The Hub checks the page, routes, and configured public rails and records the result.

> `3V` proves the local consumer path. It does not prove that a hosted deployment is live.

When the local receipt passes, choose **OSS in Cloud** (`OC`) and then **Walk through my hosted demo** (`OCV`). The hosted walkthrough is the evidence for a hosted claim.

<a id="build-your-own"></a>
<table><tr><td bgcolor="#0d9488"><strong><big>🛠️ Build your own consumer</big></strong></td></tr></table>

Run these commands from the `merit-agent-skills` checkout. Replace `<consumer>` with the path to your own repository.

| Step | Command | What you do | What MERIT does | Evidence |
|---|---|---|---|---|
| Start | `.\merit.ps1 init --path <consumer>` | Choose your consumer folder | Creates `.merit_launch.md` and protects it with gitignore | Launch profile exists |
| Make progress | `.\merit.ps1 apply --path <consumer>` | Review the generated settings | Generates the consumer config and local environment template | Files are present; secrets are still local |
| Finish | `.\merit.ps1 verify --path <consumer>` | Read each check | Validates the public scaffold | `verify OK` and no unexplained failure |

For a guided Cloud First scaffold, use:

```powershell
.\merit.ps1 create --path <consumer> --profile fullstack-consumer
```

Use `par scaffold`, `branding scaffold`, `subs scaffold`, or `community scaffold` only when that feature is part of your consumer plan. They add public templates; they do not turn this generic repository into your consumer application.

<a id="test-and-publish"></a>
<table><tr><td bgcolor="#0d9488"><strong><big>🧪 Test and publish</big></strong></td></tr></table>

### Test

```powershell
.\merit.ps1 where
.\merit.ps1 verify --path <consumer>
.\merit.ps1 e2e --path <consumer>
.\merit.ps1 e2e:playwright --path <consumer>
```

Run the browser command only when its optional browser tooling is installed. Record the command, expected result, observed result, and receipt path. A browser check must use local HTTP or a deployed HTTPS origin; `file://` is smoke-only.

### Publish

| Command | Use it when | Boundary |
|---|---|---|
| `oc --path <consumer>` | You want the guided MERIT-hosted demo route | Uses the selected public provider profile |
| `deploy --path <consumer>` | You own a Vercel deployment path | Uses your deployment credentials and scope |
| `portal --path <consumer>` | You own a here.now portal path | Uses your BYOK portal credentials |
| `all --path <consumer>` | Your consumer is ready for the supported combined sequence | Runs the applicable publish steps |
| `apps publish --path <consumer>` | You need to repeat the platform upload phase | Publishes only the consumer's play/config surface |

After publishing, use the Hub's `OCV` route and save the hosted URL and receipt. Do not describe a local `3V` result as a hosted release.

<a id="provider-profiles"></a>
<table><tr><td bgcolor="#6f42c1"><strong><big>🔌 Provider profiles and ownership</big></strong></td></tr></table>

The public default is **v00**:

```text
gateway:  https://merit-prod.vercel.app
```

The release may also list **v01**:

```text
gateway:  https://merit-prodv01.vercel.app
status:   coming_soon until the provider promotes it to live_public
```

Inspect and select profiles with:

```powershell
.\merit.ps1 ecosystem list
.\merit.ps1 ecosystem use v00 --path <consumer>
```

Selection is per consumer. The default remains v00 until the provider publishes v01 as live. `--allow-nonlive` is for deliberate preview validation only.

| Surface | Owns |
|---|---|
| `merit-agent-skills` | Generic CLI, Hub, templates, release pins, and provider-profile selection |
| Consumer repository, such as `merit-demo` | Consumer ID, launch settings, app routes, product content, and consumer tests |
| Provider repository, such as `merit-prod` | Registration, hosted runtime, provider rails, and live profile promotion |
| `merit-private-vault` | Private policy, registries, operator procedures, and future `merit.blob` decisions |

> A consumer ID never belongs in this generic skills repository. The CLI selects a provider profile; the provider owns registration and hosted behavior.

<a id="recovery"></a>
<table><tr><td bgcolor="#0d9488"><strong><big>🧯 Recovery and safety</big></strong></td></tr></table>

When a check fails, run:

```powershell
.\merit.ps1 help
.\merit.ps1 where
.\merit.ps1 verify --path <consumer>
```

Read the first failing line in the receipt. It should tell you the expected result, observed result, reason, and remediation. Keep `.env.local`, credentials, and generated secret-bearing receipts out of Git. Use `apps remove --yes` only after checking the target consumer and platform ID.

Operator and policy commands such as `law`, `vault`, and `admin` are not part of the first student path. They remain documented in the public law pack and private operator materials.

<a id="references"></a>
<table><tr><td bgcolor="#6f42c1"><strong><big>📚 References</big></strong></td></tr></table>

- [MERIT public README](../README.md) — visual path chooser and quick install.
- [Merit-Hub README](../Merit-Hub/README.md) — menu keys, receipts, and clean-device behavior.
- [Usage guide](usage.md) — accounts, hosting, and freemium behavior.
- [Try bundles](TRY_BUNDLES.md) — route selection by outcome.
- [Build over dinner](howto/launch-over-dinner.md) — guided personalization.
- [Public/private law pack](merit_law_pack.md) — the public boundary for MERIT law.

## Document control

| Version | Date | Change |
|---|---|---|
| 1.0.1 | 2026-09-08 | Reworked to the MERIT documentation standard; corrected the public command map and ownership boundaries. |
| 1.0.0 | 2026-09-08 | Initial student guide. |
