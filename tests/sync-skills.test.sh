#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_root/scripts/sync-skills"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

source_dir="$temp_dir/source"
codex_dir="$temp_dir/codex"
claude_dir="$temp_dir/claude"
mkdir -p "$source_dir/example-skill" "$source_dir/claude-only-skill" "$codex_dir" "$claude_dir"
printf '%s\n' '# Example skill' > "$source_dir/example-skill/SKILL.md"
printf '%s\n' '# Claude-only skill' > "$source_dir/claude-only-skill/SKILL.md"

ln -s "$source_dir/example-skill" "$codex_dir/example-skill"
ln -s "$source_dir/example-skill" "$claude_dir/example-skill"
ln -s "$source_dir/claude-only-skill" "$claude_dir/claude-only-skill"
printf '%s\n' 'do not replace me' > "$codex_dir/nonmatching-skill"

run_sync() {
  ATIUM_SKILLS_SOURCE_DIR="$source_dir" \
  ATIUM_CODEX_SKILLS_DIR="$codex_dir" \
  ATIUM_CLAUDE_SKILLS_DIR="$claude_dir" \
  "$script" "$@"
}

run_sync --dry-run
[ -L "$codex_dir/example-skill" ]
[ -L "$claude_dir/example-skill" ]

run_sync
[ ! -e "$codex_dir/example-skill" ]
[ ! -e "$claude_dir/example-skill" ]
[ ! -e "$claude_dir/claude-only-skill" ]
grep -qx 'do not replace me' "$codex_dir/nonmatching-skill"
printf '%s\n' 'skill sync tests passed'
