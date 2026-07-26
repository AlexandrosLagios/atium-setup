---
name: morning-brief
description: Weekday read-only digest of overnight environment errors, own PR state, review requests, tracker priorities, calendar, one suggested first task.
---

Produce the morning brief: one read-only digest of what happened overnight and what to start on. This routine NEVER remediates anything. No code changes, no merges, no PR comments, no messages, no tracker writes, no calendar writes. It reads and reports. If you find yourself planning a fix, put it in the digest instead.

Checkout: `$REPO` (`gh` is authenticated as the user).

**Graceful degradation is mandatory.** Any section whose source fails (unauthenticated connector, missing credentials, query error) prints `unavailable: <one-line reason>` and you move on. Never abort the brief over one failure, never retry a source more than once, never attempt an OAuth flow.

Time budget: under 5 minutes. One query per section, not exploration.

## Sections 1 to 3: run the script

    ~/.claude/scheduled-tasks/morning-brief/brief.sh

The script produces the environment-errors, own-PRs, and review-requests sections as finished markdown, already classified and already degraded per section. Reproduce its output verbatim. Do not re-run the underlying log or `gh` queries, do not re-classify, do not expand on it: naming a signature is the whole job, investigating one is not. The script always exits 0; a section reading `unavailable: ...` is the intended output, not something to work around.

Only if the script fails to execute at all, print `unavailable: brief.sh failed` for sections 1 to 3 and carry on.

> Keeping the deterministic work in a script and out of the prompt is the main
> cost lever in a daily routine. The model reads output instead of deciding how
> to gather it.

## 4. Tracker

Use pinned, pre-verified queries. Do not explore the schema, do not add columns, do not drop the limits. Record the date each query was last verified next to it.

Query 1: initiatives the user drives that are actually in flight, limit 8.
Query 2: the user's near-done items (in review, in UAT), limit 20.
Query 3: load counts as a single grouped count, not rows.

Report initiatives as one line each, near-done items as at most 5 lines plus a count of the rest, and the counts as a single line.

Wide dashboard views are a trap here: they can return tens of thousands of characters per call because every row carries its summary and relation arrays, and their row order is usually not the hand-ranked one. Query the collection directly.

If the connector is unavailable, print `unavailable: <tracker> connector not authorized` and continue. Do not attempt a browser workaround. Note that a scheduled run reaches the connector fine but a subagent spawned inside one does not, so do connector work in the main loop rather than delegating it.

## 5. Today

Today's calendar events, primary calendar, local timezone. Time and title, one line each. "Nothing scheduled" is a fine answer and a useful one.

## 6. Suggested first task

Exactly one, in one line, with a one-clause why. Prefer finishing over starting, in this order: an approved PR ready to merge; a review the user is blocking; an item of theirs sitting in review or UAT; only then something new.

Do not apply a numeric WIP gate unless the column is actually maintained. A threshold that fires every single day says nothing. Report the counts as context and let the finish-before-start ordering do the work.

Skip anything already covered by an open PR of theirs. If the tracker was unavailable, pick from sections 2 and 3 and say the choice was made without it. Suggest only: do not create a worktree, branch, or tracker record.

## Output

Six headings, in order, terse. One line per item, no prose paragraphs, no advice beyond the single suggested task.

Then send exactly one PushNotification, under 200 characters, one line, leading with the most actionable thing. Send it even on a quiet morning: this is a brief the user expects daily, not an alert. No email, no chat message on their behalf.
