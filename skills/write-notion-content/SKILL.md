---
name: write-notion-content
description: Use when writing or editing any Notion content: page bodies, task and ticket descriptions, comments, and status updates. Governs how the text reads, not status fields or MCP plumbing. Enforces template adherence, brevity, lists over prose, and no em-dashes. For prose that stays in a repository, use write-technical-content instead.
---

# write-notion-content

Rules for how content reads when written to Notion. Style only. This skill does
not move status fields, create pages, or make MCP calls.

## Rules

1. **Follow the template.** If the page or ticket has an existing template or
   structure, match its format exactly. Fill its sections; do not reshape them.
2. **Do not create new sections.** Use what the template or page already has.
   Add a section only if the user explicitly asks.
3. **Few words.** Cut filler, articles, and pleasantries.
4. **Lists are fine.** Prefer a bullet list over a paragraph when listing things.
5. **One sentence is ideal.** Say it in one sentence where possible.
6. **No em-dashes.** Use a period, comma, colon, or parentheses.

## Scope

The destination decides the style, not the subject. Technical content going into
Notion follows this skill. The same content committed to a repository follows
`write-technical-content`, which keeps articles and complete sentences and gives
the opposite instruction to rule 3.

PR titles and descriptions belong to `manage-pr`, even when the PR links a Notion
task.

These rules govern the Notion content this skill produces, and nothing more. The
skill claims no precedence over other active modes or skills.

## Provenance

Adapted from `write-notion-content` in
[konvoulgaris/soong](https://github.com/konvoulgaris/soong) by Konstantinos
Voulgaris, MIT licensed. See `THIRD-PARTY-NOTICES.md`.
