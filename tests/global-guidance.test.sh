#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_root/scripts/install-global-guidance"
source_path="$repo_root/global/personal-skills-guidance.md"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

codex_home="$temp_dir/codex"
claude_home="$temp_dir/claude"

run_installer() {
  ATIUM_CODEX_HOME="$codex_home" \
    ATIUM_CLAUDE_HOME="$claude_home" \
    "$script" "$@"
}

run_installer --dry-run
[ ! -e "$codex_home/AGENTS.md" ]
[ ! -e "$claude_home/CLAUDE.md" ]

run_installer
[ -L "$codex_home/AGENTS.md" ]
[ -L "$claude_home/CLAUDE.md" ]
[ "$(readlink "$codex_home/AGENTS.md")" = "$source_path" ]
[ "$(readlink "$claude_home/CLAUDE.md")" = "$source_path" ]

preserved_claude_home="$temp_dir/preserved-claude"
mkdir -p "$preserved_claude_home"
printf '%s\n' 'preserve this instruction' > "$preserved_claude_home/CLAUDE.md"
ATIUM_CODEX_HOME="$temp_dir/preserved-codex" \
  ATIUM_CLAUDE_HOME="$preserved_claude_home" \
  "$script"
grep -qx 'preserve this instruction' "$preserved_claude_home/CLAUDE.md"
grep -Fxq "@$preserved_claude_home/personal-skills-guidance.md" "$preserved_claude_home/CLAUDE.md"
[ -L "$preserved_claude_home/personal-skills-guidance.md" ]
[ "$(readlink "$preserved_claude_home/personal-skills-guidance.md")" = "$source_path" ]

conflict_home="$temp_dir/conflict"
mkdir -p "$conflict_home"
printf '%s\n' 'keep me' > "$conflict_home/AGENTS.md"

if ATIUM_CODEX_HOME="$conflict_home" ATIUM_CLAUDE_HOME="$temp_dir/other-claude" "$script" >/dev/null 2>&1; then
  printf '%s\n' 'expected installer to reject a regular destination' >&2
  exit 1
fi

grep -qx 'keep me' "$conflict_home/AGENTS.md"
printf '%s\n' 'global guidance tests passed'
