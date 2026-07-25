---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it under a fresh temp directory with a descriptive filename — e.g. ``dir=$(mktemp -d) && path="$dir/handoff-<short-topic>.md"`` (replace `<short-topic>` with the actual topic). Read the file before you write to it.

Create or update the document with:
- **Goal**: What we're trying to accomplish
- **Current Progress**: What's been done so far
- **What Worked**: Approaches that succeeded
- **What Didn't Work**: Approaches that failed (so they're not repeated), briefly
- **Next Steps**: Clear action items for continuing

Suggest the skills to be used, if any, by the next session.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
