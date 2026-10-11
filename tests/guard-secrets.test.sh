#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
hook="$repo_root/plugins/atium-claude-skills/hooks/guard-secrets.py"

run_hook() {
  python3 -c 'import json, sys; print(json.dumps({"tool_input": {"command": sys.argv[1]}}))' "$1" | "$hook" 2>/dev/null
}

allowed() {
  run_hook "$1" || { printf 'expected allowed: %s\n' "$1" >&2; exit 1; }
}

blocked() {
  status=0
  run_hook "$1" || status=$?
  [ "$status" -eq 2 ] || { printf 'expected blocked: %s\n' "$1" >&2; exit 1; }
}

allowed 'with-secret KEY=acme-stage-api-key -- ./run-task --env stage'
allowed 'API_KEY="$(secret acme-stage-api-key)" ./run-task --env stage'
allowed 'secret-ls'
allowed 'git commit -m "fix: security headers"'
allowed 'grep -rn security src/'
allowed "with-secret KEY=acme -- 'printf %s \"\$KEY\" | curl --data @- https://example.com'"

blocked 'secret acme-stage-api-key'
blocked 'cd app && secret acme-stage-api-key | head -c 4'
blocked '( secret acme-stage-api-key )'
blocked 'echo "$(secret acme-stage-api-key)"'
blocked 'security find-generic-password -a atium -s acme -w'
blocked 'TOKEN=$(security find-generic-password -s cloudflare-dns-token -a vlp -w) && curl x'
blocked 'secret-set acme-stage-api-key'

printf '%s\n' 'guard-secrets tests passed'
