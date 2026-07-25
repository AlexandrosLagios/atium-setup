# Canonical Local Setup Repository Design

## Goal

Make `atium-setup` the single editable source for the owner's shell setup,
dotfiles, and reusable agent skills. Home-directory files and platform plugin
directories are deployed views, not independent sources.

## Principles

- Edit only files in this repository.
- Deploy dotfiles with chezmoi so deployment can be previewed and applied
  safely on a new machine.
- Keep every reusable skill in `skills/<name>/`; install it into Codex and
  Claude through links or generated adapters rather than copying its content.
- Keep platform-specific plugin manifests thin and separate from canonical
  skill content.
- Never commit credentials, access tokens, certificates, or machine-specific
  private configuration.
- Separate portable configuration from macOS-only and work-only configuration.

## Repository Structure

```text
atium-setup/
├── .chezmoiroot
├── .gitignore
├── README.md
├── Brewfile
├── dotfiles/
│   ├── home/
│   │   └── dot_zshrc
│   └── config/atium/zsh/
│       ├── aliases.zsh
│       ├── functions.zsh
│       ├── paths.zsh
│       ├── runtimes.zsh
│       └── prompt.zsh
├── skills/
│   └── <skill-name>/SKILL.md
├── plugins/
│   ├── claude/
│   └── codex/
├── scripts/
│   ├── bootstrap
│   ├── doctor
│   └── sync-skills
└── docs/
    └── secrets.md
```

`dotfiles/` is the chezmoi source root and contains the real, active
configuration. Files under `dotfiles/home` deploy to the home directory, and
files under `dotfiles/config` deploy to `~/.config/atium`. The deployed
`~/.zshrc` stays deliberately small: it loads the real modular configuration
from `~/.config/atium/zsh` and, if present, a local ignored private overlay.

## Skills and Plugin Deployment

`skills/<skill-name>/SKILL.md` is the only authored copy of a skill. The
`scripts/sync-skills` command discovers those folders, validates their names
and metadata, and links them into the configured Codex and Claude skills
directories. Plugin manifests live under `plugins/` and refer to the canonical
skill locations; no skill text is copied into a second source directory.

The script is idempotent, refuses to replace a non-symlink destination, and
supports a dry-run mode. That keeps existing local configurations safe while
making the installed skills actively usable.

## Secrets and Local Overrides

Users create `~/.config/atium/private.zsh` themselves and source credentials
from a password manager or local environment. The repository ignores actual
private overlays and `.env` files; `docs/secrets.md` documents the environment
variable names and setup process without creating a second configuration file.
Existing plaintext credentials are not migrated; they must be rotated and
replaced outside the repository.

## User Workflow

1. Clone this repository.
2. Run `scripts/bootstrap` to install chezmoi and the declared command-line
   dependencies.
3. Run `chezmoi init --source "$PWD/dotfiles"` and `chezmoi apply --source
   "$PWD/dotfiles"` to deploy dotfiles.
4. Create the ignored local private overlay if needed.
5. Run `scripts/sync-skills` to make canonical skills available in Codex and
   Claude.
6. Run `scripts/doctor` after setup or whenever tools change.

## Scope of First Implementation

The initial repository provides the structure, a modular secret-free zsh
baseline, a curated Brewfile, a sample skill, safe deployment scripts, and
documentation. It does not attempt to copy the existing `.zshrc` verbatim:
work-specific aliases and all secret-bearing exports stay out until each is
made portable and safe.
