---
name: renovate-prs
description: Weekly pass over the repository's open Renovate dependency-update PRs, classifying them into merge-ready buckets.
---

/renovate-prs

> The whole routine is one slash command. When a repository-local skill already
> carries the procedure, the routine should be a pointer, not a copy: the skill
> is versioned with the code it operates on, the routine is not.
>
> The tradeoff is that the routine only works from a checkout where that skill
> exists, so it does not survive a migration on its own. Note the dependency in
> `routines/README.md` rather than inlining the procedure here.
