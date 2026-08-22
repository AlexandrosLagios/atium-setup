# atium-setup

The public-safe source of truth for my dotfiles and personal agent skills.

Edit this repository, never deployed copies in `$HOME`. Chezmoi deploys files
from `dotfiles/`; Codex and Claude Code load the same skills through thin
plugins that link back to `skills/`.

## Set up

```sh
git clone https://github.com/AlexandrosLagios/atium-setup.git
cd atium-setup
scripts/bootstrap          # preview changes
scripts/bootstrap --apply  # install dependencies and deploy
pre-commit install         # optional commit-time secret check
```

Before applying on an existing machine, copy any configuration you want to
keep into this repository.

## Daily workflow

```sh
# Edit the source of truth.
$EDITOR dotfiles/dot_config/atium/zsh/aliases.zsh

# Preview, then deploy dotfiles.
chezmoi diff --source "$(git rev-parse --show-toplevel)"
chezmoi apply --source "$(git rev-parse --show-toplevel)"

# After changing skills, refresh their generated plugin links.
scripts/refresh-plugins

# Before publishing changes.
tests/run.sh
scripts/check-secrets
```

Run `scripts/doctor` for a read-only check of prerequisites, plugin status,
and stale links.

## Privacy

Tracked files must be safe to publish. Put secrets and machine-specific shell
state only in the untracked `~/.config/atium/private.zsh` overlay. If a secret
is committed, revoke and rotate it before attempting history cleanup.

## Personal skills

Author each skill once under `skills/`; do not edit generated copies in
`~/.codex/skills`, `~/.claude/skills`, or plugin wrappers. Use
`skills/creating-personal-skills` when creating, importing, or adapting a
skill.

Install the global policy that enforces this rule in both agents:

```sh
scripts/install-global-guidance --dry-run
scripts/install-global-guidance
```

`AGENTS.md` is the canonical policy, and `CLAUDE.md` imports it.

### Plugin delivery

Codex receives portable skills through `atium-skills`; Claude Code receives
all skills through `atium-claude-skills`. Both wrappers are generated from the
canonical `skills/` directory: the Claude one links it, and the Codex one holds
git-ignored copies, because `codex plugin add` snapshots a plugin without
following symlinks and a linked skill installs as nothing.
`skills/.codexignore` lists skills that remain Claude-only because of runtime
requirements.

```sh
# Codex
codex plugin marketplace add "$(git rev-parse --show-toplevel)"
codex plugin add atium-skills@personal

# Claude Code
claude plugin marketplace add "$(git rev-parse --show-toplevel)"
claude plugin install atium-claude-skills@atium-setup
```

Run `scripts/refresh-plugins` after changing a skill. Claude Code caches
plugin content, so reinstall or update its plugin after changing skills.

A file on disk is not a skill a session can see. `scripts/verify-skill-discovery`
opens one session per agent and reports what each one actually offers, which is
where discovery fails: Codex shortens skill descriptions that overflow its skills
context budget, and says so in the session rather than on disk. It costs a model
call, so it stays out of `tests/run.sh`.

```sh
scripts/verify-skill-discovery            # both agents
scripts/verify-skill-discovery --codex    # one arm
```

## Third-party skills

`third-party-skills.tsv` declares the skills this machine should have from other
people's repositories, the way `Brewfile` declares packages. They are deployment
state, not authored content: the installer writes them to `~/.agents/skills/`
and links them into both agents.

```sh
scripts/install-third-party --dry-run
scripts/install-third-party
scripts/install-third-party --check   # report missing without installing
```

`scripts/bootstrap --apply` runs the installer, and `scripts/doctor` reports any
declared skill that is missing. Scan anything new before trusting it; see
`skills/audit-agent-skills`.

A skill adapted from someone else's repository instead of installed from it lives
in `skills/` like any authored skill, names its origin in a Provenance section,
and carries its upstream licence in `THIRD-PARTY-NOTICES.md`.

## Harness audit

The harness has no failing state: a plugin serves the skill set it was installed
with, a hook injects context nobody acts on, a scheduled task runs with no copy
in any repository. `scripts/audit-harness` looks for the drift on purpose.

```sh
scripts/audit-harness --repo /path/to/the/repository/you/work/in
```

Read-only and offline; exits non-zero on a `high` finding. `scripts/doctor`
cannot substitute for it, because it compares plugin versions and a stale cache
carries the current version. `skills/audit-harness` covers the judgement the
scan cannot make, and the `harness-audit` routine runs it weekly.

## Agent cost

Claude Code records per-message token usage, model, and skill attribution in its
own session transcripts, so spend is already on disk. `scripts/agent-cost` reads
it and reports where the money went, retroactively and without a collector.

```sh
scripts/agent-cost                                     # last 30 days by skill, model, project
scripts/agent-cost --days 7 --by day
scripts/agent-cost --days 30 --offset-days 30 --by skill   # the month before last
```

Figures are API list-price equivalent, not an invoice: a subscription plan does
not bill per token. Compare workloads against each other, not against a bill.
The `agent-cost-digest` routine turns this into a monthly read-only digest.

## Routines

`routines/` holds sample Claude Code scheduled tasks, genericized so they carry
the shape (caps, ledger, guardrails, notification policy) without any private
repository, tracker, or environment detail.

```sh
scripts/install-routines --dry-run
scripts/install-routines
```

The installer only creates symlinks into `~/.claude/scheduled-tasks/` and never
replaces an existing path, so a live routine of the same name is left alone.
Prompts then sync across machines through `git pull`.

Schedules are account-side state and do not travel with the files. Register them
once per account from `routines/schedules.tsv`; `routines/README.md` has the
prompt for it.

## Release skill changes

```sh
scripts/release-skills 0.2.0
```

This synchronizes generated links, updates both plugin versions, runs checks,
and prints the next commands. It does not commit or push.

## Repository layout

- `dotfiles/` — chezmoi source files.
- `skills/` — canonical authored skills.
- `routines/` — sample scheduled tasks and their schedule manifest.
- `third-party-skills.tsv` — declared third-party skills installed from other repositories.
- `THIRD-PARTY-NOTICES.md` — upstream licences for skills adapted from other repositories.
- `scripts/` — setup, validation, and plugin-delivery commands.
- `tests/` — repository and plugin checks.
