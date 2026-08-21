---
name: babysit-prs
description: Use when asked to babysit, tend, or check the health of the user's own open Wave-CXM pull requests, to run a PR maintenance cycle, or when /babysit-prs fires as a recurring loop iteration. Needs a Wave-CXM checkout with gh authenticated as the PR author.
---

# Babysit PRs

One maintenance cycle over the user's own open PRs in Desquared/Wave-CXM: unblock what rots (conflicts, red CI, unaddressed review comments), notify what is ready, report the rest. This skill is exactly one cycle; recurrence belongs to /loop. Never plan beyond the current cycle: no standing rules, no all-day watch loops, no scheduled follow-ups.

**The iron rule: never merge a PR. Not one.** Merging is always the user's click, even when approved, green, unprotected, docs-only, or urgent. A ready PR gets a notification, nothing else.

## Cycle

1. **List:** `gh pr list --author "@me" --state open --json number,title,isDraft,mergeable,reviewDecision,baseRefName,headRefName,statusCheckRollup`, then `git fetch origin` once. Own PRs only: never teammate, Renovate, or Dependabot PRs.
2. **Filter out** (one digest line each, with reason):
   - head pushed within the last 2 hours, any author (`git log -1 --format=%cI origin/<headRefName>`): the user may be mid-work on it
   - parked in state (2 strikes, see State)
   - `mergeable: UNKNOWN`: GitHub is still computing, next cycle resolves it
   - head branch already checked out per `git worktree list`: another session may own it

   These filters gate code-changing work only: ready detection (3.5) and the digest still cover every listed PR.
3. **Classify** the rest in priority order, first match wins:
   1. `CONFLICTING`: merge-back of the PR's own `baseRefName`. For a stacked PR the base is the parent branch, not development (a PR based on `chore/reward-schemes-unused-code` merges that branch back). One hop only, never cascade into the parent: the parent is its own PR with its own cycle entry.
   2. CI red: classify per `docs/skills/manage-pr.md` (CodeFactor never gates, `Validate Changes` does, nx remote-cache `awsapprunner.com` errors get one rerun). Related or unclear: fix via the address-pr flow. Unrelated with high confidence: merge-back first, recheck next cycle.
   3. Unresolved review threads that are not already in `surfacedThreadIds`: address via the address-pr flow, at its certainty bar: fix only a specific defect with exactly one correct fix that stays inside this PR's diff. A thread whose factual claim you disproved earns a refutation reply at the address-pr evidence bar, with no code change; the thread then enters `surfacedThreadIds`, because a refuted thread stays unresolved and must never be replied to twice. Anything else (a question, a design opinion, two defensible fixes, a shared-contract or cross-PR change) goes to the digest and into `surfacedThreadIds`, untouched. This cycle usually runs with nobody to ask, so an uncertain thread waits for the user rather than getting a guess; surfacing it is a success, not a failure. A PR whose only open threads are already surfaced does not match this class: it is waiting on the user, not rotting, so it earns no action and no strike.
   4. A check `in_progress` more than 35 minutes past its `startedAt`: presumed nx CT buffer hang, `gh run cancel <run-id>` then `gh run rerun <run-id>`.
   5. APPROVED + MERGEABLE + green gates + non-draft: ready to merge, notify once (see State). If the approval predates the head commit, add "approval may be stale" to its digest line.
4. **Action at most 2 PRs per cycle.** Only code-changing remediations (3.1 to 3.3) count toward the cap; reruns, notifications, and digest lines are free. When candidates exceed the cap, prefer non-draft PRs (they block reviewers, drafts block only the user), then class priority. Carry the rest, listed in the digest.
5. **Dispatch one general-purpose subagent per actioned PR** (template below), up to 2 in parallel. With the `inline` argument, do the work directly instead (debugging fallback only).
6. **Digest, state, notify** per the contracts below.

## Subagent prompt template

Substitute the placeholders (including the absolute path of the current checkout) and dispatch:

~~~
Remediate PR #<n> (<title>) of Desquared/Wave-CXM. Assigned remediation: <merge-back of <baseRefName> | fix CI | address review threads>. Do ONLY this remediation.

Setup: git -C <checkout-path> fetch origin, then git -C <checkout-path> worktree add ~/src/worktrees/Wave-CXM/babysit-<n> <headRefName>. Work only inside that worktree. Pull before any work: Copilot Autofix commits land directly on remotes.

