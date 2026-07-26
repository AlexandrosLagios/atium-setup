---
name: nightly-commit-audit
description: Weekday evening audit of the last 48h of commits on the base branch. Reports every finding, and opens at most 2 draft PRs, only for findings reproduced by a failing test.
---

Audit the last 48 hours of commits on `<base>` in `$REPO`. Work from that checkout: fetch first, do not switch its branch.

Run the repository's own change-audit skill for the audit itself (scope the surface, two review tracks, adversarial verification, group into proposals). It carries the audit logic. Skip its interactive approval gate; this run is headless, so the rules below replace it.

## Ledger (read before auditing, write at the end)

`~/.local/state/commit-audit/ledger.jsonl`, one JSON object per line: `{"date","sha","file","line","summary","status"}` where status is `reported` | `pr` | `rejected`. Create the directory and file if missing.

Read it first. Drop any finding already in it (match on file plus the substance of the summary, not exact wording) and any finding already covered by an open PR. A finding reported once never resurfaces, whatever its outcome.

## Report first

Every surviving confirmed finding goes into the digest, whether or not it becomes a PR. The digest is the primary deliverable; PRs are a bonus. For each: `file:line`, one-line defect, severity, and whether it was reproduced.

## Reproduction gate

A finding may become a PR only if you first reproduce it with a failing test in a fresh worktree. Test fails against current code, passes after the fix. No reproduction, no PR: it stays a digest item with status `reported`.

The reproduction must be **behavioural**, not a query-shape or mock-argument assertion. Existing unit tests often encode the bug, because they were written to match the buggy code, so a "was called with" assertion just mirrors what the code currently does and proves nothing. Drive the real path and assert the observable outcome. If existing tests assert the buggy behaviour, updating them is part of the fix and worth calling out in the PR description.

Findings that cannot be reproduced deterministically (races, load-dependent behaviour) are digest items only. Do not substitute a multi-agent refutation panel for the test.

When a confirmed finding sits in code the audited commits claim to cover with tests, the interesting question is why the suite missed it. Use `mutation-testing` on that one module, scoped tightly, and report the surviving mutants as a digest item of their own. A suite that survives its mutants is the finding.

## Caps and PR mechanics

- At most 2 draft PRs per run. Everything else carries over as digest items.
- One finding per PR, off `<base>`, always draft, Conventional-Commits title with scope, the user as reviewer.
- Open every PR through the `manage-pr` skill. Never `gh pr create` directly.
- Make all edits and commits yourself in the worktree. Do not delegate edits or commits to subagents; they run in the main checkout and their commits leak there.

## Never

Push to `<base>` or any shared branch. Merge anything. Comment on anyone else's PR. Modify the main checkout's working tree or branch.

## Finish

1. Append one ledger line per finding. Zero findings still gets a single line summarising the run, so a silent run is distinguishable from a broken one.
2. Print the digest: commits reviewed, findings by severity, PRs opened with links, items carried over.
3. Send a PushNotification only if there was at least one confirmed finding.
