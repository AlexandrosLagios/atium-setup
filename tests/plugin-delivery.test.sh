#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo_root/skills"
codex_dir="$repo_root/plugins/atium-skills/skills"
claude_dir="$repo_root/plugins/atium-claude-skills/skills"
exclude_file="$source_dir/.codexignore"

[ -d "$codex_dir" ]
[ ! -L "$codex_dir" ]
[ -L "$claude_dir" ]
[ "$(readlink "$claude_dir")" = "../../skills" ]

for skill_path in "$source_dir"/*; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")
  codex_link="$codex_dir/$skill_name"

  if grep -F -x "$skill_name" "$exclude_file" >/dev/null 2>&1; then
    [ ! -e "$codex_link" ]
  else
    [ -L "$codex_link" ]
    [ "$(readlink "$codex_link")" = "../../../skills/$skill_name" ]
  fi
done

grep -Fq '"source": "./plugins/atium-claude-skills"' "$repo_root/.claude-plugin/marketplace.json"
grep -Fq '"path": "./plugins/atium-skills"' "$repo_root/.agents/plugins/marketplace.json"
expected_version=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$repo_root/plugins/atium-skills/.codex-plugin/plugin.json")
claude_version=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["version"])' "$repo_root/plugins/atium-claude-skills/.claude-plugin/plugin.json")
marketplace_version=$(python3 -c 'import json, sys; print(next(p["version"] for p in json.load(open(sys.argv[1]))["plugins"] if p["name"] == "atium-claude-skills"))' "$repo_root/.claude-plugin/marketplace.json")
[ "$expected_version" = "$claude_version" ]
[ "$expected_version" = "$marketplace_version" ]
printf '%s\n' 'plugin delivery checks passed'
