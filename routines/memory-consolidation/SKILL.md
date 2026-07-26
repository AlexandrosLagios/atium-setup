---
name: memory-consolidation
description: Monthly consolidation pass over one project's agent memory directory: back up, merge duplicates, retire finished work, repair the index.
---

Consolidate the project memory directory at `~/.claude/projects/<project-slug>/memory/`. That directory is the only thing in scope. Never touch another project's memory.

## 1. Back up first

```sh
mkdir -p ~/.local/state/memory-backups
tar -czf ~/.local/state/memory-backups/<project>-$(date +%F).tar.gz \
  -C ~/.claude/projects/<project-slug> memory
```

Then delete all but the 3 newest tarballs. Memory edits are not in git; this is the only undo.

## 2. Consolidate

Run the `consolidate-memory` skill. It carries the method: take stock, merge overlaps, separate durable from dated, fix time references, tidy the index. Do not restate it.

These constraints sit on top of it:

- **Never delete a `feedback`-type memory on staleness grounds.** Those encode standing rules and outlive any project. Only clear duplication justifies merging two of them.
- **A code claim you cannot re-verify against the current repo gets marked, not deleted.** Append `_Unverified as of <YYYY-MM-DD>._` to the body and leave the fact in place.
- **A `project` memory whose PRs are all merged and whose follow-ups are closed is done.** Retire the file and fold any lasting lesson into a `reference` or `feedback` memory.
- **`MEMORY.md` is one line per memory, no content in the index.** Truncated half-sentences left from earlier edits are the drift to repair, not a style to match. Lines that have grown into summaries get cut back; the detail belongs in the topic file.
- **Do not rename surviving files or their `name:` fields.** Wiki-links across the directory resolve against a mix of filename stems and `name:` values, so a rename pass breaks links silently. A merge keeps the survivor's existing path and name. Frontmatter dialect differences are cosmetic; leave them.

## 3. Digest

Print, and send as a one-line PushNotification:

- counts of merged, retired, rewritten, marked-unverified
- the names of every retired and merged file
- anything flagged stale but unverifiable
- the backup path

## Never

Delete the backup you just took. Touch files outside the memory directory. Commit anything.
