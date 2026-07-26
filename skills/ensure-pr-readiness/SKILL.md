---
name: ensure-pr-readiness
description: Use when verifying a branch or PR is ready to open or undraft, or when asked for a PR-readiness review. Runs the mechanical typecheck and lint gate, a correctness review, a conventions walk over the repository's own rule docs with file:line evidence, conditional escalations, and the affected integration tests, then reports READY or NOT READY.
---

# ensure-pr-readiness

Applies the repository's existing rules to a diff and reports blocking findings versus suggestions.

This skill deliberately contains no conventions of its own. The rules live in the target repository: its `AGENTS.md` or `CLAUDE.md`, and whatever rule docs it indexes. This skill carries only how to scope the run, the order of operations, and the report format. If the repository has no rule docs, step 3 collapses to its contribution standards alone; say so rather than inventing rules.

## Entry modes

| Mode | Diff basis |
|------|-----------|
| Branch (default) | `git fetch origin <base>` then `git diff origin/<base>...HEAD` (three-dot). For a stacked branch, diff against the parent branch instead. |
| PR number | The PR's diff and base as reported by the host (`gh pr diff <n>`, `gh pr view <n>`). |

## Scope the run

Pick a tier from the diff before starting. Steps 1 and 5 always run; steps 2 to 4 scale.

| Tier | When | Steps 2 to 4 |
|------|------|--------------|
| Small | 5 files or fewer, additive or mechanical, no step-4 trigger: a field threaded through existing layers, a rename, a guard, a constant. | 2 at lowest effort; 3 only for rule docs whose subject changed; skip 4. |
| Standard | Neither Small nor Deep. | As written. |
| Deep | A step-4 trigger fires, or the diff spans services, shared contracts, or a published package surface. | As written, at raised effort. |

Promote the tier when the diff surprises you. Never demote to dodge a trigger.

## Order of operations

Do not reorder. Review effort spent on a red baseline is wasted, and integration tests run once, after fixes, so they are not paid for twice.

1. **Mechanical gate.** Typecheck and lint the affected projects. If either is red, stop and report. Do not continue to review.
2. **Correctness review.** Review the diff for bugs using the harness's native code-review capability at the tier's effort. On Claude Code that is the `code-review` skill, mapping Small to `low`, Standard to `medium`, Deep to `high`.
3. **Conventions walk.** Open the repository's rule-doc index and apply each doc whose *subject the diff changes*. Adding a field to an endpoint touches the API contract, not caching or migrations. Every verdict is pass or fail and must cite `file:line` evidence; a bare assertion is not a verdict. Skip anything the repository already enforces automatically, since step 1 covered it.
4. **Conditional escalations.** Skipped at Small. Otherwise run whichever the diff triggers:
   - Changes an auth, crypto, token, or PII *mechanism*, as opposed to carrying an existing field across an unchanged boundary: run a security review before opening. On Claude Code that is the `security-review` skill. Never at Small.
   - Changes public exports or types of a shared package: scan every consumer of that package for breakage.
   - Introduces env vars or infra expectations: verify the PR description states where each value lives.
   - Changes rendered UI, markup, or component structure: run `web-design-guidelines` over the changed files. Report accessibility failures (missing labels, focus handling, contrast, touch targets, semantics) as blocking; treat its stylistic notes as suggestions.
5. **Integration tests.** Run the affected integration test files once, after the fixes from steps 2 to 4 are applied.

## Report format

- **Blocking**: rule violations, correctness bugs, a red gate, red integration tests. Each entry names the rule doc or the bug, the `file:line`, and the smallest fix.
- **Suggestions**: non-blocking improvements found along the way.
- **Verdict**: `READY` only when Blocking is empty and the gate plus tests are green. Otherwise `NOT READY`.

Report what changed the outcome, not the work done. A clean Small run is one line: tier, green gate, verdict.

Fix-and-recheck is in scope when the user asked for readiness rather than just a report: apply the blocking fixes, then re-run only the affected steps.

## Don'ts

- Do not restate or paraphrase rules in the report. Link the rule doc and show the evidence.
- Do not skip the mechanical gate because the branch looks clean.
- Do not run the full test suite. Only the affected projects and the affected integration tests.
- Do not run the Standard or Deep ladder on a Small diff.
