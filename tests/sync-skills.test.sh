#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_root/scripts/sync-skills"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

source_dir="$temp_dir/source"
codex_dir="$temp_dir/codex"
claude_dir="$temp_dir/claude"
exclude_file="$temp_dir/codex-exclude"
mkdir -p "$source_dir/example-skill"
printf '%s\n' '# Example skill' > "$source_dir/example-skill/SKILL.md"
mkdir -p "$source_dir/claude-only-skill"
printf '%s\n' '# Claude-only skill' > "$source_dir/claude-only-skill/SKILL.md"
printf '%s\n' 'claude-only-skill' > "$exclude_file"

run_sync() {
    ATIUM_SKILLS_SOURCE_DIR="$source_dir" \
    ATIUM_CODEX_SKILLS_DIR="$codex_dir" \
    ATIUM_CLAUDE_SKILLS_DIR="$claude_dir" \
    ATIUM_CODEX_EXCLUDE_FILE="$exclude_file" \
    "$script" "$@"
}

run_sync --dry-run
[ ! -e "$codex_dir/example-skill" ]
[ ! -e "$claude_dir/example-skill" ]

run_sync
[ -L "$codex_dir/example-skill" ]
[ -L "$claude_dir/example-skill" ]
[ "$(readlink "$codex_dir/example-skill")" = "$source_dir/example-skill" ]
[ "$(readlink "$claude_dir/example-skill")" = "$source_dir/example-skill" ]
[ ! -e "$codex_dir/claude-only-skill" ]
[ -L "$claude_dir/claude-only-skill" ]
[ "$(readlink "$claude_dir/claude-only-skill")" = "$source_dir/claude-only-skill" ]

mkdir -p "$source_dir/conflicting-skill" "$codex_dir"
printf '%s\n' '# Conflicting skill' > "$source_dir/conflicting-skill/SKILL.md"
printf '%s\n' 'do not replace me' > "$codex_dir/conflicting-skill"

if run_sync >/dev/null 2>&1; then
  printf '%s\n' 'expected sync to reject a regular destination' >&2
  exit 1
fi

[ ! -L "$codex_dir/conflicting-skill" ]
grep -qx 'do not replace me' "$codex_dir/conflicting-skill"
printf '%s\n' 'skill sync tests passed'
