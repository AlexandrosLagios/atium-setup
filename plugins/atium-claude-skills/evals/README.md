# Evals

`creating-personal-skills` says to run an eval against representative prompts
before and after a description edit. These cases are that eval.

Each case is a directory holding `prompt.md` and `graders/criteria.md`, which is
the documented alternative to a single `case.yaml`.

## How to run

```sh
claude plugin eval plugins/atium-claude-skills --ablation with-without
```

The ablation arm runs the same prompt with the plugin off, so the score
difference shows what the skill set changed. Every case here tests routing, not
output quality: the failure these cases exist to catch is a skill that fires when
it must not, or stays silent when it must fire.

## State

The cases are authored and unrun: `claude plugin eval` reports "currently in
early access" on this account. Two consequences:

- No case has a recorded baseline yet. Record one on the first successful run.
- The graders are prose criteria only. The command also supports a mechanical
  indicator (`tool_used: Skill`) for whether a skill fired. Add it to each grader
  once a real run confirms the field syntax, because a guessed schema that never
  runs is worse than prose a human can read.

Keep this suite out of `tests/run.sh`. Every case costs model calls, and the test
suite must stay free to run on every commit.
