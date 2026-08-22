---
name: audit-harness
description: "Use when reviewing the coding agent harness itself (skills, hooks, plugins, scheduled routines, settings, and worktrees), or on a scheduled harness-audit run. Finds the drift that fails silently: a plugin serving a stale skill set, a hook injecting context nobody acts on, a routine with no source of truth, a skill duplicated across sources. Not for auditing an imported skill's safety, which is audit-agent-skills."
context: fork
background: false
effort: high
---

# Auditing the harness

The harness has no failing state. A plugin keeps serving skills from the commit
it was installed at, a hook keeps injecting a paragraph that changes nothing, a
scheduled task keeps running with no copy in any repository. Every one of those
looks exactly like a working harness, so the only way to find them is to go
looking on a schedule.

This skill runs in a forked subagent, so the reading it does never lands in the
calling conversation. Only the verdict returns. Report the numbers, not the
files you opened to find them.

## Run the mechanical scan first

```bash
scripts/audit-harness --repo /path/to/the/repository/you/work/in
```

It is read-only and offline. It exits non-zero on a `high` finding. Each check
exists because that condition was found silently true on a working machine:

- **plugin-drift**: the installed plugin cache does not hold the skills the
  source does. `scripts/doctor` cannot see this: it compares versions, and
  `claude plugin update` refuses to copy anything while the version matches.
- **collision**: one skill name offered by two sources.
- **routine-drift**: scheduled tasks and `routines/` disagree.
- **hook-noise**: identical hook injections, counted across recent transcripts.
- **dead-config**: hooks pointing at missing files, permission rules that
  cannot match.
- **worktree**: merged, generated-name, or simply too many worktrees.

## Then judge what the scan cannot

The scan counts. These need a decision:

- **Is an expensive hook earning its cost?** Compare the injection count the
  scan reports against how often the behaviour it demands actually happened.
  Count the tool calls, do not assume. A hook whose instruction is followed a
  few times per thousand injections is not a nudge, it is a tax.
- **Is a duplicated skill duplicated in substance?** Two skills with one name
  can be a portable version and a repository-specific one, which is fine once
  each description says which wins. Two skills with different names doing the
  same job is one skill too many.
- **Does a rule contradict the tooling that implements it?** A convention doc
  forbidding something a hook then does automatically means the doc is dead
  letter. Fix the tooling, not the doc.
- **Has a check been replaced by the platform?** A locally maintained tool that
  duplicates a built-in is pure carrying cost.
- **Is a scheduled routine still worth its cadence?** Read `lastRunAt`. A
  routine that has never fired is either misconfigured or unwanted.

## Verdict

Prefer deleting. A harness earns its keep by what it stops you re-deriving, and
every hook, skill, and routine is read or run on a schedule whether or not it
still applies. When a finding is real:

- **Silently wrong** (stale cache, dead hook path, unregistered routine): fix
  it in the same session; these are cheap and nothing else will catch them.
- **Expensive and ineffective**: delete it, and record the measurement that
  justified the deletion so it does not get rebuilt from the same intuition.
- **Deliberate**: say so where the next audit will read it, not in a commit
  message.

Report what was changed and what was left, with the numbers behind each call.
