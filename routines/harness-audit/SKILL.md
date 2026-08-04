---
name: harness-audit
description: Weekly audit of the agent harness itself. The scan script does the work; the model judges only what it cannot count, and fixes the silent breakage in place.
---

Run the scan, then act only on what it could not judge.

    ~/src/Personal/atium-setup/scripts/audit-harness --repo <primary-repo>

**No output means done.** Print "no drift" and stop; send no notification for a
clean week. Otherwise use the `audit-harness` skill and work the findings in
severity order.

## Fix in place, this run

These are silently wrong and nothing else will catch them. Do them yourself
rather than reporting them:

- **plugin-drift** — bump the plugin version in the three manifests, run
  `scripts/refresh-plugins`, and confirm the cached skill set now matches
  `skills/`. Confirm by listing the cache, not by trusting the update message:
  a version-matched update reports success and copies nothing.
- **dead-config** — delete the hook entry or permission rule. If the hook was
  meant to exist, restore the file it points at instead.
- **collision** — add one clause to the portable skill's description naming the
  repository-specific one as the winner.

## Judge, then propose

- **hook-noise** — before proposing anything, count how often the behaviour the
  hook demands actually occurred in the same transcripts. Report the ratio.
  Below roughly one in twenty, propose deleting the hook and say what already
  covers the rule without it. Never delete a hook on the injection count alone.
- **routine-drift** — a live task with no copy in the repository is one machine
  failure from gone; write the genericized copy. A sample that never installed
  is either wanted or dead, and a year of not installing it answers that.
- **worktree** — never remove one. List the merged branches with their dirty
  state and let the user run the removals.

## Cap

At most **one** behaviour change per run (a hook removed, a routine retired),
plus any number of the fix-in-place repairs above. A harness edited faster than
it is observed cannot be evaluated. Anything past the cap goes in the digest as
a recommendation.

## Track what was measured

Append one line per run to `~/.local/state/harness-audit/ledger.tsv`:
date, finding count by severity, what changed, and the ratio behind any
deletion. Next week's audit reads it first, so a finding that was deliberately
left alone is not re-litigated, and a deletion that turns out wrong can be
traced to the number that justified it.

## Never

Touch a shared branch. Delete a worktree, a memory file, or accumulated tool
data. Uninstall a third-party tool. Edit a repository's tracked settings
without opening a PR for it. Change more than the cap allows.
