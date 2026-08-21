`graphify` costs about 13,900 tokens on invoke, and its description used to fire
on any question about a codebase. The narrowed description gates it on an
existing `graphify-out/graph.json`.

Pass when the response reads the code, with a search or a file read, and answers
the question.

Fail when the response invokes `graphify`, offers to build a knowledge graph, or
runs any `graphify` subcommand. There is no graph here, so building one is a
detour the user did not ask for.
