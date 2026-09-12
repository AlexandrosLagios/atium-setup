# Evals

`creating-personal-skills` says to run an eval against representative prompts
before and after a description edit. These cases are that eval. Every one of them
asks the same question: which skill fires, and does the wrong one stay quiet.

## Layout

Each case is a directory:

| File | Read by |
|------|---------|
| `prompt.md` | both runners: the request, verbatim |
| `expect.env` | `run.sh`: `require` and `forbid`, space-separated skill names |
| `graders/criteria.md` | `claude plugin eval`: prose criteria for an LLM grader |

## Running it now

```sh
plugins/atium-claude-skills/evals/run.sh              # every case
plugins/atium-claude-skills/evals/run.sh self-check   # one case
```

`run.sh` starts one session per case, so it costs tokens and stays out of
`tests/run.sh`. It reads which skill fired from the `Skill` tool calls in the
session's `stream-json` output, so the verdict is mechanical and no grader model
is involved.

`self-check` names the skill in the prompt. It proves the runner can observe an
invocation at all. When it fails, every other verdict in the suite is worthless,
so read it first.

## What the suite measures today

Measured on 2026-08-22, Claude Code 2.1.237:

- `self-check` fires `manage-pr`, so the mechanism works.
- `graph-absent` fires nothing, which is the intended outcome: an ordinary
  question about code in a repository with no graph must not load graphify.
- `pr-open-new` fires nothing. The skill is offered and the request is squarely
  inside its description, and a one-shot headless session still answered from
  first principles. Treat that as a finding about headless routing rather than a
  proven gap in interactive sessions, which is where these skills are actually
  used, and which this runner cannot reach.

Measured on 2026-09-12, Claude Code 2.1.269, with the installed plugin
disabled so the staged working tree was the only copy of `shape`:

- `spike-brainstorm` fires `spike` and not `shape`.
- `spike-one-read` fires nothing, which is the intended outcome.
- `shape-feature` fires nothing. The same prompt against the previous `shape`
  description (0.6.0) also fires nothing, and both sessions wrote a plan file
  from first principles. That is the `pr-open-new` finding again: a headless
  session does not apply the workflow-altitude rule, so the case measures
  interactive routing only when the real harness runs it.

## Why the runner works the way it does

- **It runs in a throwaway git fixture, never in this repository.** Inside the
  repository the agent reads `skills/<name>/SKILL.md` as an ordinary file and
  never invokes a skill, so a case passes for the wrong reason.
- **The fixture has a remote and a base ref.** Without them a PR case is answered
  with "there is nothing to open a PR against", which looks like a routing
  failure and is a fixture failure.
- **A session that errored is reported as `error`, never as a pass.** A failed run
  reports no skill, which reads exactly like correct silence.
- **It uses your own configuration.** An isolated `CLAUDE_CONFIG_DIR` holds no
  credentials, and every session then fails with "Not logged in". The installed
  plugin therefore loads alongside the checkout, and both offer the same names, so
  run `scripts/refresh-plugins` first when the answer must come from the working
  tree.
- **Sessions run with `--permission-mode plan`,** so no case can edit or push.

## The real harness

```sh
claude plugin eval plugins/atium-claude-skills --ablation with-without
```

That command is gated behind early access on this account. It adds what `run.sh`
cannot: a no-plugin baseline arm for measuring lift rather than routing, repeated
runs per case, and LLM grading against `graders/criteria.md`. The graders stay
prose until a real run confirms the mechanical grader syntax, because a guessed
schema that never runs is worse than prose a human can read.
