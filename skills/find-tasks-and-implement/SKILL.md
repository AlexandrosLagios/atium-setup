---
name: find-tasks-and-implement
description: Use when the user asks to go through their open tracker tasks, plus unassigned tasks and roadmap items, and implement the clear ones unattended, for example before they sleep or leave, or when /find-tasks-and-implement runs. Triages every candidate, then dispatches up to three implementer subagents in isolated worktrees, and each implementer opens one draft PR. Not for one named task, which is the normal implementation flow, and not for upkeep of PRs that already exist, which is babysit-prs.
disallowed-tools: AskUserQuestion
metadata: {cluster: "pr-lifecycle", siblings: "babysit-prs, manage-pr, ensure-pr-readiness, subagents"}
---

# Find tasks and implement

One unattended run: find the candidate tasks, keep only the clear ones, implement
each clear task as one draft PR, and end with a digest. Nobody answers questions
during the run, so an unclear item goes to the digest, never to a guess.

`AskUserQuestion` is removed while this skill is active.

## Arguments

- A number sets the concurrency cap. The default is 3. Never exceed 3.
- `triage-only` stops after the triage table. No implementer starts.

## Iron rules

- Never merge a PR, and never mark a PR ready for review. Every PR stays a draft.
- Never write to a production database, and never apply infrastructure.
- Never change the status or the assignee of a tracker task.
- Never run more than the concurrency cap of implementers at the same time.
- Never start a second implementer on files that a running implementer edits.

## Wave-CXM tracker

| Item | Value |
| --- | --- |
| Tasks data source | `collection://7051c789-3c39-434d-a4d0-32df0bd400a3` |
| Roadmap data source | `collection://f1c9aa2f-dc9c-4c11-aef6-a2b8647ea142` |
| Title, status, assignee | `Tasks`, `Status`, `Assignee(s)` |
| Task id in SQL | `userDefined:ID` is a number: query `5310`, not `CXM-5310` |
| Base branch | `development` |
| PR title suffix | `[CXM-<id>]` |

Fetch the data source once per run and read its `<sqlite-table>` block before
the first query. A query on a missing column fails with a parse error.

In another repository, find the tracker in `AGENTS.md`, `CLAUDE.md`, or memory.
If no tracker is named, report `BLOCKED` and stop.

## Procedure

### 1. Collect the candidates

1. Get the user id from the tracker's identity call, such as `notion-get-self`.
2. Query the open tasks assigned to the user. Open means a not-started status,
   such as `Brief` or `Backlog`.
3. Query the open tasks that have no assignee.
4. Query the roadmap items that are not done and have no driver. Add their open
   child tasks that have no assignee.
5. Drop every task that already has a PR. Check the task's PR relation, then
   run `gh pr list --state all --search "CXM-<id>"`.

### 2. Triage

Dispatch one read-only subagent for the triage. The triage subagent runs no
tests and writes nothing. Give it the candidate list with the page URLs.

The triage subagent reads each task page and the code on `origin/development`.
It gives each task one verdict:

| Verdict | Meaning |
| --- | --- |
| CLEAR | The defect and the fix are stated, or one code read gives the fix. The fix fits one PR under about 300 lines of product code. |
| DECISION | An open question, options without a choice, or a product change that needs approval. |
| FIXED | The defect is gone on `origin/development`. The verdict names the commit. |
| NOT-CODE | An operation, a cloud action, a purchase, a document, or a tracker-only change. |
| TOO-BIG | The task needs several PRs or a design first. |

Ask for a table with one row per task, a confidence ranking of the CLEAR tasks,
and the pairs of CLEAR tasks that edit the same files.

With `triage-only`, report the table and stop.

### 3. Queue the clear tasks

1. Sort the CLEAR tasks by confidence, highest first.
2. For each pair that edits the same files, keep the higher-ranked task. Move the
   other task to the digest as skipped.
3. Start the first tasks up to the concurrency cap.

### 4. Dispatch the implementers

Dispatch each implementer with `subagent_type: "general-purpose"`,
`isolation: "worktree"`, and `run_in_background: true`. The worktree isolation
copies the gitignored environment files that `.worktreeinclude` lists.

When an implementer finishes, start the next queued task. Do not poll. The
completion notification starts the next step.

### 5. Report

End the run with this digest:

- **PRs opened:** the task id, the PR link, and one line on the change.
- **Needs you:** each DECISION task and each implementer that returned
  `needs-human`, with the question.
- **Skipped:** each FIXED, NOT-CODE, TOO-BIG, and conflicting task, with the
  reason.
- **Failed:** each implementer that failed, with the worktree path it left.

Send one push notification when the run ends, if the tool exists. Keep the
notification under 200 characters, and lead with the count of PRs opened.

## Implementer prompt template

Replace each placeholder before the dispatch:

~~~
Implement tracker task <CXM-id> "<title>" (<task URL>) in <repository> as one draft PR. Nobody watches this run. When the task turns out to need a decision, stop and return needs-human with the question.

Setup: your shell starts in an isolated worktree. Run git fetch origin <base>, then git switch -c <type>/<short-slug> origin/<base>. The branch name is a Conventional Commits slug, ASCII only, 64 characters at most. Never keep the generated worktree branch name. Run pnpm i.

Read the task page and its comments. Read AGENTS.md and the rule docs it links before you design the change.

Work test first: write the regression test, watch it fail, then fix. Run only the test files you touch, from the app directory, with --maxWorkers=2. Never run a whole project suite. Typecheck the affected projects.

Open the PR with the repository's manage-pr skill, as a draft, based on <base>, with the title suffix [<CXM-id>]. Never mark the PR ready, never merge, never push a shared branch. Re-verify the branch in the same command as the push.

Never write to a production database, apply infrastructure, or change the tracker task status or assignee.

Return raw data: {task, outcome: pr-opened|needs-human|already-fixed|failed, pr, branch, worktree, detail}.
~~~

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "The task is almost clear, so I will pick the likely fix" | A guess at night is a wrong PR in the morning. Put the task in Needs you. |
| "Four implementers finish sooner than three" | The laptop runs out of memory. Keep the cap. |
| "The PR is green, so I will mark it ready" | Every PR stays a draft. The user promotes it. |
| "I will move the task to In progress so nobody else takes it" | The task status belongs to the user. Report the PR instead. |
