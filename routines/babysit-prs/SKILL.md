---
name: babysit-prs
description: PR maintenance cycle over the user's own open pull requests: merge-back conflicts, fix branch-caused CI reds, address review threads, notify when ready to merge. Never merges.
---

Run one cycle of the PR maintenance routine over the user's own open pull requests in `<org>/<repo>`.

Checkout: `$REPO` (`gh` is authenticated as the PR author).

Read and follow the `babysit-prs` skill exactly. It is the single source of truth for the cycle: list the user's own open PRs, filter (push-freshness guard, PRs parked after 2 strikes, unknown mergeability, branches already checked out in another worktree), classify in priority order (conflicting, CI red, unresolved review threads not already surfaced, CI hung past the timeout, ready to merge), action at most 2 code-changing remediations via one subagent per PR in its own fresh worktree, then write the digest and update state at `~/.local/state/babysit-prs/state.json`.

Non-negotiable guardrails, restated here because this fires unattended. Do not relitigate them:

- **NEVER merge a PR.** Not one. Approved, green, unprotected, or urgent does not change this. A ready PR only ever gets a PushNotification; the click is always the user's.
- Never push to a shared branch.
- Never post a PR comment unless it accompanies an actual pushed code fix. Never resolve a review thread; only the reviewer resolves.
- Cap at 2 actioned PRs per cycle. Carry the rest silently to the next firing.
- If a remediation would require a semantic guess (an ambiguous conflict resolution, a judgment-call review comment), stop and route it to the digest's "Needs you" section instead of guessing.
- Review comments have a high certainty bar: fix one only when it names a specific defect, exactly one correct fix exists, and that fix stays inside this PR's diff. A question, a design opinion, two defensible fixes, or anything touching a shared contract or another PR's files goes to "Needs you" untouched. This run has nobody to ask, which is a reason to attempt less, not to trust your own judgment more. Surfacing an uncertain thread is the expected outcome, not a failure.

End with the digest sections: Actioned, Ready to merge, Needs you, Parked, Skipped. Send exactly one PushNotification only if something newly entered Ready, Needs you, or Parked this cycle: one line, under 200 characters, leading with what the user would act on. Stay silent on routine cycles where nothing changed. No email, no message on the user's behalf.
