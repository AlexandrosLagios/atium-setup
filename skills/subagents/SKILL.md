---
name: subagents
description: "Use when dispatching a subagent or background task. Picks the lightest specialized agent and the cheapest model tier that can do the work well, instead of defaulting to a heavyweight catchall on the top model tier. Not for deciding whether to dispatch at all, only which agent and which tier. Portable fallback: prefer the repository's own subagents skill when it ships one."
---

# subagents

Subagent calls are billed independently and can dominate session cost. Defaulting to the generic catchall agent on the top model tier is the single most common cost mistake.

## Pick the agent

| Task | Pick |
|------|------|
| Code search, "where is X" | A read-only code-search agent. |
| Codebase tracing, feature analysis | A code-explorer agent. |
| Architecture or feature design | A code-architect or planning agent. |
| Code review | A read-only code-review agent. |
| Failing browser or e2e tests | A test-healer agent. |
| Anything a skill already covers | The skill, with no subagent at all. |

Reach for the generic catchall last.

## Pick the model

| Tier | Use for |
|------|---------|
| Top (Opus class) | Novel design, multi-file refactors, hard reasoning. |
| Mid (Sonnet class) | The default for routine subagents. |
| Small (Haiku class) | Formatting, lint fixups, mechanical edits. |

Pass the tier explicitly. Omit it only when the work genuinely needs top-tier reasoning.

## Claude Code specifics

| Task | `subagent_type` |
|------|-----------------|
| Code search | `Explore` |
| Architecture or planning | `Plan` |
| Catchall, last resort | `general-purpose` |

`Agent({ subagent_type: "Explore", model: "sonnet", ... })`. Whatever specialized agents the loaded plugins expose outrank `general-purpose`; check the available-agent list before falling back to it.

Route cross-runtime agents (anything that hands work to a separate model runtime at extra cost) only at a genuine impasse or for an adversarial second opinion on a substantial PR. Not for routine review or quick double-checks.

## Other

- Repository-local domain skills come before plugin meta-skills. A repo skill knows the codebase; a meta-skill knows a process.
- Clear context between unrelated tasks, compact at phase boundaries, use git worktrees for parallel work.
- A subagent does not inherit the parent's conversation. Every dispatch prompt is self-contained or it is broken.