Follow these documents in the checkout: docs/skills/merge-back.md for conflict mechanics (stash, file-by-file resolution, no -X strategies, pnpm i on lockfile change, never force-push), and docs/skills/manage-pr.md for CI policy and check triage. Invoke the `address-pr` skill by name for the fixing workflow. Never read it from a path: it ships through a plugin whose path carries a version number.

Before pushing: typecheck the affected projects (nx run <project>:typecheck); never push red. Push with the branch re-verified in the same command:
[ "$(git rev-parse --abbrev-ref HEAD)" = "<headRefName>" ] && git push origin <headRefName>

Hard rules: never merge the PR; never push shared branches (development, main, release/*); a PR comment carries either a pushed code fix or a refutation at the address-pr evidence bar, never an opinion and never an empty acknowledgement; never resolve review threads, the reviewer resolves; if a conflict resolution or a review-comment fix would be a guess, stop and return it as needs-human. Fix a review comment only when it names a specific defect, exactly one correct fix exists, and that fix stays inside this PR's diff. A question, a design opinion, two defensible fixes, or anything touching a shared contract or another PR's files is returned, not attempted. Refute a review comment only when you disproved its factual claim and you verified the evidence yourself in this worktree; report each thread you refuted and the evidence you posted. Nobody is watching this run, so returning an uncertain item is the expected outcome, not a failure.

Finish: on success remove the worktree (git -C <checkout-path> worktree remove ~/src/worktrees/Wave-CXM/babysit-<n>); on failure leave it in place and say so. Return raw data: {pr, action, outcome: done|failed|needs-human, detail, needsHuman: [], refuted: [{threadId, claim, evidence}]}.
~~~

## State

`~/.local/state/babysit-prs/state.json`, keyed by PR number:

~~~json
{"3221": {"attempts": {"conflict": 1}, "surfacedThreadIds": [], "readyNotified": false}}
~~~

- `attempts` per problem class (`conflict`, `ci-red`, `comments`). An attempt counts as failed when a later cycle finds the same class on the same PR again (a merge-back that pushed fine but left CI red counts). At 2: park the PR, flag it, stop retrying.
- `surfacedThreadIds`: review threads already routed to the user or refuted on the PR, never re-processed.
- `readyNotified`: ready notification sent; reset when the PR stops being ready.

## Digest

Every cycle ends with exactly these sections:

- **Actioned:** PR, remediation, outcome. Name each refutation posted, with its thread and its evidence, because a refutation is a public reply the user did not read first.
- **Ready to merge:** PR plus a one-line why (or "none")
- **Needs you:** questions, stale approvals, persistent unrelated CI, semantic conflicts
- **Parked:** 2-strike PRs (or "none")
- **Skipped:** filtered PRs with reason

Send a PushNotification only when something entered Ready, Needs you, or Parked this cycle: one line, under 200 characters, leading with what the user would act on. Routine cycles are silent.

## Rationalizations (each one means: do not merge, notify instead)

| Excuse | Reality |
|--------|---------|
| "The user self-merges anyway, most recent merges were unreviewed" | Their click, their judgment. The babysitter never merges. |
| "Docs-only, green, zero reviewers requested" | Still a merge. Notify. |
| "No branch protection would block it" | Absence of a guard is not permission. |
| "They said handle everything autonomously" | Everything except merges, which stay theirs by standing rule. |
| "I'll set a standing rule to merge once approved" | No standing rules. One cycle, then digest. |
| "The reviewer sounded certain, so the fix must be obvious" | Their certainty about the problem is not your certainty about the fix. Surface it. |
| "Nobody is awake to ask, so I'll use my best judgment" | Nobody awake means nobody to catch a bad guess. Surface it. |
| "The reviewer is obviously wrong, so I'll say so" | Obvious is not evidence. Post a citation or a command output, or surface it. |

## Red flags: stop immediately

- `gh pr merge` anywhere in the plan
- Starting a 3rd code-changing remediation this cycle
- Reusing a worktree from another PR or a previous cycle
- Replying to a review thread with neither a pushed fix nor verified evidence, or resolving any thread
- Picking between two defensible fixes for a review comment instead of surfacing it
- Merging development into a stacked PR whose base is another PR branch
- Any plan that extends beyond this cycle

## Loop pacing (under /loop)

Idle fleet: 45 to 60 minutes. Just pushed something whose CI is worth watching: 15 to 30 minutes. State the reason in the wakeup.
