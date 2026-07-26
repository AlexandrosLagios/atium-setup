---
name: agent-cost-digest
description: Monthly read-only digest of agent spend by skill, routine, project, and model, naming the workloads whose cost is not paying for itself.
---

Report where agent spend went last month and name what to change. This routine reads and reports. It never edits a skill, disables a routine, or changes a model default: those are the user's calls, made from the digest.

## 1. Run the script

    ~/.claude/scheduled-tasks/agent-cost-digest/report.sh

It produces the whole numeric picture: totals by skill, project, model, and day for the last 30 days, plus the same by-skill table for the 30 days before that so a trend is visible. Reproduce its tables rather than recomputing anything.

> Keeping the arithmetic in a script and out of the prompt is the cost lever in
> a monthly routine. The model reads output and judges it; it does not gather it.

The figures are API list-price equivalent, not an invoice: a subscription plan does not bill per token. Say that once in the digest. The comparison between workloads is the signal; the absolute number is not.

## 2. Judge, do not just restate

For each of the five most expensive skills or routines, answer one question: what did the spend buy? The evidence is already on disk.

- A routine with a run ledger (`~/.local/state/<routine>/runs.jsonl` or its digest output) shows what each run produced. A routine that spent real money and opened nothing, found nothing, and reported nothing for a month is the finding.
- A skill whose cost is concentrated in one project is doing project work, not skill work. Note it; that is usually fine.
- A skill that appears with a large share and no matching artefacts (PRs, tracker updates, digests) is the interesting case. Say so plainly rather than assuming waste: a review skill that finds nothing on a clean month is working.

Attribution is partial by design. Only messages inside a skill carry its name, so the unattributed share is the largest line and means nothing on its own. Do not report it as a problem.

## 3. Digest

Print, in this order:

1. One line: total, message count, and the list-price caveat.
2. Spend by skill or routine, top 10, with the month-over-month direction for each.
3. Spend by model, all rows. Note any workload sitting on a more expensive tier than its task needs.
4. Spend by project, top 5.
5. At most three recommendations, each naming one workload, one change (drop the model tier, lower the cadence, narrow the scope, retire it), and the evidence from step 2. No recommendation is a valid outcome; say the month looks proportionate instead of inventing one.

Then send exactly one PushNotification, under 200 characters, leading with the total and the single most actionable recommendation.

## Never

Change a schedule, edit a skill, or delete a transcript. Recommend retiring a routine on cost alone without the ledger evidence from step 2. Treat the unattributed share as waste.
