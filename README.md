# atium-setup

The canonical, public-safe source for my dotfiles and agent skills.

Edit files here—never the deployed copies in `$HOME`. Chezmoi deploys the
actual dotfiles from `dotfiles/`. Both agents load skills through thin plugins
whose generated links point back to the canonical `skills/` directories.

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

# Refresh generated plugin links and installed agent plugins.
scripts/refresh-plugins

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
- `scripts/sync-plugin-skills`: generates portable Codex plugin links.
- `scripts/sync-skills`: removes legacy direct skill links from both agents.
- `scripts/refresh-plugins`: validates and refreshes local plugin deployment.
- `scripts/doctor`: reports missing tools, plugin status, and stale links.

## Codex plugin

The `atium-skills` plugin is a thin wrapper: it contains generated symlinks to
portable canonical skills, so it never contains a second authored copy.

```sh
codex plugin marketplace add "$(git rev-parse --show-toplevel)"
codex plugin add atium-skills@personal
```

Use `scripts/refresh-plugins` after changing skills. It keeps the generated
portable inventory in sync and confirms the plugin is installed.

## Claude Code plugin

This repository is also a Claude Code marketplace. Its plugin is a thin wrapper
whose `skills/` directory links to the same canonical `skills/` directory:

```sh
claude plugin marketplace add "$(git rev-parse --show-toplevel)"
claude plugin install atium-claude-skills@atium-setup
```

Claude Code copies the plugin into its cache on installation. Reinstall it after
changing plugin or skill content. `scripts/sync-skills` deliberately removes
legacy `~/.claude/skills` links so the plugin is the sole Claude entrypoint.

## Releasing skill changes

Use an explicit version when skills or plugin metadata are ready to publish:

```sh
scripts/release-skills 0.2.0
```

It synchronizes generated plugin links, updates both plugin versions, runs the
test and secret checks, and prints the commit and refresh commands. It never
commits or pushes for you.
