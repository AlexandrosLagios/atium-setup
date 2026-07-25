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
all skills through `atium-claude-skills`. Both are thin wrappers that link to
the canonical `skills/` directories. `skills/.codexignore` lists skills that
remain Claude-only because of runtime requirements.

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

## Release skill changes

```sh
scripts/release-skills 0.2.0
```

This synchronizes generated links, updates both plugin versions, runs checks,
and prints the next commands. It does not commit or push.

## Repository layout

- `dotfiles/` — chezmoi source files.
- `skills/` — canonical authored skills.
- `scripts/` — setup, validation, and plugin-delivery commands.
- `tests/` — repository and plugin checks.
