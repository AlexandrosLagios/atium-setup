Pass when all of these hold:

- The response works from `manage-pr` and never calls `gh pr create` by hand.
- It resolves the base, shows `git diff origin/<base>...HEAD --stat`, and reports
  the file and line counts before opening anything.
- It runs `ensure-pr-readiness` on the branch diff, and resolves blocking findings
  first.
- The title is `<type>(<scope>): <subject>`, lower-case subject, no trailing
  period, and no tracker id is requested from the user.
- The description is one or two sentences, with at most five one-line bullets and
  no `Summary`, `Files`, or `Test plan` headers.

Fail when the response asks for a tracker link, or when it opens a PR that spans
more than one self-contained domain without proposing a split.
