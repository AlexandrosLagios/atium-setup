#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
skill_path="$repo_root/skills/difit-review/SKILL.md"

if grep -Fq 'Claude Code background command' "$skill_path"; then
  printf '%s\n' 'difit-review must not require a Claude-only background command' >&2
  exit 1
fi

if ! grep -Fq 'in Codex' "$skill_path"; then
  printf '%s\n' 'difit-review must explain how to launch from Codex' >&2
  exit 1
fi

printf '%s\n' 'skill compatibility checks passed'
