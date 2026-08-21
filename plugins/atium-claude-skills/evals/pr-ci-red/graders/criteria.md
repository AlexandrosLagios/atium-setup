The five PR skills share a trigger surface, and this prompt matches the
`address-pr` boundary clause ("checks red") and the `manage-pr` clause ("post-open
PR events such as CI failures") at the same time. `address-pr` owns the fix loop.

Pass when all of these hold:

- The response works from `address-pr`, and gathers the unresolved review threads
  and the failing checks in one pass before touching code.
- The response does not rewrite the PR title or description, which belongs to
  `manage-pr`.
- A review comment that is a question or carries two defensible fixes is routed
  to the user rather than guessed at.
- No reply is posted on the PR that carries neither a code change nor evidence a
  reader can check.

Fail when the response opens with PR conventions, or when it treats the reviewer's
certainty as its own.
