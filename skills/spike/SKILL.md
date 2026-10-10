---
name: spike
description: "Use when the deliverable is understanding, a decision, or a design: research a topic, investigate a behaviour, brainstorm, weigh options, decide an approach, or design a feature before a plan. Reads every source first, interviews the user one question at a time until every aspect that is not straightforward is settled, and writes a spike document that grows into an approved design when the next step is to build. Not for a question the code answers in one read."
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
whether that document is the input. Continue from the first open item: an open
question, the approaches, or the design. Never ask again what the document
settles.

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

Replace `<short-topic>` with the topic. When the project's `AGENTS.md` or
`CLAUDE.md` names a `superpowers/` namespace, use that namespace in place of the
repository name, and keep the `spikes` directory. Create the
file after the findings brief, and append to it during the interview. Do not
commit the document.

Write the prose under `write-technical-content`. Write these sections:

- **Problem**: what the spike set out to answer.
- **Findings**: what the research established, each item with its path or URL.
- **Decisions**: one item per answer that closed a branch, as the question, the
  decision, and the reason.
- **Open questions**: what stays unresolved, and who resolves it.
- **Approaches**: the 2 to 3 approaches, their trade-offs, and the
  recommendation.
- **Next step**: the design, a ticket, or nothing.

## Design

When the next step is to build, ask the user whether to start the design now,
and wait for the answer.

1. Design the recommended approach, unless the user picked another one.
2. Present the design in sections: architecture, components, data flow, error
   handling, and testing. Scale each section to its complexity.
3. Ask for approval after each section. Revise a section that the user rejects.
4. Append the approved design to the document as a **Design** section.
5. Read the document again for placeholders, contradictions, ambiguity, and
   scope. Fix each problem in place.
6. Ask the user to review the document, and wait for the approval.

Apply these principles to the design:

- Split the system into units with one purpose each. For each unit, state what
  the unit does, how to use the unit, and what the unit depends on.
- In an existing codebase, follow the existing patterns. Include a targeted
  improvement when an existing problem blocks the work.
- Remove every feature that the work does not need.

Do not invoke `writing-plans` before the user approves the document. After the
approval, invoke `writing-plans` with the document path, unless the
workflow-altitude rule skips the plan for the tier.

## Publish

When the argument or the user names a Notion parent, create a page under it
with the same sections. Write that page under `write-notion-content`.

## Close

Report the path. When the user stops before the design, the closing line names
`/spike <path>`, which resumes the document later.
