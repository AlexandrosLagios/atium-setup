---
name: atium-repository-maintenance
description: Maintain the Atium setup repository as the single public-safe source for dotfiles and reusable agent skills.
---

# Atium repository maintenance

Use this skill when changing this repository's dotfiles, setup scripts, skill
installation, or public-release safety controls.

## Rules

- Edit source files in this repository, never deployed files in `$HOME`.
- Keep reusable skill content in `skills/<name>/SKILL.md` exactly once.
- Keep the Codex plugin's `skills/` directory as a link to the canonical
  `skills/` directory; never copy skill text into a plugin wrapper.
- Keep the Claude Code plugin's `skills/` directory as a link to the same
  canonical directory; Claude's installed cache is generated state.
- Do not add credentials, access tokens, private endpoints, certificates, or
  work-only paths to tracked files.
- Put genuinely local shell configuration in
  `~/.config/atium/private.zsh`, which is intentionally ignored.

## Verification

Run the following before committing:

```sh
tests/run.sh
scripts/check-secrets
git diff --check
```

Use `scripts/sync-skills --dry-run` before deploying Codex links or removing
legacy Claude links if you want to inspect the changes first.
