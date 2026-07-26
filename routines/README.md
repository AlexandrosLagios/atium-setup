# Routines

Sample scheduled routines (Claude Code "scheduled tasks"), kept here as reusable
shapes rather than as a mirror of any live account. Every reference to a private
repository, tracker id, or environment has been replaced with a placeholder.

## What a routine is

Two halves, stored in two different places:

| Half | Where | Travels by |
|------|-------|-----------|
| Prompt and support files | `~/.claude/scheduled-tasks/<id>/` (`SKILL.md`, plus any `.sh` or `.sql`) | file copy or symlink |
| Schedule (cron, enabled, notify, jitter) | account-side state, not on disk | one `create_scheduled_task` call per account |

There is no export or import. Copying the directory gives you the prompt and
nothing that fires it.

## Keeping routines synced across accounts

Prompts sync through git. Schedules do not, and have to be registered once per
account.

```sh
scripts/install-routines --dry-run   # show what would link
scripts/install-routines             # symlink routines/<id> into ~/.claude/scheduled-tasks/
```

The installer only ever creates symlinks and refuses to touch an existing path,
so it cannot overwrite a live routine you already have. After that, `git pull`
propagates every prompt edit to every machine with no copy step.

Then register the schedules on the new account, once:

> Read `routines/schedules.tsv`. For each row, read
> `~/.claude/scheduled-tasks/<taskId>/SKILL.md`, and call `create_scheduled_task`
> with that `taskId`, the row's `cron`, the frontmatter `description`, and the
> file body after the frontmatter as `prompt`, verbatim. Use
> `update_scheduled_task` for any that already exist. Then show me
> `list_scheduled_tasks`.

Cron is evaluated in local time, not UTC. The several-minute dispatch jitter is
applied automatically; do not try to reproduce it.

Runtime state (`~/.local/state/<routine>/`) is a third thing again and syncs
through neither. Ledgers restart empty on a new machine unless you copy them,
which makes already-reported findings resurface once.

## Placeholders

| Token | Meaning |
|-------|---------|
| `$REPO` | absolute path to the main checkout the routine works in |
| `<org>/<repo>` | the code host slug |
| `<handle>` | the user's code-host handle |
| `<base>` | the repository's base branch |
| `<tasks-collection-id>`, `<roadmap-collection-id>`, `<user-id>` | tracker ids |

## What makes these work unattended

The prompt bodies are longer than they look like they need to be, on purpose.
A scheduled run has nobody to ask, so every guardrail has to be in the prompt:

- **A hard cap per run.** Two PRs, five records, one fix. The overflow carries to
  the next firing rather than being handled now.
- **A ledger.** A JSONL file under `~/.local/state/` that makes a quiet run
  distinguishable from a broken one, and stops a finding resurfacing every week.
- **An explicit Never list.** Never merge, never push a shared branch, never
  comment without a code fix, never write the terminal status.
- **A notification policy.** Most routines stay silent unless something needs a
  human. Only the daily brief notifies unconditionally.
- **Graceful degradation.** A failed source prints `unavailable: <reason>` and
  the run continues. One dead connector never aborts the routine.
- **Uncertainty routes to the digest.** Anything needing a semantic guess gets
  surfaced, not guessed. Surfacing is the expected outcome, not a failure.
