# Personal skills

This repository is the only authored source for personal agent skills.

- When asked to create, import, or edit a personal skill, work in
  `skills/<kebab-case-name>/` in this repository.
- Never author directly in `~/.claude/skills` or `~/.codex/skills`; they
  are deployed links managed by `scripts/sync-skills`.
- Keep every skill authored once. The Codex plugin must link to `skills/`,
  never contain a copied skill.
- Classify compatibility before deployment. Portable skills use
  `scripts/sync-skills`; a skill with a documented Claude-only runtime
  requirement belongs in `skills/.codexignore`.
- Before committing, run `tests/run.sh`, `scripts/check-secrets`, and
  `scripts/sync-skills --dry-run`.

For the full creation workflow, read
`skills/creating-personal-skills/SKILL.md` before taking action.
