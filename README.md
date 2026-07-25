# atium-setup

The canonical, public-safe source for my dotfiles and agent skills.

Edit files here—never the deployed copies in `$HOME`. Chezmoi deploys the
actual dotfiles from `dotfiles/`, and `scripts/sync-skills` links the
canonical skills into Codex and Claude without copying them.

## Quick start

```sh
git clone https://github.com/<your-user>/atium-setup.git
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

The only supported untracked shell overlay is
`~/.config/atium/private.zsh`. It is loaded after the tracked modules and is
for secrets or genuinely local settings only. See [the secrets guide](docs/secrets.md).

## Layout

- `dotfiles/`: real chezmoi source state; deployed files are not edited directly.
- `skills/`: one authored copy of each reusable skill.
- `scripts/sync-skills`: creates agent-facing links, never skill copies.
- `scripts/doctor`: reports missing tools and deployment status.
