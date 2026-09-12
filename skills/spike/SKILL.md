---
name: spike
description: "Use when the deliverable is understanding or a solution to a problem, with or without code: research a topic, investigate a behaviour, brainstorm, weigh options, or decide an approach. Reads every source first, interviews the user one question at a time until every aspect that is not straightforward is settled, and writes a spike document. Not for a question the code answers in one read, and not for a design that ends in a spec, which is shape."
---

# spike

Turn a question or a problem into a spike document: what the sources say, what
the user decided, which approaches exist, and which one to take. A spike writes
no code.

## Explore

Assess the scope first. When the topic spans several independent subsystems,
say so, and spike the first one.

Read before you ask:

- Inside a repository: the code, the docs, and the recent commits.
- For any topic: the web.
- Notion, Slack, Gmail, and Drive, when the topic names a project, a ticket, or
  a person that those hold.

Read only. Never write, send, or create anything in a connected source.

Post a findings brief before the first question. Cite each source by path or
URL.

## Interview

Ask one question per message. Give a recommended answer with the reasoning.
Prefer a multiple-choice question.

Never ask what a source can answer. When an answer opens a gap you can close
yourself, research the gap before the next question.

Ask about every aspect of the problem that is not straightforward. That covers
the purpose, the constraints, the success criteria, the context you do not
have, and each branch that an answer opens. Resolve the dependencies between
decisions one by one.

Stop only when you are certain that the user has been interviewed about every
aspect that is not straightforward. Say so in one line, then draft.

Append each decision to the document as it lands. A compacted session then
loses nothing.

## Approaches

Propose 2 to 3 approaches with their trade-offs. Lead with the recommended one
and state why. When the topic is a question with no choice to make, write that
in the section instead.

## Write the document

Compute the path:

```sh
dir="${XDG_STATE_HOME:-$HOME/.local/state}/superpowers/$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")/spikes"
mkdir -p "$dir"
path="$dir/$(date +%F)-<short-topic>-spike.md"
```

Replace `<short-topic>` with the topic. Create the file after the findings
brief, and append to it during the interview. Do not commit the document.

Write the prose under `write-technical-content`. Write these sections:

- **Problem**: what the spike set out to answer.
- **Findings**: what the research established, each item with its path or URL.
- **Decisions**: one item per answer that closed a branch, as the question, the
  decision, and the reason.
- **Open questions**: what stays unresolved, and who resolves it.
- **Approaches**: the 2 to 3 approaches, their trade-offs, and the
  recommendation.
- **Next step**: `shape`, a ticket, or nothing.

## Publish

When the argument or the user names a Notion parent, create a page under it
with the same six sections. Write that page under `write-notion-content`.

## Close

Report the path. When the next step is design, the closing line names
`/shape <path>`. Never invoke `shape` yourself.
