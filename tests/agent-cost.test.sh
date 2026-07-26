#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
script="$repo_root/scripts/agent-cost"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT HUP INT TERM

session_dir="$temp_dir/-Users-someone-src-Example"
mkdir -p "$session_dir"

# One Opus 5 message at $5/$25 per MTok: 1M input, 1M output, 1M cache read
# (0.1x input), 1M 1h cache write (2x input) = 5 + 25 + 0.5 + 10 = $40.50.
cat >"$session_dir/session.jsonl" <<'EOF'
{"type":"assistant","timestamp":"2020-01-01T00:00:00.000Z","cwd":"/Users/someone/src/Example","attributionSkill":"example-skill","message":{"model":"claude-opus-5","usage":{"input_tokens":1000000,"output_tokens":1000000,"cache_read_input_tokens":1000000,"cache_creation_input_tokens":1000000,"cache_creation":{"ephemeral_1h_input_tokens":1000000,"ephemeral_5m_input_tokens":0}}}}
{"type":"assistant","timestamp":"2020-01-01T00:00:00.000Z","cwd":"/Users/someone/src/Example","message":{"model":"claude-imaginary-9","usage":{"input_tokens":50,"output_tokens":50}}}
EOF

output="$temp_dir/output.txt"
"$script" --days 0 --by skill --by model --transcripts "$temp_dir" >"$output" 2>&1

grep -q '\$40\.50' "$output" || {
  printf 'expected the documented $40.50 total\n' >&2
  cat "$output" >&2
  exit 1
}
grep -q 'example-skill' "$output"
grep -q 'unpriced models excluded: claude-imaginary-9' "$output"

# The window filter must exclude everything when the cutoff is in the future.
"$script" --days 1 --transcripts "$temp_dir" >"$output" 2>&1
grep -q '0 assistant message' "$output" || {
  printf 'expected the day window to exclude the dated fixture\n' >&2
  cat "$output" >&2
  exit 1
}

printf '%s\n' 'agent cost tests passed'
