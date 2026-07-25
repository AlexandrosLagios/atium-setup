---
name: creating-personal-skills
description: Use when creating, importing, or adapting a personal Claude or Codex skill that should live in the atium-setup source-of-truth repository.
---

# Creating personal skills

Create every personal skill in `skills/<kebab-case-name>/` in this repository.
Do not author a skill directly in `~/.claude/skills`, `~/.claude/plugins`, or
`~/.codex/skills`: those paths are generated deployment state.

## Workflow

1. Use `skill-creator` to initialize or update the skill in `skills/`.
2. Use `writing-skills` to test and validate the skill's triggering and
   behavior before deployment.
3. Check for credentials, private endpoints, work-only paths, and platform-only
   tool assumptions. Keep secrets out of the repository.
4. Classify compatibility:
   - Portable: leave it out of `skills/.codexignore` so
     `scripts/sync-skills` links it to Codex.
   - Claude-only: document the concrete runtime dependency and add its name to
     `skills/.codexignore`.
   - Claude Code loads both kinds through the `atium-claude-skills` plugin.
5. Run `tests/run.sh`, `scripts/check-secrets`, and
   `scripts/sync-skills --dry-run` before committing or deploying.

Never copy a skill into a platform wrapper. The source directory under
`skills/` is the only authored copy.
