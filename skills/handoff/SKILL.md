---
name: handoff
description: Use when compacting the current conversation into a durable brief that a fresh session picks up later, or when asked to write a handoff or a prompt for the next session. Do not use it to reach a session that already runs, which needs a cross-session message, and do not use it to continue this same conversation elsewhere, which needs a session resume. Takes an optional argument that names what the next session focuses on.
---

# handoff

Write a handoff document that lets a fresh agent continue the work.

## Route first

A handoff document is for a session that does not exist yet. Two neighbouring cases need a different tool:

- The target session already runs. Send it a message instead. In the desktop app, use `send_message`. In the terminal, use `SendMessage`. Do not write a document.
- The work continues in the same conversation, in another terminal or another window. Resume or fork the session instead. Do not write a document.

Continue with this skill only when a fresh session must start with curated context.

## Write the document

Create the file under the local state directory:

```sh
dir="${XDG_STATE_HOME:-$HOME/.local/state}/superpowers/$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")/handoffs"
mkdir -p "$dir"
path="$dir/$(date +%F)-<short-topic>-handoff.md"
```

Replace `<short-topic>` with the actual topic. Read the file before you write to it. Do not commit the document.

Write these sections:

- **Goal**: what the work must accomplish.
- **Current Progress**: what is done so far.
- **What Worked**: approaches that succeeded.
- **What Didn't Work**: approaches that failed, briefly, so the next session does not repeat them.
- **Repo State**: the branch name, what is committed, what is pushed, and what is still uncommitted. A new session gets its own worktree and cannot see uncommitted work. If the next session needs work that is still dirty, say so and name the commit it must wait for.
- **Next Steps**: the action items that continue the work.

Suggest the skills the next session should use, if any.

Do not duplicate content that other artifacts already capture, such as specs, plans, ADRs, issues, commits, or diffs. Reference them by path or URL instead.

If the user passed arguments, treat them as a description of what the next session focuses on, and tailor the document to it.

## Offer a new session

After you write the document, offer to start the work:

- If the `spawn_task` tool is available, call it with a prompt that reads `Read <absolute path to the document> and continue the work.` The user gets a chip that starts a new session with its own worktree. The chip is a suggestion, so do not ask for confirmation first.
- Otherwise, report the absolute path and tell the user to open a new session against it.
