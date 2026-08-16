# Global Claude Code Instructions

## Code style

- Do not add unnecessary comments to the code.
- Always follow the project conventions.

## Worktrees

Always pass a meaningful conventional-commit `name` to `EnterWorktree`, derived
from the task in the initial prompt. Never use the auto-generated random name.
Pick a short descriptive slug, for example `feat/inbound-file-processing` or
`fix/kafka-publish`. Use 64 characters maximum: letters, digits, dots,
underscores, and dashes only.

The same naming rule applies to a git branch name for a PR. Derive a meaningful
descriptive slug from the task. Use Latin and ASCII characters only:
transliterate or summarize a Greek task title, and never emit Greek glyphs.
Never keep the harness auto-generated `claude/...` prefix or a random name.

Worktree hygiene matters, because I run many concurrent worktrees and ref drift
has broken builds:

- Before you create a worktree, confirm you are not already inside one, and
  confirm you do not nest a worktree inside another worktree.
- A concurrent session can switch a shared worktree branch during a task.
  Re-verify the current branch in the same command as the commit or the push,
  never as a separate earlier step.
- Verify a clean test baseline before you implement, with the repository real
  filtered command, not a blanket `npm test`. New breakage then stays
  distinguishable from pre-existing breakage.

## Large sessions

For a larger set of tasks, use subagent-driven development by default. Do not
ask me first. After you finish a large set of tasks, run one final
`/ponytail-review` and one `/simplify`.

When asked to write a prompt or a handoff for the next session, use the
`handoff` skill instead of free-form prose. The document then stays structured
and resumable. To resume from a pasted handoff, no skill is necessary: read the
handoff and continue, or route into `shape` when the next step is creative
design.

## Workflow altitude (match ceremony to task size)

The full spine (shape, writing-plans, subagent-driven-development, review,
finishing) is for large work. The whole spine on a change of 1 to 3 files is
pure ceremony. Route by size:

- **Trivial one-liner** (rename, log key, constant, guard): no chain. Direct
  edit plus the one filtered test that covers the change. No shape, no plan, no
  subagents.
- **Small bugfix (1 to 3 files)**: use `systematic-debugging` only when the
  cause is not obvious. Otherwise apply a direct fix, a regression test, and the
  filtered tests. Let CI and a quick `/code-review` be the review. Do not create
  an in-session reviewer subagent. No shape, no plan, no subagent-driven
  development.
- **Single self-contained feature (3 to 10 files, one PR)**: run `shape` for
  real design intent, then implement in-session with the matching domain skill
  and TDD. Skip `writing-plans` unless real ordering or unknowns exist. Skip
  subagent-driven-development, because one task has nothing to parallelize.
  Close with `/code-review` and `/simplify`. Then open or undraft the PR with
  `manage-pr`, never with `gh pr create` by hand. `manage-pr` runs the
  `ensure-pr-readiness` gate, which `/code-review` and `/simplify` do not
  replace.
- **Large multi-task feature**: the full chain is essential. Run shape,
  writing-plans, worktree, subagent-driven-development (or a Workflow for
  deterministic parallel orchestration), a final whole-branch review, and
  finishing. Do not down-tier.
- **Cross-service or shared-contract change**: as above, plus
  `daisy:breaking-change-detector`, an ADR when the change is architectural, and
  `/security-review` when the change touches auth or PII.

The default failure mode is to reach for shape, writing-plans, or
subagent-driven-development on small work. Prefer a domain skill or a direct
edit, and use native CI and `/code-review` as the downstream gate.

## Execution: subagent-driven-development against Workflow

- Never invoke `executing-plans`. It is a no-subagent fallback for a thin
  platform, and it assumes a per-task human-checkpoint cadence I do not want.
  Use `subagent-driven-development` instead.
- `subagent-driven-development` is the model-in-the-loop default. Use it when a
  plan needs judgment during a task: to answer an implementer question, to
  resolve a cross-task gap that the diff cannot verify, or to escalate a
  contradiction between the plan and a defect.
- When a plan is fully specified and mechanical, and no question during the task
  is plausible, prefer a deterministic `Workflow` `pipeline()`. A pipeline is
  cheaper, it runs in the background, and it expresses implementer, review, and
  fix without a controller.

## Brainstorming

Always use the `shape` skill for brainstorming and creative-design exploration.
`shape` replaces any other brainstorming skill, including wherever another flow
tells you to invoke one.

## RTK

A hook rewrites a normal shell command through `rtk` automatically. Never call
`rtk` for a normal command. Four meta commands need a direct call:

- `rtk gain`: show token savings.
- `rtk gain --history`: show command history with savings.
- `rtk discover`: report missed opportunities.
- `rtk proxy <cmd>`: run a raw command without filtering.

## GitHub and Notion links

When a reply references a GitHub PR or issue, or a Notion page or task, end the
message with a `Links:` section. List each referenced item as a markdown link to
its full URL, for example
`- PR #2617: https://github.com/Desquared/Wave-CXM/pull/2617`. The section is
message-body text, so it renders in Claude Desktop. The footer-badge
configuration does not render there.

@~/.claude/personal-skills-guidance.md
