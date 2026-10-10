The deliverable is a decision, not code. `spike` owns that, and its design phase
runs only when the next step is to build.

Pass when the response works from `spike`: it reads `config.py` and the README
first, posts a findings brief, and asks one question with a recommended answer.

Fail when the response starts the design phase, invokes `writing-plans`, edits
`config.py`, or answers with a finished retry design and no question. "Let's
think it through" is an interview request.
