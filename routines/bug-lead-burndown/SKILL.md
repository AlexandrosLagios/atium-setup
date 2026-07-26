---
name: bug-lead-burndown
description: Burn down a fixed backlog of bug leads produced by an earlier convention sweep, one or two per run.
---

Work the bug-lead backlog in `$REPO`. Ledger: `~/.local/state/bug-lead-burndown/ledger.jsonl`, one lead per line: `{id, status, class, file, line, description, source}`, where status is `open` | `fixed` | `invalid` | `needs-human`, `note` is set when invalid or needs-human, and `pr` when fixed.

Change a lead's status only through the helper next to the ledger, never by hand-editing:

    node ~/.local/state/bug-lead-burndown/update-lead.mjs <id> <status> [note-or-pr]

It prints how many leads are still open.

The ledger is the source of truth. If it does not exist or has no `open` entries, stop immediately. Entries but none open: disable this scheduled task and send a PushNotification saying the backlog is drained. Missing entirely: send a PushNotification asking for a reseed and stop.

> A finite backlog needs a termination condition in the prompt. Without the
> self-disable, a drained routine keeps firing forever and costs a run every day
> to discover it has nothing to do.

If a knowledge graph exists for the repo, query it to orient before reading source files, and pass that same rule to every subagent you dispatch.

Each run:

1. Pick 1 or 2 `open` leads. Prefer leads sharing a `class` with recently fixed ones, so a class gets completed rather than sampled at random. Take `observation`-class leads last: the sweep author flagged those as pre-existing behaviour worth noting, not defects, so most should end up `invalid`.
2. Dedup against open PRs. Skip any lead whose files are touched by one. Mark nothing; leave it `open` and pick another.
3. Re-verify the lead against current code. The sweep is old and the code moves. Already fixed or simply wrong: set `invalid` with a `note` giving the reason, and move on.
   Re-derive reachability yourself; do not trust the lead's stated cause. The notes were written by agents with a single file in scope, so their reasoning about callers is often wrong even when the defect is real. **A wrong stated cause is not grounds for `invalid`. Only an absent defect is.**
4. Reproduce it with a failing test in a fresh worktree, named from the lead with a meaningful conventional slug, never an auto-generated name. If you cannot make a test fail, set `needs-human` with a `note` recording exactly what you tried, and move on. Never fix a lead without a reproducing test.
5. Fix minimally. Keep the regression test. Run the filtered tests for the affected project and typecheck the affected packages.
   Then use `variant-analysis` on the fixed defect to find its siblings. A defect the sweep found once is usually a pattern: append every new instance to the ledger as an `open` lead with `source` naming this run, and if the pattern is mechanical enough to express as a rule, write it with `semgrep-rule-creator` so it cannot come back. Do not fix the siblings in this PR.
6. **Critic pass.** Read the full diff yourself, or dispatch a subagent whose only job is this, looking for behaviour changes smuggled in alongside the fix: log-level bumps that would flood a production alert stream, switch-to-lookup-map rewrites that turn a silent skip into a throw, logger-key or string renames that break tests asserting those strings and any saved log search pinned to them. Revert anything the lead did not require.
7. Open a **draft** PR with the `manage-pr` skill, never raw `gh pr create`. The user as reviewer, Conventional-Commits title with scope. One lead per PR, except that several leads of the same `class` in the same module may share one PR if the diff stays small. Set the lead's status to `fixed` with the PR number.

Caps and hard rules:

- Max 2 draft PRs per run. Stop at the cap even if leads remain.
- Never push a shared branch, never merge, never mark a lead `fixed` without an opened PR.

Reporting:

- Append one line per run to `~/.local/state/bug-lead-burndown/runs.jsonl` as `{"run": "<ISO date>", "summary": "...", "open": <count>}`. Keep it out of the ledger so the two files stay separately parseable.
- Send a PushNotification only if a PR was opened or the backlog reached zero. Silent otherwise.
