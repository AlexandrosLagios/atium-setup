---
name: flaky-ci-sentinel
description: Weekly CI flake scan. The scan script does the work; the model only classifies unknown causes and, rarely, fixes one reproducible test flake.
---

Run the scan, then act only on what it could not classify.

    ~/.claude/scheduled-tasks/flaky-ci-sentinel/scan.sh

It collects the week's runs, filters to the real flake signals, classifies causes against known signatures, diffs against `~/.local/state/flaky-ci/baseline.jsonl`, appends this week, and prints the digest. **Exit 0 means done, nothing to think about.** Print the digest and stop. Send no notification for a quiet or all-known week.

## Exit 10: unclassified causes

The script prints the log window above each unclassified error. For each one:

1. Name the actual cause from that window: the failing test or the specific error, never just the job name.
2. If it is a recurring *signature* rather than a one-off, add a matching branch to `classify()` in the script so next week classifies it automatically. **This is the point of the loop: each new cause is learned once, then never costs judgement again.**
3. Report it in the digest as a new cause and send a PushNotification.

> A learning classifier is what keeps a weekly routine cheap. Without step 2 the
> same three infra signatures burn model judgement every single week.

## Known-cause discipline

Keep a short list in this prompt of the causes already understood, each with what to do about it. The pattern that matters:

- **Infrastructure failures are counted, never fixed in-repo.** A remote build cache failing on upload, a package manager racing a restored cache, a runner aborting. The job is red for zero signal. Never wrap the failing step in `|| true`; that would swallow real failures too.
- **Cancellations near the job timeout** usually hide the real culprit, because static CI output only flushes a task's output on completion. The hanging task is the one *missing* from the list, not one of the ones shown.
- **Long deploy-gate cancellations** are usually waits, not flakes. Ignore unless a non-release workflow shows up.

## Optional fix PR, at most one per week

Only for a *test* flake, never the infra causes, and only if you reproduce it locally by running the test repeatedly. A flake must be **observed, not inferred**. If it will not reproduce, it stays digest-only.

Fix the cause: a missing await, state leaking between tests, a nondeterministic seed, an ordering assumption. Never "fix" it with retries, sleeps, or raised timeouts; that is hiding it. If that is the only available move, say so in the digest instead.

Open ONE draft PR via the `manage-pr` skill, off `<base>`, the user as reviewer, Conventional-Commits title with scope, in a fresh worktree with a meaningful conventional slug. Make all edits and commits yourself; subagents run in the main checkout and their commits leak there.

## Never

Rerun or cancel CI on any branch. Push to a shared branch. Merge anything. Comment on anyone else's PR. Modify the main checkout's working tree or branch.
