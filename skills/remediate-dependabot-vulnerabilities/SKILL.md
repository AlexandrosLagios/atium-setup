---
name: remediate-dependabot-vulnerabilities
description: Use when asked to fix, remediate, or triage open GitHub Dependabot alerts in a pnpm-workspace (or comparable lockfile-catalog) monorepo, such as "fix the dependabot vulnerabilities", "check security alerts", a scheduled weekly sweep, or a link to a repo's /security/dependabot page. Classifies each alert as catalog-pinned, purely transitive, or bundled inside a dependency's own pin, decides between a catalog bump and a scoped pnpm override, and knows when forcing a fix is riskier than leaving the alert open. Not for a single CVE whose fix is already decided, and not for reviewing Renovate's or Dependabot's own version-bump PRs (that's a PR-review task, not a triage task).
allowed-tools: Bash(gh:*) Bash(git:*) Bash(pnpm:*) Bash(npm:*)
metadata: {cluster: "dependency-hygiene"}
---

# Remediate Dependabot vulnerabilities

Blindly bumping every flagged package to "latest" trades a DoS advisory for a
broken build, or worse, a broken build nobody notices because the bump was
approved on the strength of a green CI that never exercised the changed code
path. The value of this skill is the triage step before any file gets edited:
find out where a package actually resolves from, and let that answer, not the
advisory's severity, decide how aggressive the fix can be.

Worked example: Desquared/Wave-CXM PR #4540 fixed 19 of 21 open alerts this
way, with a two-major `csv-parse` bump, three same-major pnpm overrides
forced past what their dependents declared, one catalog dependency
(`@nestjs/testing`) bumped to match a major already in use elsewhere, and two
alerts left deliberately open because the only fix crossed a major version
nothing in the tree was reaching for, with firebase-tools' own devDependency
bundle owning the vulnerable code path and no exercised runtime path in this
app.

## 1. Gather

```bash
gh api repos/<owner>/<repo>/dependabot/alerts --paginate -q '.[] | select(.state=="open")'
```

Read the target repo's own PR conventions before opening anything (title
format, base branch, ticket-suffix rules): this skill covers the fix, not
the PR mechanics, and the repo's own `manage-pr`-equivalent doc still governs
the PR.

## 2. Classify every alert before editing anything

For each vulnerable package, find every place it actually resolves:

- **Direct catalog pin.** `grep -rn '"<pkg>"' --include=package.json .` shows
  whether every consumer points at a single `catalog:<name>` entry in
  `pnpm-workspace.yaml` (or the npm/yarn equivalent: a shared version in a
  root manifest). One declaration, one fix site.
- **Purely transitive, or multiple resolved versions.** `pnpm why <pkg> -r`
  (or `npm ls <pkg>` / `yarn why <pkg>`) prints every resolved version and its
  full requester chain. A package with no `package.json` entry anywhere in
  the workspace is reached only through this chain.
- **Bundled inside a third party's own pin.** When the requester chain ends
  at a dependency you don't own, such as `@nestjs/platform-express` shipping
  its own `multer`, or `firebase-tools` shipping its own `stream-json`, read
  that dependency's *own* declared range instead of the version pnpm happened
  to resolve: `npm view <dependent>@<version> dependencies.<pkg>`. That range
  is what any fix has to reckon with.

Multiple versions of the same package commonly coexist in one lockfile
(different requesters, different ranges). Fixing the alert means every
resolved instance ends up patched, not just the one your own code touches
directly: re-run the `pnpm why` check after the fix to confirm.

## 3. Decide the fix, per alert

**We declare it directly via a shared catalog.** Bump the catalog entry.
Prefer the smallest published version that closes the advisory, the latest
patch on the major/minor line already in use, over jumping to whatever
`npm view <pkg> version` reports as newest. Only take a new major when the
advisory's fixed version requires it. A major bump means checking that
package's own published types/changelog for renamed or removed options your
code passes before committing to it (see step 4 for what breaks and how to
fix it, not work around it).

