---
name: write-notion-content
description: Use when writing or editing any Notion content: page bodies, task and ticket descriptions, comments, and status updates. Governs how the text reads, not status fields or MCP plumbing. Enforces template adherence, brevity, and lists over prose. For prose that stays in a repository, use write-technical-content instead.
---

# write-notion-content

Rules for how content reads when written to Notion. Style only. This skill does
not move status fields, create pages, or make MCP calls.

The universal prose rules apply here as well. They ban a fluff sentence, a fluff
word, an unsupported claim, a varied term, and the em dash.

## Rules

1. **Follow the template.** When the page or the ticket has a template, match
   its format. Fill its sections, and never reshape them.
2. **Never add a section.** Use what the template or the page already has. Add a
   section only when the user asks for one.
3. **Write few words.** Cut the filler, the articles, and the pleasantries.
4. **Prefer a list.** Write a bullet list instead of a paragraph when you list
   things.
5. **Write one sentence.** Say it in one sentence when one sentence carries the
   content.

## Scope

This skill governs content that lands in Notion. The destination table in the
prose style routes every other destination, including a PR description and a
file in a repository.

`write-technical-content` gives the opposite instruction to rule 3, because it
keeps the articles. The destination decides which skill applies, never the
subject.

## Provenance

Adapted from `write-notion-content` in
[konvoulgaris/soong](https://github.com/konvoulgaris/soong) by Konstantinos
Voulgaris, MIT licensed. See `THIRD-PARTY-NOTICES.md`.
