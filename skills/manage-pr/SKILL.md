---
name: manage-pr
description: Use when creating a pull request, editing an existing PR's title or description, or handling post-open PR events such as CI failures, merge conflicts with the base branch, or reviewer questions; also when given a raw CI run URL or asked to "fix CI" with no PR open yet. Enforces Conventional-Commits-with-scope titles, an optional tracker-id suffix that is never solicited, the short-prose description style, a pre-open scope check, and the policy that a PR comment carries either a code fix or verifiable evidence. Portable fallback: prefer the repository's own manage-pr skill when it ships one.
---

# manage-pr

Never run `gh pr create` by hand. Every PR goes through this skill, including drafts. Draft status does not relax the title format, the tracker suffix, or the description style.

## Title format

```
<type>(<scope>): <subject>
```

**Type**: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `build`, `ci`.

**Scope** names the affected area:

- Package or app changes: the package names, comma-separated, no spaces. More than three, list the first three only.
- Non-package areas use a fixed single word, with the type still varying by change: CI or workflows becomes `(ci)`, skills and agent config becomes `(skills)`, infrastructure and deploy becomes `(infrastructure)`.

**Subject**: short, lower-case, imperative, no trailing period.

**Tracker suffix**: if the PR has associated tracker pages, append the ids in square brackets with no spaces between them.

```
feat(reward-schemes): add tiered accrual [ABC-3880]
feat(api,worker): backfill missing events [ABC-3880][ABC-3881]
```

Do not ask for a tracker link. Add the suffix only when the user supplies a tracker page, or when one is already linked from the branch or the task at hand. Otherwise omit it and open the PR without one.

When you do have a tracker page, resolve the id from the record itself, not from a URL slug. In a Notion workspace, resolve it via the Notion MCP from the page id. Never invent an id.

## Description format

Descriptions are short. State the goal in one or two sentences. Add a bullet list only when the change is large or non-obvious enough that a reviewer needs a map. The diff is the source of truth; the description orients, it does not re-narrate.

- Open with one or two sentences: the problem and the fix, or the capability added. No headers.
- Bullets are optional. When present: maximum 5, one sentence each, covering only the changes that most help a reviewer. Do not pad to reach 5.
- No multi-paragraph narratives, no architecture deep-dives, no test inventories, no per-file walkthroughs.
- No `Summary`, `Files`, or `Test plan` headers. The diff and CI cover those.
- No `Generated with ...` or `Co-Authored-By` footers. No emojis unless asked.
- No em dashes.

Good:

> After a partial refund the ledger chain holds two unreversed entries, because the original entry is never marked when it is reversed. On a later cancel, the lookup issued a `findOne` with no ordering, so it could pick either entry and write the wrong reversal.
>
> Sorting by `createdAt` descending makes the lookup deterministically return the latest live entry, so cancel-after-refund nets to zero.

Bad: prose that walks the diff file by file, explains every helper, and ends in a `Test plan` section. If the reviewer has to scroll, cut it.

## Pre-open scope verification

Before opening:

1. **Resolve the base and show the diff stat.** Fetch first, then diff three-dot against the remote ref so the scope matches what the host will compare: `git diff origin/<base>...HEAD --stat`. Fall back to the local ref only if the remote is unavailable. Report the resolved base plus file and line counts. If the stat is far larger than the change you made, the base is wrong or the branch is stale: stop and fix it.
2. **Do not smuggle unrelated artifacts.** Skills, agent or MCP config, and unrelated docs ship in their own PR. The reserved `(skills)` and `(infrastructure)` scopes exist precisely for that.
3. **Check for multiple domains.** Group changed files into logical domains. More than one self-contained domain means proposing a split, not opening one big PR.
4. **Run the readiness review.** Run `ensure-pr-readiness` on the branch diff and resolve blocking findings first. Skip only when the user explicitly says to open without it.

### Proposing a split

Present a numbered stacked plan, one line per PR, and wait for an answer before opening anything.

```
PR1: permission vocab + schema extension + types (base: development)
PR2: validator + errors + DTOs (base: PR1)
PR3: service + controller + routes + itests (base: PR2)
PR4: remove obsolete script (base: development, independent)
```

Order dependent slices so each stacks on the previous. State the base for every entry and mark independent ones. Say in one line whether the slices are strictly sequential or genuinely independent, so the user can weigh rebase cost against smaller diffs.

- Agrees: create them in dependency order, each following this skill in full.
- Suggests different grouping: adopt theirs.
- Declines: open the single PR as-is.

## Post-open events

Default posture: **do not comment on the PR**. A comment goes out in two cases only: alongside an actual fix you push, or as a refutation of a review comment whose factual claim you disproved. A refutation carries the evidence, and `address-pr` states the evidence bar. A reply with neither a code change nor verifiable evidence never goes out.

### CI failures

1. Inspect the failing checks and read the logs.
2. Classify: **related** (plausibly caused by this diff), **unrelated with high confidence** (untouched code, or a known flake or infra issue), or **unclear**. Unclear is treated as related.
3. Related or unclear: diagnose and fix in code, push, and comment only alongside the fix. Unrelated with high confidence: first run `merge-back` to bring the base in and let CI re-run. If it still fails and is still unrelated, tell the user in chat and stop. Do not comment on the PR.
4. Never claim "CI is fine, ignore it" without the merge-back attempt unless told to skip it.

Know which red checks actually gate. Advisory repo-wide linters (complexity scores and similar) are not a reason to change code in a feature PR. Transient build-cache errors get one re-run, not an investigation.

### Starting from a raw CI run URL with no PR

1. Read the failing jobs from the run.
2. Map the failing job to a local target and reproduce it.
3. Fix on a feature branch. Never push a shared branch directly.
4. Open or update the PR following the rest of this skill.

### Reviewer questions

Answer the user in chat, not on the PR. Post a reply on the PR in two cases: the reply accompanies the code change that addresses the comment, or the reply refutes a factual claim and carries the evidence. If the question needs clarification, ask the user; do not speculate on the PR.

### Merge conflicts with the base

Use `merge-back`. Resolve locally, never through the web UI. Re-run typecheck and the affected tests before pushing.

### Comment policy

| Situation | PR comment? |
|-----------|-------------|
| Pushing an actual fix | Yes, alongside the commit if it adds context |
| CI failure, unrelated with high confidence | No, tell the user in chat |
| CI failure, related or unclear | Only paired with the fix commit |
| Reviewer question, no code change yet | No, answer in chat |
| Reviewer question, answered by a fix | Yes, alongside the fix |
| Review comment whose factual claim you disproved | Yes, a refutation that carries the evidence |
| Review comment you disagree with, no evidence | No, route it to the user |

## Editing an existing PR

Re-check the title against the rules and rewrite it in place if it does not conform. Leave an existing tracker suffix alone, and do not ask for one that is absent. Replace a non-conforming description wholesale rather than appending to it.

## Checklist

1. Pre-open scope verification, including `ensure-pr-readiness`.
2. Determine the type.
3. List the scopes; cap at three packages or use the fixed single word.
4. If, and only if, a tracker page was supplied, resolve each id from the tracker record and concatenate with no separator.
5. Compose `<type>(<scope>): <subject>`, with the tracker suffix appended only when step 4 produced one.
6. Write one or two sentences, plus at most 5 one-line bullets only if warranted.
