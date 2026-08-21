---
name: write-technical-content
description: "Use when writing or editing technical documentation: READMEs, API docs, runbooks, ADRs, migration guides, skill and agent instructions, code comments, and error or log messages. Applies ASD-STE100 Simplified Technical English adapted for software, and enforces one instruction per sentence, active voice, present tense, and unambiguous pronouns. Not for commit messages, PR titles or descriptions, or Notion content."
---

# write-technical-content

Rules for a file that stays in a repository, derived from ASD-STE100 Simplified
Technical English and adapted for software.

The universal prose rules apply here as well. They ban a fluff sentence, a fluff
word, an unsupported claim, a varied term, and the em dash.

## Rules

1. Write one instruction per sentence.
2. Write in the active voice. Use the imperative mood for an instruction: "Run
   the migration", not "The migration should be run".
3. Write in the present tense. Never write "will".
4. Keep the articles and the complete sentence structure. Simplified Technical
   English is not terse-speak.
5. Never write an ambiguous pronoun. When two nouns could be the referent,
   repeat the noun instead of writing "it" or "this".
6. Put a warning or a caution before the step it applies to, never after.
7. Never write a gerund as a noun. Write "To configure the server, edit the
   file", not "Configuring the server is done by editing the file".
8. Never write slang, an idiom, humour, or jargon used for flavour.

## Length limits

| Unit                   | Limit        |
| ---------------------- | ------------ |
| A procedural sentence  | 20 words     |
| A descriptive sentence | 25 words     |
| A procedural paragraph | 6 sentences  |
| A descriptive paragraph| 10 sentences |
| A procedure step list  | 6 items      |

Split a list that exceeds six items into two steps.

## Word choice

Before you choose a verb or a noun that has a shorter equivalent, read
`reference/approved-words.md` and use the approved column.

## Scope

This skill governs a file that stays in a repository. The destination table in
the prose style routes every other destination, including a PR description, a
commit message, and a Notion page.

`write-notion-content` gives the opposite instruction to rule 4, because it cuts
the articles. The destination decides which skill applies, never the subject.

## Provenance

Adapted from `write-technical-content` in
[konvoulgaris/soong](https://github.com/konvoulgaris/soong) by Konstantinos
Voulgaris, MIT licensed. See `THIRD-PARTY-NOTICES.md`.
