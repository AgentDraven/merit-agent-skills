# Contributing to merit-agent-skills

Thanks for helping the MERIT OSS movement. This repo is **Apache-2.0** and welcomes
contributions to the public skills (`skills/`), the `merit` CLI (`merit.ps1` / `merit.sh`),
and the small play-shell/config templates (`templates/`, `cfg/`).

The same model applies to the sibling showcase repo
[`Mr-PI-Bala/merit-demo`](https://github.com/Mr-PI-Bala/merit-demo).

## clone vs branch vs fork — which do I need?

These are three different things, and the one you need depends on **whether you have
write access to the repo you want to change**.

| Action | GitHub account? | Who it is for | What it lets you do |
|--------|-----------------|---------------|---------------------|
| **Clone** | No (public repos) | Everyone | Download a local copy, run the CLI, scaffold apps, run smokes. You can commit **locally** but cannot push to the upstream repo. |
| **Branch** | Yes, **and** write access | Maintainers / collaborators | Push a `cursor/…` (or `feature/…`) branch directly to the upstream repo, then open a PR. |
| **Fork** | Yes (free) | Outside contributors | Create your **own** server-side copy under your account, push branches there, and open a PR back to upstream. No write access to upstream required. |

Rule of thumb:

- **Just using MERIT?** `clone` a release tag (see below). No account needed.
- **Contributing and you are a collaborator?** `branch` on upstream → PR.
- **Contributing and you are not a collaborator?** `fork` → `branch` on your fork → PR.

## Path A — no GitHub account (use + validate locally)

You can do the entire freemium loop with **zero accounts**:

```bash
git clone --branch skills-v0.3.53 https://github.com/AgentDraven/merit-agent-skills.git
cd merit-agent-skills
./scripts/smoke-freemium.sh          # scaffolds a temp app and verifies it
./merit.sh closeout --path .         # the same validation CI runs
```

To propose a change without an account, you can still make commits locally and share a
patch with a maintainer:

```bash
git checkout -b my-change
# ...edit files...
git commit -am "describe the change"
git format-patch origin/main --stdout > my-change.patch   # email/attach this
```

A maintainer can apply the patch and open the PR for you. (Opening a PR yourself on
GitHub requires a free account — see Path B.)

## Path B — with a free GitHub account (fork → PR, recommended)

This is the standard open-source flow and works the same for `merit-agent-skills` and
`merit-demo`.

1. **Fork** the repo on GitHub (top-right "Fork"). This creates
   `https://github.com/<you>/merit-agent-skills`.
2. **Clone your fork** and add the upstream remote:
   ```bash
   git clone https://github.com/<you>/merit-agent-skills.git
   cd merit-agent-skills
   git remote add upstream https://github.com/AgentDraven/merit-agent-skills.git
   ```
3. **Branch, change, validate, push to your fork:**
   ```bash
   git checkout -b my-change
   # ...edit files...
   ./merit.sh closeout --path .        # must pass (CI gate)
   ./scripts/smoke-freemium.sh         # must pass (CI gate)
   git commit -am "describe the change"
   git push -u origin my-change
   ```
4. **Open a Pull Request** from `your-fork:my-change` → `AgentDraven/merit-agent-skills:main`.

Keep your fork current with `git fetch upstream && git rebase upstream/main`.

## Path C — maintainers / collaborators (branch on upstream)

If you have write access, skip the fork and push a branch straight to upstream:

```bash
git checkout -b cursor/short-description
# ...edit + validate (closeout + smoke)...
git commit -am "describe the change"
git push -u origin cursor/short-description
# open a PR to main
```

## "must be a collaborator" when opening a PR

Public repos already accept **forks and PRs from anyone with a GitHub account** — nothing
needs to be enabled for that (Path B). You only see `must be a collaborator` when a tool
or bot tries to create a **branch or PR directly on the upstream repo** using an identity
that lacks write access. Two ways to resolve it, depending on what you want:

- **For outside contributors:** use the **fork → PR** flow (Path B). No upstream write
  access is required.
- **For trusted people / automation (e.g. Cursor Cloud agents) that should push branches
  and open PRs directly on upstream:** the repo owner grants access, either by adding them
  under **Settings → Collaborators**, or by installing the **Cursor GitHub App** on the
  account/repo so cloud agents can open PRs. (A plain `git push` may still succeed via a
  connected token even when PR creation is blocked — the two use different permissions.)

## Before you open a PR (local checklist)

CI (`.github/workflows/validate.yml`) runs exactly these two commands. Run them locally
first so your PR is green:

```bash
./merit.sh closeout --path .     # verify + closeout gate (AP-MA-13 webpage shell)
./scripts/smoke-freemium.sh      # scaffold + verify the generated play shell
```

Both require **PowerShell (`pwsh`)** — the wrappers `exec pwsh`. See `AGENTS.md` for the
runtime and scaffold-flow notes.

## Scope (please respect the boundaries)

Per `AGENTS.md`, this repo ships **only** public skills, the public CLI, and small
templates. Do **not** add product implementations, running Portals, provider backends,
private vault policy, or consumer app source here — those live in `merit-prod` / consumer
repos such as `merit-demo`.
