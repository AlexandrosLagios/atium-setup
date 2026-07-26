---
name: tracker-drift-sweep
description: Weekly sweep of the user's merged PRs whose linked tracker tasks were never updated. Auto-advances only their own merged-but-stale tasks one status, digests everything else.
---

Find the user's PRs merged in the last 7 days whose linked tracker task was never updated, fix the mechanical drift on their own tasks, and digest the rest.

Checkout: `$REPO` (`gh` authenticated as them, repo `<org>/<repo>`). Never switch that checkout's branch. This loop touches the tracker only: it never edits code, opens PRs, or merges anything.

Tracker access: use the authenticated connector. If a second, unauthenticated server for the same tracker is also configured, never use it. If the connector fails, print `unavailable: connector not authorized` and stop. Never attempt an OAuth flow or a browser workaround.

Ids: tasks collection `<tasks-collection-id>`, initiatives collection `<roadmap-collection-id>`, the user `<user-id>`.

## 1. Collect the window

List merged PRs authored by the user in the last 7 days. Keep only titles carrying a tracker id suffix. **Group by tracker id, not by PR.** One task routinely has many PRs, and the id is the unit of work for the rest of this run.

## 2. Read the tracker state

One query for the whole batch, selecting id, title, status, assignees, PRs, parent, and url, filtered by `id IN (...)`.

## 3. Classify

**Auto-fix (mechanical). All four must hold:**

1. The user is the sole assignee, and
2. current status is exactly the one or two statuses that precede the target, and
3. no open PR of theirs still carries that task id, verified per id, and
4. at least one PR for it merged inside the window.

The only write is a **single status transition**, one step forward.

**Never write the terminal status.** A merge lands on the base branch; done comes after deploy and acceptance, which a merged PR does not evidence. Writing it here would be a false record.

**Digest only, never write** for anything else, in particular:

- Any item where the user is not the assignee, or is one of several. A teammate item stays untouched.
- An early status with merged PRs. That is an anomaly, not mechanical drift: the task skipped the workflow rather than lagging it. Report it and let them decide.
- A status already at or past the target. No drift, do not report.
- Content drift: a stale solution section, an analysis describing the plan rather than the shipped code, API examples to mirror, companion tasks to create. These need judgment and belong to the interactive sync skill. **List them, do not perform them here.**

Do not open the interactive sync skill to do the work autonomously. This loop performs the single status transition above and nothing richer.

## 4. Caps

At most **5 tracker ids per run**, ids not PRs, oldest merge first. Carry the rest to next week and say in the digest how many were carried and which.

## 5. Ledger

`~/.local/state/tracker-drift/swept.jsonl`, one object per line: `{"week","id","prs","before","after","action"}` where action is `fixed` | `digested` | `anomaly` | `teammate`. Create the directory and file if missing.

Read it before reporting: an id already logged as `digested` at the same status in a prior week gets one summary line, not a repeat writeup. Append every id you touched or considered, including on a clean week, so a quiet run is distinguishable from a broken one.

## Never

Edit a teammate-assigned item. Delete or archive tracker content. Touch ownership fields. Write to an initiative's solution section. Set the terminal status. Create or close tasks. Comment on anyone's PR. Send email or chat messages.

## Finish

Print the digest: PRs scanned, ids in window, each id as one line (`ID · title · before → after`, or `· digest reason`), anomalies, teammate items skipped, carried-over count.

Send a PushNotification only if something was fixed or something needs them. A clean sweep is ledger lines and no notification.
