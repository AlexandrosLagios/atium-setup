# Personal skills

This repository is the only authored source for personal agent skills.

- When asked to create, import, or edit a personal skill, work in
  `skills/<kebab-case-name>/` in this repository.
- Never author directly in `~/.claude/skills`, `~/.claude/plugins`, or
  `~/.codex/skills`; they are generated deployment state.
- Keep every skill authored once. `skills/` is the only authored copy. The
  Claude plugin links it. The Codex plugin holds generated, git-ignored copies,
  because `codex plugin add` snapshots a plugin without following symlinks.
  Never edit either wrapper by hand; run `scripts/sync-plugin-skills`.
- Classify compatibility before deployment. `scripts/sync-plugin-skills`
  exposes portable skills through the Codex plugin; Claude Code loads all
  personal skills through the `atium-claude-skills` plugin. A skill with a
  documented Claude-only runtime requirement belongs in `skills/.codexignore`.
- Skills from other people's repositories are deployment state too. Declare them
  in `third-party-skills.tsv` and install with `scripts/install-third-party`;
  never copy their content into `skills/`. Audit one before you trust it.
- Before committing, run `tests/run.sh`, `scripts/check-secrets`, and
  `scripts/refresh-plugins --dry-run`.

For the full creation workflow, read
`skills/creating-personal-skills/SKILL.md` before taking action.

# Prose style

Prose has two destinations, chat and a file on disk. Each destination has its own
rule. Never apply the chat rule to a file, or the file rule to chat.

## Replies in chat

Be concise. Fragments are acceptable. Lead with the answer, never with the
process.

End every reply that changed anything with these three lines, in this order.
Omit none of the three lines.

- **Did:** what changed. One line for each file or each decision, five lines
  maximum.
- **Next:** the next step, or `nothing` if the work is complete.
- **You:** what the user must do (review, decide, run a command, approve, answer
  a question), or `nothing`.

Put evidence, command output, and reasoning above those three lines, or leave the
evidence out. The user reads the three lines first. Never bury a question or a
blocker inside a paragraph. A question belongs on the `You:` line.

## Prose in a file

This rule covers documents, READMEs, ADRs, `CLAUDE.md`, `AGENTS.md`, code
comments, and error or log messages. Invoke `write-technical-content` before you
write the file, then follow that skill.

For a file on disk, `write-technical-content` outranks the brevity rule above. It
also outranks any active terse mode, because a terse mode governs chat only. Keep
each sentence under 25 words, keep the articles, use one term for each concept,
and use no idioms.

## Both destinations

Never use an em dash in prose you author: a PR description, a commit message, a
Notion page, a document, or chat. Use a comma, parentheses, a colon, or two
sentences instead. This rule does not cover code, string literals, or test
fixtures, where the character can be intentional.
