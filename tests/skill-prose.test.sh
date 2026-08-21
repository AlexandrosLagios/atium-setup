#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

# Rule 5 of global/prose-style.md bans the em dash, and a skill body is a file in
# a repository. The character reads as house style to a human and drifts back one
# skill at a time, so lock it. graphify is a declared fork, and its upstream text
# is exempt; see THIRD-PARTY-NOTICES.md.
offenders=$(grep -rn '—' "$repo_root/skills" --include='*.md' | grep -v '/skills/graphify/' || true)
if [ -n "$offenders" ]; then
  printf 'em dash in a skill, against prose rule 5:\n%s\n' "$offenders" >&2
  exit 1
fi

printf '%s\n' 'skill prose checks passed'
