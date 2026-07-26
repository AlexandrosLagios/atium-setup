---
name: steal-skills
description: Use when porting skills, convention docs, or agent config from one repository into another - "steal the skills from repo X", "copy the conventions from Y", "adapt their docs for this project", or when setting up a new repo by cribbing from an established one. Enforces profiling the target codebase before adapting, so imported rules describe the target's reality rather than the source's.
---

# steal-skills

Porting skills between repos fails in one specific way: you translate the source's *rules* instead of documenting the target's *reality*. The result is a confident doc that contradicts the code it governs, and every agent that reads it is now wrong on purpose.

The whole skill is a guard against that.

## The cardinal rule

**Never write a convention doc for the target from the source's doc alone.** The source doc tells you which *topics* are worth documenting. Only the target's code tells you what the *rules* are.

Real failure this prevents: a source repo's `state-management.md` ended with "Do not introduce Redux, Zustand, MobX, or any other state management library." The target repo used Zustand throughout. Translated verbatim, that doc would have instructed every future agent to rip out working code.

So: source supplies the **table of contents**, target supplies the **content**.

## Process

### 1. Survey cheaply

Do not read every file. Get the shape first:

```bash
ls -1 <source>/.claude/skills/
wc -l <source>/docs/**/*.md | sort -n
```

Then read only frontmatter (`name`, `description`) for skills, and the index/README for doc trees. A 500-line doc and a 5-line doc get triaged the same way; the line count only tells you how much work adaptation will be.

### 2. Find the gap before picking favourites

Before judging what is *good* in the source, find what is *missing* in the target. Read the target's `CLAUDE.md` / `AGENTS.md` and its existing skills. If the user's own instructions already reference a skill by name that does not exist in the target, that is the highest-value steal in the repo, and it outranks anything that merely looks impressive.

### 3. Triage every candidate

Sort into three buckets. Be aggressive about the third.

| Bucket | Test |
|--------|------|
| **Steal** | The rule survives with only nouns swapped (paths, project names, base branch). Generic engineering discipline: review gates, PR hygiene, accessibility, test structure, performance heuristics. |
| **Adapt** | The *topic* applies but the content is stack-specific. Keep the section headings, rewrite the body from the target's code. |
| **Skip** | Coupled to the source's in-house packages, infrastructure, vendors, or domain. Also: anything solving a problem the target does not have. |

Coupling signals that mean skip: imports from private org packages, in-house framework hooks, vendor names, service names, ticket-tracker prefixes, deploy targets, base-class hierarchies that do not exist in the target.

A skill that is 90% coupled is not a 10% steal. It is a topic heading. Say so and move on.

Anything in the **Steal** bucket carries the source's instructions with it. Audit
it with `audit-agent-skills` before it earns a place in the target: a skill you
copied is a dependency you now ship.

### 4. Profile the target before writing a single line

For every doc in the **Adapt** bucket, dispatch parallel `Explore` subagents (one per area: backend patterns, frontend patterns, testing, build) to report what the target codebase *actually* does, with `file:line` evidence.

Brief them to report inconsistency, not just the happy path:

> Report the dominant pattern with 2-3 concrete file:line examples, and flag where the codebase is INCONSISTENT. Explicitly say "inconsistent" or "no established pattern" where true rather than inventing a convention.

A doc that asserts a convention the codebase does not follow is worse than no doc. When the profile comes back inconsistent, the honest doc says "two patterns exist, prefer X for new code" and names both.

### 5. Adapt, do not transliterate

- Swap the mechanical nouns: base branch, package manager, task runner, project names, test file globs.
- Cut every section whose subject the target lacks. Do not keep an empty heading as a placeholder.
- Do not import the source's *file layout* unless the target needs it. A source that splits `SKILL.md` into a thin stub plus `docs/skills/x.md` usually does so to share one source of truth across several harnesses (`.claude/`, `.codex/`, `.github/`). A target with only `.claude/` should inline the content into `SKILL.md`.
- Keep the source's genuinely hard-won specifics when they are stack-neutral: a comment-policy table, a tiered-effort ladder, a "no useEffect for state" table. These are the actual value; the framework glue around them is not.

### 6. Verify every command you wrote down

A convention doc is executable documentation. Before claiming it is done, confirm that every command, target, path, and script it references exists in the target:

```bash
# example: confirm the task-runner targets the doc references are real
npx nx show project <name> --json | jq '.targets | keys'
```

If the target repo is a worktree without `node_modules`, run the check in the main checkout. Do not assume a target exists because the source had one under the same name.

### 7. Report the skip list

Tell the user what you did **not** take and why, as a table. The skip reasoning is the most reviewable part of the work: it is where your judgement is visible and where a wrong call is cheapest to correct. Burying it loses the one thing they can meaningfully check.

Flag any rule you *invented* (one not present in the source and not directly evidenced in the target) separately and explicitly, so they can veto it.

## Don'ts

- Do not copy files verbatim and fix them up later. Adaptation is the work; a verbatim copy defers it to whoever reads the doc next and believes it.
- Do not steal a skill because it is impressive. Steal it because the target has the problem it solves.
- Do not port multi-agent or heavy-orchestration skills into a small or solo repo. They are calibrated for a team's volume.
- Do not port a skill whose tooling the target lacks (Playwright agents, Storybook, a CI provider) without saying the tooling is a prerequisite.
- Do not let the source's doc count anchor you. Porting 4 of 21 docs is a good outcome if 17 were coupled.