**Transitive, or hard-pinned below the fix by a dependent, but the fix stays
in the major version already in use somewhere in the tree.** Add an entry to
the workspace's `overrides` (pnpm) / `resolutions` (yarn) block. Match the
block's existing citation style if one exists: a comment naming which
dependent pins the bad version and the GHSA id(s), then the override itself,
bounded to one major above the fix (`'>=X.Y.Z <X+1'`) unless the vulnerable
package is one a sibling package pins in lockstep at an *exact* version
(monorepo-internal packages that ship together, like `vitest` and
`@vitest/mocker`, or `ai` and `@ai-sdk/provider-utils`), in which case bound
those to the same minor line instead of a full major, since the sibling
coupling is tighter than a normal semver range implies.

**The fix crosses a major version that nothing already installed reaches,
and the owning dependent is a devDependency-only CLI or build tool.** Do not
force it. The canonical shape: a deploy/build tool (firebase-tools, a
bundler, a codegen CLI) bundles its own copy of something at a version two
majors behind the fix, its *own latest release* still hasn't moved off that
version, and the vulnerable code path (a streaming JSON parser, a CSV
importer) is never exercised by how this repo actually uses the tool. Check
that last part against what the tool actually does here, not against what it
does in general: a CDN-publish CLI's *purpose* being unrelated to CSV
parsing is a hint, not the check. Confirm from the advisory's description or
the tool's own docs which command/feature touches the vulnerable dependency,
then confirm this repo's scripts/CI never invoke that command. Forcing the
override here trades a low-severity, code-path-unreachable advisory for an
untested risk of breaking that tool at the one time someone actually runs it,
a risk no unit test in this repo can catch, because the repo's tests don't
exercise the bundled tool's internals. Leave the version alone, name the
alert number and the one-line reason in the PR, and leave the GitHub alert
itself open for a human to dismiss (or not): don't dismiss it yourself unless
the person running this skill has told you that's in scope for this run.

**Never** touch a package pinned to an exact version by first-party code
unless that exact pin *is* the vulnerable version.

## 4. Apply and verify

- Make the version-file edits, then run the package manager's install once
  to regenerate the lockfile.
- Re-run the step-2 resolution check for every targeted package to confirm
  the vulnerable resolution is gone: the one deliberate holdout from step 3
  is the only version left unpatched, and it should be an outcome you chose,
  not one you missed.
- For every package whose source imports the bumped package directly (a
  devDependency bump with zero source-level usage doesn't need this), run
  its typecheck, lint, and test targets. A major bump that changes a
  published type is a real compile break, not a false positive: adapt the
  calling code to the new type shape, keep the same observable behavior, and
  update any test that was asserting on the old implementation detail (a
  reference-equality check that only worked because the old code passed a
  callback straight through, for instance) rather than the behavior itself.
  Don't reach for `any` to make an error disappear; that's how a fixed
  vulnerability regresses six months later when nobody remembers why the
  type was there.
- Run the repo's own diff-coverage or line-coverage check if it has one: new
  wiring introduced to bridge an API change is still new code, and it needs
  the same coverage bar as anything else.

## 5. Open the PR

Follow the target repo's own PR-title and description conventions. In the
description, list what was bumped or overridden and why in one bullet per
package, and, when step 3's third case applies, a separate "left open" list
naming each alert number and the one-line unreachable-code-path reason. That
list is what turns "I decided not to fix this" into something the next
person (or the next scheduled run of this same skill) can act on instead of
re-litigate.

## Recurring / scheduled use

When this runs on a schedule against the same repo, reuse one stable branch
name across runs instead of a fresh one every time. Before starting, check
whether that branch has an open PR: if so, rebase it onto the current base
branch and redo the classification fresh (a prior run's alert list is a
snapshot, not a plan: some alerts may be fixed upstream by now, new ones may
exist); if not, branch fresh. This keeps one live PR per remediation cycle
instead of an accumulating pile of stale ones.
