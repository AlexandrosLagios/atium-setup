#!/usr/bin/env bash
# Assembles the numeric half of the monthly cost digest: last 30 days across
# every dimension, then the 30 days before that by skill so the routine can
# state a direction rather than a snapshot.
#
# Never exits non-zero: a missing transcript directory prints one line and the
# digest still ships.
set -uo pipefail

# The routine directory is symlinked into ~/.claude/scheduled-tasks, so resolve
# the physical path to reach the repository's scripts.
task_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cost="$task_dir/../../scripts/agent-cost"

if [ ! -x "$cost" ]; then
  echo "unavailable: agent-cost not found at $cost"
  exit 0
fi

echo "# This month"
"$cost" --days 30 --by skill --by model --by project --by day --limit 12 \
  || echo "unavailable: agent-cost failed for the current window"

echo
echo "# Previous month, by skill (for direction only)"
"$cost" --days 30 --offset-days 30 --by skill --limit 12 \
  || echo "unavailable: agent-cost failed for the prior window"

exit 0
