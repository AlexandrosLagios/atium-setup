#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_root/scripts/install-global-guidance"
generated_agents="$repo_root/AGENTS.md"
source_prose="$repo_root/global/prose-style.md"
source_skills="$repo_root/global/personal-skills-guidance.md"
source_claude="$repo_root/global/claude-global-instructions.md"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

codex_home="$temp_dir/codex"
claude_home="$temp_dir/claude"

run_installer() {
  ATIUM_CODEX_HOME="$codex_home" \
    ATIUM_CLAUDE_HOME="$claude_home" \
    "$script" "$@"
}

# The committed artefact matches its sources before any change.
run_installer --check >/dev/null

# Drift in the generated artefact is detected, then repaired by a plain run.
printf '%s\n' 'drift' >>"$generated_agents"
if run_installer --check >/dev/null 2>&1; then
  printf '%s\n' 'expected --check to reject a stale AGENTS.md' >&2
  exit 1
fi

run_installer --dry-run >/dev/null
[ ! -e "$codex_home/AGENTS.md" ]
[ ! -e "$claude_home/CLAUDE.md" ]
grep -qx 'drift' "$generated_agents"

run_installer >/dev/null
run_installer --check >/dev/null

# AGENTS.md carries both authored files to Codex.
grep -q 'The reply contract' "$generated_agents"
grep -q 'This repository is the only authored source' "$generated_agents"
[ ! -L "$generated_agents" ]

# The output style carries the prose rules into the Claude system prompt.
style="$claude_home/output-styles/Atium.md"
[ -f "$style" ]
grep -qx 'name: Atium' "$style"
grep -qx 'keep-coding-instructions: true' "$style"
grep -q 'The reply contract' "$style"

# Each instruction file reaches its agent through a link to the authored copy.
[ "$(readlink "$codex_home/AGENTS.md")" = "$generated_agents" ]
[ "$(readlink "$claude_home/CLAUDE.md")" = "$source_claude" ]
[ "$(readlink "$claude_home/personal-skills-guidance.md")" = "$source_skills" ]

# CLAUDE.md must not import the prose rules, because the output style holds them.
if grep -q 'prose-style' "$source_claude"; then
  printf '%s\n' 'CLAUDE.md must not import the prose rules' >&2
  exit 1
fi
grep -q '@~/.claude/personal-skills-guidance.md' "$source_claude"

# An unrelated file at a destination is never replaced.
conflict_home="$temp_dir/conflict"
mkdir -p "$conflict_home"
printf '%s\n' 'keep me' >"$conflict_home/AGENTS.md"

if ATIUM_CODEX_HOME="$conflict_home" ATIUM_CLAUDE_HOME="$temp_dir/other-claude" "$script" >/dev/null 2>&1; then
  printf '%s\n' 'expected installer to reject a regular destination' >&2
  exit 1
fi

grep -qx 'keep me' "$conflict_home/AGENTS.md"

# The chat rules cap a reply that only answers a question.
grep -q 'one paragraph maximum to answer a question' "$source_prose"

# The prose rules state the reply contract that both agents read.
grep -q 'DONE' "$source_prose"
grep -q 'BLOCKED' "$source_prose"

printf '%s\n' 'global guidance tests passed'
