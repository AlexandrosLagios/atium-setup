---
name: merge-back
description: Use when the user asks to merge a base branch (typically `development` or `main`) back into the current feature branch and push. Handles stash, conflict resolution, post-merge install, typecheck, and push. Portable fallback: prefer the repository's own merge-back skill when it ships one.
---

# merge-back

## Steps

1. `git status`. If the working tree is dirty, stash with a label: `git stash push -m "pre-merge-back" <paths>`. Pop after pushing.
2. `git fetch origin <base>`. Resolve the base from the repository's own default, do not assume `main`.
3. `git merge origin/<base> --no-edit`.
4. On conflict, resolve file by file. Pick the side that reflects the newer intentional code, usually the incoming base side when it represents a refactor or a new abstraction. Then verify nothing survived: `grep -rn '<<<<<<<\|=======\|>>>>>>>' <changed-paths>`.
   More than a couple of conflicted files, or a conflict where both sides changed the same logic: use `resolving-merge-conflicts` and work hunk by hunk from each side's intent instead of picking a side per file.
5. If the manifest or lockfile changed in the merge, take the base branch's version and re-run the install.
6. Typecheck every affected project. Do not skip this.
7. `git add` the resolved files and `git commit --no-edit`, keeping the default merge message.
8. Pop the stash if you made one.
9. `git push`.

## Rules

- Never `--no-verify`, never a blanket `-X ours` or `-X theirs`.
- Never force-push. A clean fast-forward or a true merge commit pushes normally.
- Do not rebase instead of merging unless asked. This skill is explicitly a merge.
- If the merge surfaces a pre-existing build break, such as a workspace package failing to resolve, re-run the install once before reporting it as a real failure.
