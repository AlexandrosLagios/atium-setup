#!/usr/bin/env bash
# Assembles the mechanical sections of the morning brief (environment errors, own
# PRs, review requests) as finished markdown. No model needed: the scheduled task
# runs this, pastes the output, and adds the connector-backed sections itself.
#
# Genericized sample. Set the three values below for a real deployment; the log
# archive is queried through `bslog sql`, so swap that call for whatever CLI
# fronts your log store.
#
# Never exits non-zero and never aborts on a failed section: a broken source
# prints "unavailable: <reason>" and the rest of the brief still ships.
set -uo pipefail

REPO=${REPO:-$HOME/src/example/example-repo}
REPO_SLUG=${REPO_SLUG:-owner/example-repo}
# Checks that report status but never gate a merge, as an extended regex.
ADVISORY_CHECKS=${ADVISORY_CHECKS:-'(?i)(codefactor|coverage)'}

TASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# The overnight window is the last 16h. The baseline span is measured by the query
# itself (baseline_hours) because log retention is shorter than it looks.
OVERNIGHT_H=16
# An archive more than this far behind means "no errors" is not evidence of quiet.
STALE_AFTER_MIN=180

section_errors() {
  echo "## 1. Overnight environment errors"
  if ! command -v bslog >/dev/null 2>&1; then
    echo "unavailable: bslog not on PATH"
    return
  fi
  # scan-skills: allow S002 the log CLI reads its credentials from the repo's .env
  set -a; . "$REPO/.env" 2>/dev/null; set +a
  if ! bslog sql -- "$(cat "$TASK_DIR/overnight-errors.sql")" >"$TMP/errors.json" 2>"$TMP/errors.err"; then
    echo "unavailable: bslog query failed ($(head -1 "$TMP/errors.err" | cut -c1-120))"
    return
  fi
  if [ "$(jq 'length' "$TMP/errors.json" 2>/dev/null || echo 0)" -eq 0 ]; then
    quiet_or_broken
    return
  fi
  jq -r --argjson on "$OVERNIGHT_H" '
    def line: "- \(.svc) · \(.key // .level // "?") · \(.signature) · ×\(.overnight)";
    ((.[0].baseline_hours // 0) | if . < 1 then 1 else . end) as $base
    | def rate: (.overnight / $on);
      def baserate: (.baseline / $base);
      map(select(.baseline == 0)) as $new
    | map(select(.baseline > 0 and .overnight >= 5 and rate > 3 * baserate)) as $spiking
    | ($new | length) as $n
    | ($spiking | length) as $s
    | if $n > 0 then "**New signatures (\($n)):**", ($new[] | line) else empty end
    , if $s > 0 then "**Spiking (\($s), >3x its \($base | floor)h baseline rate):**", ($spiking[] | line) else empty end
    , if $n == 0 and $s == 0 then
        "No new or spiking signatures. Top recurring: " + ([limit(3; .[] | "\(.svc)/\(.signature[0:48]) ×\(.overnight)")] | join("; "))
      else empty end
  ' "$TMP/errors.json" 2>/dev/null || echo "unavailable: could not parse bslog output"
}

# Zero error rows is either good news or a broken pipeline, and those must not read
# the same. Confirm the archive is still receiving before calling it a quiet night.
quiet_or_broken() {
  if ! bslog sql -- "$(cat "$TASK_DIR/freshness.sql")" >"$TMP/fresh.json" 2>/dev/null; then
    echo "unavailable: no error rows, and the freshness check failed — treat as unknown, not quiet"
    return
  fi
  local lag rows
  lag=$(jq -r '.[0].lag_minutes // 99999' "$TMP/fresh.json" 2>/dev/null)
  rows=$(jq -r '.[0].rows_1d // 0' "$TMP/fresh.json" 2>/dev/null)
  if [ "$rows" -eq 0 ] 2>/dev/null; then
    echo "unavailable: the archive has no rows at all for the last 24h — log shipping is likely broken"
  elif [ "$lag" -gt "$STALE_AFTER_MIN" ] 2>/dev/null; then
    echo "unavailable: newest log is ${lag}min old, so an empty result proves nothing"
  else
    echo "No errors in the last ${OVERNIGHT_H}h (archive current, ${rows} rows in 24h)."
  fi
}

section_own_prs() {
  echo
  echo "## 2. Your PRs"
  if ! gh pr list --repo "$REPO_SLUG" --author "@me" --state open \
      --json number,title,isDraft,mergeable,reviewDecision,statusCheckRollup \
      --jq '[.[] | {number, title, isDraft, mergeable, reviewDecision,
                    red: [.statusCheckRollup[]? | select(.conclusion == "FAILURE") | .name]}]' \
      >"$TMP/prs.json" 2>"$TMP/prs.err"; then
    echo "unavailable: gh pr list failed ($(head -1 "$TMP/prs.err" | cut -c1-120))"
    return
  fi
  # UNKNOWN mergeability means GitHub is still computing it, not that it conflicts.
  # Advisory checks report status but never gate a merge, so they do not count as red.
  jq -r --arg advisory "$ADVISORY_CHECKS" '
    map(select(.mergeable != "UNKNOWN"))
    | map(. + {gating: [.red[] | select(test($advisory) | not)]})
    | map(select(
        (.gating | length > 0)
        or (.reviewDecision == "APPROVED" and .mergeable == "MERGEABLE")
        or (.mergeable == "CONFLICTING" and (.isDraft | not))
      ))
    | if length == 0 then "All clear."
      else (.[] |
        "- #\(.number) " +
        (if .gating | length > 0 then "CI red (\(.gating | join(", ")))"
         elif .mergeable == "CONFLICTING" then "CONFLICTING"
         else "ready to merge" end) +
        " · \(.title[0:70])")
      , "", "run /babysit-prs to action these"
      end
  ' "$TMP/prs.json" 2>/dev/null || echo "unavailable: could not parse PR list"
}

section_review_requests() {
  echo
  echo "## 3. Waiting on you"
  if ! gh pr list --repo "$REPO_SLUG" --search "review-requested:@me state:open" \
      --json number,title,author >"$TMP/reviews.json" 2>"$TMP/reviews.err"; then
    echo "unavailable: gh pr list failed ($(head -1 "$TMP/reviews.err" | cut -c1-120))"
    return
  fi
  jq -r '
    if length == 0 then "Nothing waiting."
    else "\(length) awaiting your review:", (.[] | "- #\(.number) \(.author.login) · \(.title[0:70])")
    end
  ' "$TMP/reviews.json" 2>/dev/null || echo "unavailable: could not parse review requests"
}

section_errors
section_own_prs
section_review_requests
exit 0
