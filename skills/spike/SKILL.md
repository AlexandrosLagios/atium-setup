---
name: spike
description: "Use when the deliverable is a decision or a design, or an investigation that spans more than one session: brainstorm, weigh options, decide an approach, or design a feature before a plan. Reads the sources first, asks the user only the decisions that change the outcome, and writes a spike document that grows into an approved design when the next step is to build. Not for a question that this session answers with no decision for the user, such as a question the code answers in one read."
---

# spike

Turn a question or a problem into a spike document: what the sources say, what
the user decided, which approaches exist, and which one to take. When the work
continues into a build, the same document also carries the approved design.

A spike writes no code. Never invoke an implementation skill from a spike. A
workflow-altitude rule in `CLAUDE.md` or `AGENTS.md` outranks this skill: that
rule decides whether a task gets a spike, a design, and a plan.

## Resume

When the argument is a spike document, read the document once. Without an
argument, look in the spike directory for a document on the same topic, and ask
whether that document is the input. Continue from the first open item. Never
ask again what the document settles.

## Explore

When the topic spans several independent subsystems, say so, and spike the
first one.

Read the code, the docs, the recent commits, and the web before you ask. Read
Notion, Slack, Gmail, and Drive when the topic names a project, a ticket, or a
person that those sources hold. Never write, send, or create anything in a
connected source.

Post a findings brief before the first question. Cite each source by path or
URL.

## Interview

Ask only the decisions that change the outcome and that no source answers. Ask
5 decisions at most. For every other branch, take the default that the sources
and the existing patterns support. Record that default in the document.

- Batch the decisions that do not depend on each other into one multiple-choice
  prompt, such as one `AskUserQuestion` call in Claude Code.
- Ask a decision that depends on an earlier answer in a later message.
- Give each question a recommended answer with the reasoning.

When an answer opens a gap that you can close yourself, research the gap before
the next question. When more than 5 decisions stay open, the topic is too wide.
Say so, and spike the first part.

Append each decision to the document as it lands. A compacted session then
loses nothing.

## Write the document

Compute the path:

```sh
dir="${XDG_STATE_HOME:-$HOME/.local/state}/superpowers/$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")/spikes"
mkdir -p "$dir"
path="$dir/$(date +%F)-<short-topic>-spike.md"
```

Replace `<short-topic>` with the topic. When the project's `AGENTS.md` or
`CLAUDE.md` names a `superpowers/` namespace, use that namespace in place of the
repository name, and keep the `spikes` directory. Create the
file after the findings brief, and append to it during the interview. Do not
commit the document.

Write the prose under `write-technical-content`. Write these sections:

- **Problem**: what the spike set out to answer.
- **Findings**: what the research established, each item with its path or URL.
- **Decisions**: one item per closed branch, as the question, the decision, and
  the reason. Mark each default that you took without a question as a default.
- **Open questions**: what stays unresolved, and who resolves it.
- **Approaches**: 2 to 3 approaches and their trade-offs, with the recommended
  approach first. When the topic has no choice to make, write that instead.
- **Next step**: the design, a ticket, or nothing.

## Design

When the next step is to build, ask the user whether to start the design now,
and wait for the answer.

Design the recommended approach, unless the user picked another one. Cover the
architecture, the components, the data flow, the error handling, and the
testing. Scale each part to its complexity.

- When the interview settled 3 or fewer decisions, present the design as one
  block, and ask for one approval.
- For a larger design, present one section at a time, and ask for an approval
  after each section.

Revise a section that the user rejects. Append the approved design to the
document as a **Design** section. The approval of the design also approves the
document.

Do not invoke `writing-plans` before the approval. After the approval, invoke
`writing-plans` with the document path, unless the workflow-altitude rule skips
the plan for the tier.

## Publish

When the argument or the user names a Notion parent, create a page under it
with the same sections. Write that page under `write-notion-content`.

## Close

Report the path. When the user stops before the design, the closing line names
`/spike <path>`, which resumes the document later.
