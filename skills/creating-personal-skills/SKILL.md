---
name: creating-personal-skills
description: Use when creating, importing, or adapting a personal Claude or Codex skill that should live in the atium-setup source-of-truth repository.
---

# Creating personal skills

Create every personal skill in `skills/<kebab-case-name>/` in this repository.
Do not author a skill directly in `~/.claude/skills`, `~/.claude/plugins`, or
`~/.codex/skills`: those paths are generated deployment state.

## Workflow

1. Use `skill-creator` to initialize or update the skill in `skills/`.
2. Use `writing-skills` to test and validate the skill's triggering and
   behavior before deployment.
3. Check for credentials, private endpoints, work-only paths, and platform-only
   tool assumptions. Keep secrets out of the repository.
4. Never spend a portable skill on a Claude-only convenience. A field outside
   the six the spec allows forces the skill into `skills/.codexignore`, and
   `tests/skill-descriptions.test.sh` enforces that. A context optimisation such
   as `context: fork` does not justify losing Codex; a runtime dependency does.
5. Confirm a session actually offers the skill, not just that the file exists:
   `scripts/verify-skill-discovery`. It costs a model call, so run it after a
   compatibility change rather than on every edit.
6. Classify compatibility:
   - Portable: leave it out of `skills/.codexignore` so
     `scripts/sync-plugin-skills` exposes it through the Codex plugin.
   - Claude-only: document the concrete runtime dependency and add its name to
     `skills/.codexignore`.
   - Claude Code loads both kinds through the `atium-claude-skills` plugin.
7. Run `tests/run.sh`, `scripts/check-secrets`, and
   `scripts/refresh-plugins --dry-run` before committing or deploying.
8. For a spec and hygiene pass that the repository's own tests do not cover, run
   `skills-ref validate skills/<name>` for spec conformance, then
   `uvx skillscheck skills/` for hygiene. It reports frontmatter that a strict YAML parser
   rejects, orphaned reference files, dead markdown links, token budgets, and
   cross-agent compatibility. Its own code makes no HTTP calls. Treat its
   description-style opinions as advice: it prefers agent-directed wording where
   Anthropic's own examples name the user.

## The specification this repository targets

The Agent Skills specification lives at
[agentskills.io/specification](https://agentskills.io/specification), stewarded
by the Agentic AI Foundation under the Linux Foundation, the same body that
stewards MCP. Everything below comes from that document, not from this
repository's preference:

| Field | Constraint |
|-------|-----------|
| `name` | Required. 1 to 64 characters, lower-case letters, digits, and single hyphens. Must match the directory name. |
| `description` | Required. 1 to 1024 characters. States what the skill does and when to use it. |
| `license` | Optional. A licence name, or the name of a bundled licence file. |
| `compatibility` | Optional. Up to 500 characters, for a real environment requirement. |
| `metadata` | Optional. A map from string keys to **string** values. A list value is out of spec. |
| `allowed-tools` | Optional, experimental. A space-separated string, such as `Bash(gh:*) Bash(git:*)`. |

Budgets from the same document: the body under 500 lines and under about 5000
tokens, references one level deep from `SKILL.md`, and the directory conventions
`scripts/`, `references/`, and `assets/`.

Validate against the steward's own library rather than by eye:

```bash
skills-ref validate skills/<name>
```

## Editing a description is a behaviour change

A skill only runs when its description triggers, so an edit there can silently
stop it firing. `tests/skill-descriptions.test.sh` locks the mechanical
properties (name matches the directory, single-line description, length bounds,
no duplicates) and lists skills whose description says what they do but never
when to use them. It cannot tell you whether the new wording actually triggers:
for that, run `skill-creator`'s eval against representative prompts before and
after the edit, and compare.

Never copy a skill into a platform wrapper. The source directory under
`skills/` is the only authored copy; wrappers contain only generated links.
