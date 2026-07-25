---
name: address-pr
description: Use when an existing pull request has unresolved review comments and/or failing CI checks that need to be fixed — review feedback to address, checks red, build failing, reviewer asked for changes. Not for creating a PR or editing its title/description.
---

# Resolve PR Feedback

## Overview

Execution loop for driving an existing PR's outstanding feedback to green: gather unresolved review threads **and** failing CI in one pass, classify each item, fix what's clear, and push. This skill owns the *work* of resolving feedback. It does **not** own PR conventions (title, description, comment policy) — defer to the project's own skills for those.

## When to Use

- A reviewer left comments / requested changes and you need to address them.
- CI is red on a PR and needs fixing.
- Both at once — the default. Scope down only if the user asks ("just the CI", "just Bob's comments").

**Not for:** opening a PR, writing/editing the title or description (that's the project's PR skill).

## Workflow

1. **Identify the PR.** Auto-detect from the current branch (`gh pr view --json number,title,url,headRefName`). Accept an explicit PR number/URL as an override.

2. **Discover project conventions.** Look for project skills (`manage-pr`, `merge-back`) and `AGENTS.md` / `CLAUDE.md`. Use them for the comment policy and the verify commands. If none exist, infer verify commands from `package.json` scripts, a Makefile, or CI workflow files; ask the user if you can't tell what to run.

3. **Gather feedback — both sources.**
   - Unresolved review threads only (`gh pr view --json reviews` / `gh api .../comments`). Skip resolved threads, approvals, and praise.
   - Failing checks: `gh pr checks`, then `gh run view <id> --log-failed` for the relevant logs.
   - Present a **consolidated plan** up front listing everything that needs addressing before touching code.

4. **Classify each item.**
   - Review comment → fix it **only when you are certain**: the comment names a specific defect, exactly one correct fix exists, and that fix stays inside this PR's diff. Everything else routes to the user — a question, a design opinion, a fix with more than one defensible shape, one that changes a shared contract, or one that touches code owned by another PR. **When in doubt, ask.** A wrong fix pushed under a reviewer's comment is worse than a thread left open: it looks addressed, so nobody re-reads it.
   - CI failure → **related / unclear** (treat unclear as related → fix in code) vs **unrelated, high confidence** (flake, infra, base-branch breakage you're sure this diff can't have caused).

5. **Act.**
   - Comments that cleared the certainty bar + related/unclear CI → fix in code.
   - Unrelated CI → **merge-back the base branch first** (project `merge-back` skill if present, else a plain base merge), let CI re-run. If it's still failing and still clearly unrelated, report in chat and stop — don't chase it.

6. **Verify** before pushing: run the affected typecheck/tests using the discovered commands. If verification fails, stop and fix — don't push red.

7. **Push.** For each review thread a pushed fix addresses, post a **brief reply describing the fix**. Do **not** auto-resolve threads — leave resolution to the reviewer who raised it. Never post a standalone reply with no accompanying code change.

8. **Report.** Summarize **fixed** vs **needs your input** vs **reported-and-stopped** (unrelated CI after merge-back).

9. **Suggest permanent guardrails (don't implement).** Scan the feedback you just fixed for items a permanent mechanism could prevent, and surface them to the user as suggestions — never bundle the guardrail change into this PR. Map each candidate to the cheapest mechanism that fits:
   - Style/formatting nit (quotes, spacing, import order, trailing commas) → a Prettier setting or an ESLint rule.
   - A code pattern a linter could catch (forbidden API, missing `await`, naming, banned import) → an ESLint rule.
   - A repeated expectation about *how work is done here* (process, structure, conventions) → a project skill or a new/updated convention doc (`AGENTS.md`, `CLAUDE.md`, `docs/`).

   Only raise it when **both** hold: the same class of comment is plausibly recurring (not a one-off), **and** no existing config/skill/doc already covers it (check `.eslintrc*`/`eslint.config.*`, `.prettierrc*`, the convention docs, and project skills before suggesting). One line per suggestion: what was commented → what would prevent it → where it'd live. If nothing qualifies, say so in one line and move on.

## Stop and Route to the User

Pause and surface in chat (do not act on the PR) when:

- A comment is a question, a judgment call, or otherwise ambiguous.
- You are not certain which fix the reviewer wants, or more than one fix is defensible.
- The fix would reach beyond this PR: a shared contract, another PR's files, or a policy that applies repo-wide.
- An unrelated CI failure persists after a merge-back.
- Verification fails and the fix isn't obvious.

**When no human is present** — a scheduled, unattended, or background run — "route to the user" means leave the thread untouched and report it in the run's output. Never lower the certainty bar because nobody is there to answer. An unattended run is a reason to ask *less* of your own judgment, not more.

## Quick Reference

| Item | Action |
|------|--------|
| Specific defect, exactly one correct fix, inside this PR | Fix in code, reply on thread alongside the push |
| Question, judgment call, or two defensible fixes | Route to the user; leave the thread untouched, no PR comment |
| Fix would touch a shared contract or another PR's files | Route to the user, even if the defect is real |
| CI failure, related/unclear | Diagnose and fix in code |
| CI failure, unrelated (high confidence) | Merge-back base; if still red, report in chat |
| Verification fails | Stop before pushing |
| Standalone reply, no code change | Never post on the PR |
| Recurring nit a rule/doc could prevent | Suggest the guardrail to the user; don't add it to this PR |

## Common Mistakes

- **Guessing at a fix to clear the thread.** A reviewer sounding confident is not the same as the fix being obvious. If two shapes are defensible, that is an ask, not a coin flip.
- **Lowering the bar because nobody is watching.** An unattended run has fewer people to catch a bad guess, not more permission to make one.
- **Commenting without a fix.** Replies on the PR only go out alongside a real code change.
- **Auto-resolving threads.** You fix; the reviewer resolves.
- **Chasing unrelated CI** without a merge-back, or chasing it forever after one.
- **Pushing before verifying** the affected typecheck/tests.
- **Duplicating project conventions.** Defer to the project's PR/merge-back skills instead of re-deriving title/description/policy rules.
- **Bundling guardrail changes into the PR.** A suggested lint rule / Prettier setting / convention doc is a *separate* follow-up — surface it, don't smuggle it into this diff.
- **Suggesting a guardrail that already exists.** Check the lint/format config and convention docs first; don't propose what's already there.
