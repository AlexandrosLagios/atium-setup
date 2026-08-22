---
name: address-pr
description: "Use when an existing pull request has unresolved review comments and/or failing CI checks that need to be fixed: review feedback to address, checks red, build failing, reviewer asked for changes. Not for creating a PR or editing its title or description, which is manage-pr."
allowed-tools: Bash(gh:*) Bash(git:*)
metadata: {cluster: "pr-lifecycle", siblings: "manage-pr, ensure-pr-readiness, merge-back, babysit-prs"}
---

# Resolve PR feedback

## Overview

Execution loop for driving an existing PR's outstanding feedback to green: gather unresolved review threads **and** failing CI in one pass, classify each item, fix what is clear, and push. This skill owns the *work* of resolving feedback. It does **not** own PR conventions (title, description, comment policy): defer to the project's own skills for those.

## When to use

- A reviewer left comments / requested changes and you need to address them.
- CI is red on a PR and needs fixing.
- Both at once, which is the default. Scope down only if the user asks ("just the CI", "just Bob's comments").

**Not for:** opening a PR, writing or editing the title or description, which is the project's PR skill.

## Workflow

1. **Identify the PR.** Auto-detect from the current branch (`gh pr view --json number,title,url,headRefName`). Accept an explicit PR number/URL as an override.

2. **Discover project conventions.** Look for project skills (`manage-pr`, `merge-back`) and `AGENTS.md` / `CLAUDE.md`. Use them for the comment policy and the verify commands. If none exist, infer verify commands from `package.json` scripts, a Makefile, or CI workflow files; ask the user if you cannot tell what to run.

3. **Gather feedback from both sources.**
   - Unresolved review threads only (`gh pr view --json reviews` / `gh api .../comments`). Skip resolved threads, approvals, and praise.
   - Failing checks: `gh pr checks`, then `gh run view <id> --log-failed` for the relevant logs.
   - Present a **consolidated plan** up front listing everything that needs addressing before touching code.

