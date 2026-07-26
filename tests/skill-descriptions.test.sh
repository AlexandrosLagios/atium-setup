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

    name = fields.get("name", "")
    if name != directory:
        failures.append(f"{directory}: name is {name!r}, expected {directory!r}")

    description = fields.get("description", "").strip().strip('"')
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
