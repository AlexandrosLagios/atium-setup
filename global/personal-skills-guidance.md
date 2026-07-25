# Personal skills

This repository is the only authored source for personal agent skills.

- When asked to create, import, or edit a personal skill, work in
  `skills/<kebab-case-name>/` in this repository.
- Never author directly in `~/.claude/skills`, `~/.claude/plugins`, or
  `~/.codex/skills`; they are generated deployment state.
- Keep every skill authored once. The Codex plugin must link to `skills/`,
  never contain a copied skill.
- Classify compatibility before deployment. `scripts/sync-skills` links
  portable skills to Codex; Claude Code loads all personal skills through the
  `atium-claude-skills` plugin. A skill with a documented Claude-only runtime
  requirement belongs in `skills/.codexignore`.
- Before committing, run `tests/run.sh`, `scripts/check-secrets`, and
  `scripts/sync-skills --dry-run`.

For the full creation workflow, read
`skills/creating-personal-skills/SKILL.md` before taking action.
