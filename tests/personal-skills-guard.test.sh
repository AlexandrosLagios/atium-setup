#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
policy_path="$repo_root/global/personal-skills-guidance.md"
skill_path="$repo_root/skills/creating-personal-skills/SKILL.md"

test -L "$repo_root/AGENTS.md"
test "$(readlink "$repo_root/AGENTS.md")" = "global/personal-skills-guidance.md"
grep -Fxq '@AGENTS.md' "$repo_root/CLAUDE.md"
grep -Fq 'Never author directly in `~/.claude/skills` or `~/.codex/skills`' "$policy_path"
grep -Fq '`skills/.codexignore`' "$policy_path"

grep -Fxq 'name: creating-personal-skills' "$skill_path"
grep -Eq '^description: Use when ' "$skill_path"
grep -Fq '`skills/<kebab-case-name>/`' "$skill_path"
grep -Fq '`skills/.codexignore`' "$skill_path"
grep -Fq 'skill-creator' "$skill_path"
grep -Fq 'writing-skills' "$skill_path"

printf '%s\n' 'personal skills guard tests passed'
