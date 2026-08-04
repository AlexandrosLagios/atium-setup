#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fake_home="$work/home"
source_repo="$work/source"

mkdir -p "$fake_home/.claude/plugins/cache/example/demo/1.0.0/skills/kept"
mkdir -p "$fake_home/.claude/scheduled-tasks"
mkdir -p "$source_repo/plugins/demo/skills/kept" "$source_repo/plugins/demo/skills/added"
printf -- '---\nname: kept\n---\n' >"$fake_home/.claude/plugins/cache/example/demo/1.0.0/skills/kept/SKILL.md"
printf -- '---\nname: kept\n---\n' >"$source_repo/plugins/demo/skills/kept/SKILL.md"
printf -- '---\nname: added\n---\n' >"$source_repo/plugins/demo/skills/added/SKILL.md"

cat >"$fake_home/.claude/plugins/known_marketplaces.json" <<EOF
{"example": {"source": {"source": "directory", "path": "$source_repo"}}}
EOF
cat >"$fake_home/.claude/plugins/installed_plugins.json" <<EOF
{"plugins": {"demo@example": [{"installPath": "$fake_home/.claude/plugins/cache/example/demo/1.0.0", "version": "1.0.0"}]}}
EOF

output=$(HOME="$fake_home" "$repo_root/scripts/audit-harness" --sessions 0 2>&1 || true)

case "$output" in
  *"plugin-drift"*"added"*) ;;
  *)
    printf 'expected a plugin-drift finding naming the uninstalled skill, got:\n%s\n' "$output" >&2
    exit 1
    ;;
esac

status=0
HOME="$fake_home" "$repo_root/scripts/audit-harness" --sessions 0 >/dev/null 2>&1 || status=$?
if [ "$status" -ne 1 ]; then
  printf 'expected exit 1 on a high finding, got %s\n' "$status" >&2
  exit 1
fi

printf '%s\n' 'audit-harness checks passed'