4. **Classify each item.**
   - Review comment → **fix**, **refute**, or **route to the user**.
     - **Fix** it only when you are certain: the comment names a specific defect, exactly one correct fix exists, and that fix stays inside this PR's diff.
     - **Refute** it when the comment makes a factual claim and you disproved that claim with evidence a reader can check. See [Refuting a review comment](#refuting-a-review-comment). No code changes.
     - **Route** everything else to the user: a question, a design opinion, a fix with more than one defensible shape, one that changes a shared contract, or one that touches code owned by another PR. **When in doubt, ask.** A wrong fix pushed under a reviewer's comment is worse than a thread left open: it looks addressed, so nobody re-reads it.
   - CI failure → **related / unclear** (treat unclear as related → fix in code) vs **unrelated, high confidence** (flake, infra, base-branch breakage you are sure this diff cannot have caused).

5. **Act.**
   - Comments that cleared the certainty bar + related/unclear CI → fix in code.
   - Comments you refuted → write the reply body, and verify every piece of its evidence before you post.
   - Unrelated CI → **merge-back the base branch first** (project `merge-back` skill if present, else a plain base merge), let CI re-run. If it is still failing and still clearly unrelated, report in chat and stop, and do not chase it.

6. **Verify** before pushing: run the affected typecheck/tests using the discovered commands. If verification fails, stop and fix, and do not push red.

7. **Push.** For each review thread a pushed fix addresses, post a **brief reply describing the fix**. Post the refutation reply on each thread you disproved. Do **not** auto-resolve threads: leave resolution to the reviewer who raised it. Never post a reply that carries neither a code change nor verifiable evidence.

8. **Report.** Summarize **fixed** vs **refuted** vs **needs your input** vs **reported-and-stopped** (unrelated CI after merge-back).

9. **Suggest permanent guardrails, and do not implement them.** Scan the feedback you just fixed for items a permanent mechanism could prevent, and surface them to the user as suggestions, and never bundle the guardrail change into this PR. Map each candidate to the cheapest mechanism that fits:
   - Style/formatting nit (quotes, spacing, import order, trailing commas) → a Prettier setting or an ESLint rule.
   - A code pattern a linter could catch (forbidden API, missing `await`, naming, banned import) → an ESLint rule.
   - A repeated expectation about *how work is done here* (process, structure, conventions) → a project skill or a new/updated convention doc (`AGENTS.md`, `CLAUDE.md`, `docs/`).

   Only raise it when **both** hold: the same class of comment is plausibly recurring (not a one-off), **and** no existing config/skill/doc already covers it (check `.eslintrc*`/`eslint.config.*`, `.prettierrc*`, the convention docs, and project skills before suggesting). One line per suggestion: what was commented → what would prevent it → where it'd live. If nothing qualifies, say so in one line and move on.

## Refuting a review comment

One case qualifies: the comment makes a factual claim, and you disproved that claim with evidence a reader can check. Post a reply that states the verdict and carries the evidence. Change no code. Do not resolve the thread.

The evidence must be one of these four, and the reply must name it:

- A repository rule document, cited by path and line.
- A command you ran, with its output, on the version the repository pins.
- A precedent count across the repository, with the denominator (for example, 31 of 47 migration test files).
- A library or runtime source path that shows the claimed behavior is absent.

An opinion is not evidence. "This is fine" and "I disagree" stay banned. A design opinion is also not a refutation: it routes to the user, and the thread stays silent.

**A human reviewer raises the bar.** Read the comment author before you draft the reply: the thread payload carries the login and the account type, and a bot login ends in `[bot]` or names the review bot (`Copilot`). Treat an author you cannot classify as a person. Against a bot reviewer, any of the four evidence types supports a reply. Against a person, only a rule citation or a command output does. A precedent count or a source trace against a person routes to the user instead. Present the evidence, and do not pronounce a verdict on the reviewer.

Verify the evidence yourself before you post. Run the command, open the cited file at that line, count the occurrences. A citation you assembled from memory is a guess, not evidence.

Post one thread at a time. Write each reply body to its own file, then send it with a single `gh api ... -f body="$(< file)"` call per thread. One script that loops over several inline heredocs reads as a bulk publish, and a permission classifier blocks it.

## Stop and route to the user

Pause and surface in chat (do not act on the PR) when:

- A comment is a question, a judgment call, or otherwise ambiguous.
- You are not certain which fix the reviewer wants, or more than one fix is defensible.
- The fix would reach beyond this PR: a shared contract, another PR's files, or a policy that applies repo-wide.
- An unrelated CI failure persists after a merge-back.
- Verification fails and the fix is not obvious.

**When no human is present**, on a scheduled, unattended, or background run, "route to the user" means leave the thread untouched and report it in the run's output. Never lower the certainty bar because nobody is there to answer. An unattended run is a reason to ask *less* of your own judgment, not more.

A refutation is the one reply an unattended run may post, under the same evidence bar as an attended run. The bar demands evidence a reader can check, so a wrong refutation stays catchable after the run.

## Quick reference

| Item | Action |
|------|--------|
| Specific defect, exactly one correct fix, inside this PR | Fix in code, reply on thread alongside the push |
| Factual claim you disproved, evidence a reader can check | Reply with the evidence, change no code, do not resolve |
| Refutation of a human reviewer | Reply only on a rule citation or a command output; else route |
| Question, judgment call, or two defensible fixes | Route to the user; leave the thread untouched, no PR comment |
| Fix would touch a shared contract or another PR's files | Route to the user, even if the defect is real |
| CI failure, related/unclear | Diagnose and fix in code |
| CI failure, unrelated (high confidence) | Merge-back base; if still red, report in chat |
| Verification fails | Stop before pushing |
| Reply with neither a code change nor verifiable evidence | Never post on the PR |
| Recurring nit a rule/doc could prevent | Suggest the guardrail to the user; do not add it to this PR |

## Common mistakes

- **Guessing at a fix to clear the thread.** A reviewer sounding confident is not the same as the fix being obvious. If two shapes are defensible, that is an ask, not a coin flip.
- **Lowering the bar because nobody is watching.** An unattended run has fewer people to catch a bad guess, not more permission to make one.
- **Replying with nothing behind it.** A reply on the PR carries either a code change or verifiable evidence. "Good catch, I will look at this" and a claim of work you did not do stay banned.
- **Posting a refutation you did not verify.** Run the command, open the cited line, count the occurrences. A citation from memory is a guess.
- **Dressing an opinion as a refutation.** A position you hold is not a claim you disproved. A design opinion routes to the user, and the thread stays silent.
- **Leaving a refuted thread silent.** Silence reads to the PR author as a thread you ignored. Evidence you gathered belongs on the thread.
- **Auto-resolving threads.** You fix; the reviewer resolves.
- **Chasing unrelated CI** without a merge-back, or chasing it forever after one.
- **Pushing before verifying** the affected typecheck/tests.
- **Duplicating project conventions.** Defer to the project's PR/merge-back skills instead of re-deriving title/description/policy rules.
- **Bundling guardrail changes into the PR.** A suggested lint rule / Prettier setting / convention doc is a *separate* follow-up: surface it, and do not smuggle it into this diff.
- **Suggesting a guardrail that already exists.** Check the lint/format config and convention docs first; do not propose what is already there.
