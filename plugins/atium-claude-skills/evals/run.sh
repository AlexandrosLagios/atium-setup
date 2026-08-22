#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: evals/run.sh [case-name ...]

Measure routing: for each case, which skill fires. `claude plugin eval` is the
real harness for this and is gated behind early access, so this runs the same
measurement with what is available today.

Each run starts one agent session, so this costs tokens. It is deliberately
absent from tests/run.sh.

Two things invalidate a result silently, so the runner handles both:

  - Running inside this repository. There the agent reads skills/<name>/SKILL.md
    as an ordinary file and never invokes a skill, so a case passes for the wrong
    reason. Every session runs in a throwaway git fixture instead.
  - A session that never reached the model. A failed run reports no skill, which
    reads exactly like correct silence. A case whose result event carries an
    error is reported as `error`, never as a pass.

The session uses your own configuration, so the installed plugin loads next to
the checkout under test. Both offer the same skill names, so routing stays
readable, but run scripts/refresh-plugins first when the answer must come from
the working tree. An isolated CLAUDE_CONFIG_DIR is not an option: a fresh config
directory holds no credentials, and every session fails with "Not logged in".

Sessions run with --permission-mode plan, so a case cannot edit or push.
EOF
}

case "${1:-}" in
  --help|-h) usage; exit 0 ;;
esac

evals_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$evals_dir/../../.." && pwd)

command -v claude >/dev/null 2>&1 || {
  printf '%s\n' 'claude CLI not found' >&2
  exit 1
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

stage="$work/plugin"
mkdir -p "$stage/.claude-plugin"
cp "$repo_root/plugins/atium-claude-skills/.claude-plugin/plugin.json" "$stage/.claude-plugin/"
cp -R "$repo_root/skills" "$stage/skills"

# A plausible repository. Without a remote and a base ref, a PR case is answered
# with "there is nothing to open a PR against" and no skill ever fires, which
# reads as a routing failure when it is a fixture failure.
fixture="$work/fixture"
mkdir -p "$fixture"
(
  cd "$fixture"
  git init -q -b main
  printf 'MAX_RETRIES = 3\n' >config.py
  printf '# service\n\nAuthentication middleware lives in config.py.\n' >README.md
  git add -A
  git -c user.email=eval@example.com -c user.name=eval commit -qm "init"
  git remote add origin https://github.com/example/eval-fixture.git
  git update-ref refs/remotes/origin/main HEAD
  git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
  git checkout -q -b feature/eval-fixture
  printf 'MAX_RETRIES = 5\n' >config.py
  git add -A
  git -c user.email=eval@example.com -c user.name=eval commit -qm "raise the retry ceiling"
  git config branch.feature/eval-fixture.remote origin
  git config branch.feature/eval-fixture.merge refs/heads/feature/eval-fixture
)

failed=false
cases=${*:-}
[ -n "$cases" ] || cases=$(cd "$evals_dir" && for d in */; do [ -f "$d/prompt.md" ] && printf '%s ' "${d%/}"; done)

for name in $cases; do
  case_dir="$evals_dir/$name"
  [ -f "$case_dir/prompt.md" ] || {
    printf 'no such case: %s\n' "$name" >&2
    failed=true
    continue
  }

  require=''
  forbid=''
  # shellcheck source=/dev/null
  [ -f "$case_dir/expect.env" ] && . "$case_dir/expect.env"

  stream="$work/$name.jsonl"
  (
    cd "$fixture"
    claude -p --plugin-dir "$stage" \
      --permission-mode plan --output-format stream-json --verbose \
      >"$stream" 2>/dev/null <"$case_dir/prompt.md" || true
  )

  session_error=$(python3 - "$stream" <<'PYERR'
import json, sys
for line in open(sys.argv[1]):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    if event.get("type") == "result" and event.get("is_error"):
        reason = event.get("terminal_reason") or "error"
        print(str(reason) + ": " + str(event.get("result"))[:80])
        break
PYERR
)
  if [ -n "$session_error" ]; then
    printf '%-14s %-5s %s\n' "$name" "error" "$session_error" >&2
    failed=true
    continue
  fi

  fired=$(python3 - "$stream" <<'PY'
import json, sys
names = []
for line in open(sys.argv[1]):
    try:
        event = json.loads(line)
    except ValueError:
        continue
    message = event.get("message") or {}
    content = message.get("content")
    if not isinstance(content, list):
        continue
    for block in content:
        if not isinstance(block, dict) or block.get("type") != "tool_use":
            continue
        if block.get("name") != "Skill":
            continue
        # The input key is not part of any contract, so read every string in it.
        # A plugin skill reports as `<plugin>:<skill>`, so compare the last
        # segment: the expectation files name the skill, not its delivery.
        for value in (block.get("input") or {}).values():
            if isinstance(value, str):
                names.append(value.rsplit(":", 1)[-1])
print(" ".join(sorted(set(names))))
PY
)

  verdict=pass
  for want in $require; do
    case " $fired " in
      *" $want "*) ;;
      *) verdict=fail; printf '%s: missing %s\n' "$name" "$want" >&2 ;;
    esac
  done
  for deny in $forbid; do
    case " $fired " in
      *" $deny "*) verdict=fail; printf '%s: fired %s\n' "$name" "$deny" >&2 ;;
      *) ;;
    esac
  done

  printf '%-14s %-4s fired: %s\n' "$name" "$verdict" "${fired:-none}"
  [ "$verdict" = pass ] || failed=true
done

if [ "$failed" = true ]; then
  printf '%s\n' 'routing evals: failing'
  exit 1
fi
printf '%s\n' 'routing evals: passing'
