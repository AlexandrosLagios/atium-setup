# atium-setup

The canonical, public-safe source for my dotfiles and agent skills.

Edit files here—never the deployed copies in `$HOME`. Chezmoi deploys the
actual dotfiles from `dotfiles/`, and `scripts/sync-skills` links the
canonical skills into Codex and Claude without copying them.

## Quick start

```sh
git clone https://github.com/AlexandrosLagios/atium-setup.git
cd atium-setup
scripts/bootstrap
scripts/bootstrap --apply
```

The first command previews what would be installed. The second applies the
dotfiles and installs the skills. On an existing machine, first move any
hand-edited configuration you want to retain into this repository.

To enable the commit-time secret check after the bootstrap:

```sh
pre-commit install
```

## Daily workflow

```sh
# Edit the source of truth.
$EDITOR dotfiles/dot_config/atium/zsh/aliases.zsh

# Preview and then deploy it.
chezmoi diff --source "$(git rev-parse --show-toplevel)"
chezmoi apply --source "$(git rev-parse --show-toplevel)"

# Make canonical skills available to both agents.
scripts/sync-skills

# Verify the repository is safe to publish.
tests/run.sh
scripts/check-secrets
```

## Private configuration

All tracked files in this repository should be safe to publish. Keep public-safe
configuration here. The only supported untracked shell overlay is
`~/.config/atium/private.zsh`, loaded after the tracked modules; reserve it for
real secrets and private machine state. If a secret reaches Git history, revoke
and rotate it before considering history cleanup.

## Personal skill guard

Personal skills are authored only under `skills/`. To apply that rule from any
repository in both Codex and Claude Code, install the linked global guidance:

```sh
scripts/install-global-guidance --dry-run
scripts/install-global-guidance
```

The root [AGENTS.md](AGENTS.md) is the canonical policy; [CLAUDE.md](CLAUDE.md)
imports it without duplicating it. Use
`skills/creating-personal-skills` whenever you create, import, or adapt a
personal skill.

## Layout

- `dotfiles/`: real chezmoi source state; deployed files are not edited directly.
- `skills/`: one authored copy of each reusable skill.
- `skills/.codexignore`: canonical skills that remain Claude-only until their
  runtime assumptions are ported.
- `scripts/sync-skills`: creates agent-facing links, never skill copies.
- `scripts/doctor`: reports missing tools and deployment status.

## Codex plugin

The `atium-skills` plugin is a thin wrapper: its `skills/` directory is a
link to this repository's canonical `skills/` directory, so it has no second
authored copy.

```sh
codex plugin marketplace add "$(git rev-parse --show-toplevel)"
codex plugin add atium-skills@personal
```

After changing plugin metadata, increment its version and reinstall the plugin
to refresh Codex's generated cache. Regular skill-content changes are available
immediately through `scripts/sync-skills`.
