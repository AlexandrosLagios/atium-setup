#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

# A skill only runs if its description triggers. That description is prose, so a
# well-meaning edit can silently stop a skill firing without breaking anything a
# normal test would notice. These are the mechanical properties worth locking:
# structure, uniqueness, and length. Trigger wording is reported, not enforced.
python3 - "$repo_root" <<'PY'
import pathlib
import sys

repo_root = pathlib.Path(sys.argv[1])
MAX_DESCRIPTION = 1024
MIN_DESCRIPTION = 30
TRIGGER_HINTS = ("use when", "use for", "use this", "use it when", "trigger")
# The Agent Skills spec allows these six fields. Every other field is a Claude
# Code extension, and packaging or upload outside Claude Code fails hard on one
# rather than ignoring it. A skill that needs an extension is Claude-only, so it
# belongs in skills/.codexignore.
SPEC_FIELDS = ("allowed-tools", "compatibility", "description", "license", "metadata", "name")

codex_only = set()
codexignore = repo_root / "skills" / ".codexignore"
if codexignore.exists():
    codex_only = {
        line.strip()
        for line in codexignore.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }

failures = []
weak_triggers = []
descriptions = {}

for skill_path in sorted((repo_root / "skills").glob("*/SKILL.md")):
    directory = skill_path.parent.name
    lines = skill_path.read_text().splitlines()

    if not lines or lines[0].strip() != "---":
        failures.append(f"{directory}: missing YAML frontmatter")
        continue
    try:
        closing = lines.index("---", 1)
    except ValueError:
        failures.append(f"{directory}: unterminated frontmatter")
        continue

    fields = {}
    for line in lines[1:closing]:
        if line.startswith((" ", "\t")):
            failures.append(f"{directory}: frontmatter value spans multiple lines")
            break
        key, separator, value = line.partition(":")
        if separator:
            fields[key.strip()] = value.strip()

    for field in fields:
        if field not in SPEC_FIELDS and directory not in codex_only:
            failures.append(
                f"{directory}: frontmatter field {field!r} is a Claude Code extension; "
                f"the spec allows {', '.join(SPEC_FIELDS)}. Drop the field, or add the "
                "skill to skills/.codexignore."
            )

    name = fields.get("name", "")
    if name != directory:
        failures.append(f"{directory}: name is {name!r}, expected {directory!r}")

    raw_description = fields.get("description", "").strip()
    # `description: Use when editing X: a, b, c` is not valid YAML: an unquoted
    # scalar cannot contain ": ". Claude Code parses it anyway, and a strict
    # parser (claude.ai upload, packaging, another agent) rejects the whole file.
    if ": " in raw_description and not raw_description.startswith(('"', "'")):
        failures.append(f"{directory}: description contains ': ' and must be quoted")

    description = raw_description.strip('"')
    if not description:
        failures.append(f"{directory}: no description")
        continue
    if len(description) > MAX_DESCRIPTION:
        failures.append(f"{directory}: description is {len(description)} chars, over {MAX_DESCRIPTION}")
    if len(description) < MIN_DESCRIPTION:
        failures.append(f"{directory}: description is {len(description)} chars, too short to trigger on")
    for placeholder in ("TODO", "TBD", "FIXME", "lorem ipsum"):
        if placeholder.lower() in description.lower():
            failures.append(f"{directory}: description still contains {placeholder!r}")

    previous = descriptions.get(description)
    if previous:
        failures.append(f"{directory}: description is identical to {previous}")
    descriptions[description] = directory

    if not any(hint in description.lower() for hint in TRIGGER_HINTS):
        weak_triggers.append(directory)

if not descriptions:
    failures.append("no skills found; the glob is probably wrong")

for failure in failures:
    print(f"skill description: {failure}", file=sys.stderr)

if weak_triggers:
    print("skills whose description states what they do but not when to use it:")
    for directory in weak_triggers:
        print(f"  {directory}")
    print("  not a failure; rewrite as a trigger when one of these underfires")

sys.exit(1 if failures else 0)
PY

printf '%s\n' 'skill description checks passed'
