---
name: shape
description: "Use when the user invokes /shape, or when the workflow-altitude rule names shape for a feature tier, and never otherwise. Turns a spike document into an approved design and a spec, then hands off to writing-plans. Never triggers on brainstorming, research, or weighing-options wording, which is spike."
---

# Shaping a spike into a design

Turn a spike document into an approved design and a spec through collaborative
dialogue. The interview and the approaches live in `spike`. This skill starts
where that document ends.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Scope

A workflow-altitude rule in `CLAUDE.md` or `AGENTS.md` outranks this skill where
it sets one. Where that rule routes a trivial one-liner or a small bugfix to a
direct edit, take the direct edit and do not run this skill. This skill owns the
tiers that rule leaves to design: a self-contained feature, a large multi-task
feature, and a cross-service change.

## Input

The argument is the path to a spike document. Without an argument, offer the
newest document under the project's spike directory, and ask whether that
document is the input:

```sh
ls -t "${XDG_STATE_HOME:-$HOME/.local/state}/superpowers/$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")/spikes" 2>/dev/null | grep -- '-spike.md$' | head -1
```

Without any document, invoke `spike`, and resume from the document it writes.

Read the Decisions, Approaches, and Open questions sections. Never ask again
what the document settles. When the design opens a question the document does
not settle, ask that question alone, with a recommended answer, and wait for
the reply.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Read the spike document**: Decisions, Approaches, Open questions
2. **Present design**: in sections scaled to their complexity, get user approval after each section
3. **Write design doc**: save to the local spec dir (default `${XDG_STATE_HOME:-$HOME/.local/state}/superpowers/<project>/specs/YYYY-MM-DD-<topic>-design.md`); do NOT commit it (see below)
4. **Spec self-review**: quick inline check for placeholders, contradictions, ambiguity, scope (see below)
5. **User reviews written spec**: ask user to review the spec file before proceeding
6. **Transition to implementation**: invoke writing-plans skill to create implementation plan

**The terminal state is invoking writing-plans.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The ONLY skill you invoke after the design is writing-plans.

## The Process

**Presenting the design:**

- Design the approach the spike document recommends, unless the user picked another one there
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.

## After the Design

**Documentation:**

- Specs, plans, and handoffs are local working artifacts and must NOT be committed to the repo. Write the validated design (spec) under an XDG state directory, namespaced per project:
  - Default: `${XDG_STATE_HOME:-$HOME/.local/state}/superpowers/<project>/specs/YYYY-MM-DD-<topic>-design.md` (use the repo/project name as `<project>`)
  - If the project's `AGENTS.md`/`CLAUDE.md` specifies a spec/plan location or namespace, follow that instead (e.g. Wave-CXM uses `superpowers/wave-cxm/`).
- Cite the spike document by path. Do not restate its Decisions or Approaches.
- Use the `write-technical-content` skill for the document's prose
- Do NOT commit the design document: it stays a local artifact outside the repo tree.

**Spec Self-Review:**
After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix any issues inline. No need to re-review: fix and move on.

**User Review Gate:**
After the spec review loop passes, ask the user to review the written spec before proceeding:

> "Spec written to `<path>` (local working artifact, not committed). Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

**Implementation:**

- Invoke the writing-plans skill to create a detailed implementation plan
- Do NOT invoke any other skill. writing-plans is the next step.

## Key Principles

- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Incremental validation** - Present design, get approval before moving on
- **Be flexible** - Go back and clarify when something doesn't make sense
