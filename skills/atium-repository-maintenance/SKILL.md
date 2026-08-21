---
name: atium-repository-maintenance
description: Use when changing this repository's dotfiles, setup scripts, skill installation, plugin wrappers, or public-release safety controls. Keeps the Atium setup repository the single public-safe source for dotfiles and reusable agent skills. Not for authoring the content of a skill, which is creating-personal-skills.
---

# Atium repository maintenance

Use this skill when changing this repository's dotfiles, setup scripts, skill
installation, or public-release safety controls.

## Rules

- Edit source files in this repository, never deployed files in `$HOME`.
- Keep reusable skill content in `skills/<name>/SKILL.md` exactly once.
- Keep the Codex plugin's `skills/` directory as generated links to portable
  canonical skills; never copy skill text into a plugin wrapper.
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

Use `scripts/refresh-plugins --dry-run` before deploying generated plugin links
or removing legacy direct links if you want to inspect the changes first.
