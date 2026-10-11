#!/usr/bin/env python3
"""PreToolUse(Bash) guard: keep Keychain secrets out of the transcript.

A guardrail against accidents, not a sandbox: `s=$(secret x); echo "$s"` still passes.
"""
import json
import re
import sys

COMMAND_START = r"(?:^|[;&|\n`{(]|\bthen\b|\bdo\b|\belse\b)\s*"
BARE_COMMAND_START = r"(?:^|[;&|\n`{]|(?<!\$)\(|\bthen\b|\bdo\b|\belse\b)\s*"
RULES = [
    (
        re.compile(COMMAND_START + r"security\s"),
        "Read a secret with `with-secret VAR=NAME -- cmd`, never with the security CLI.",
    ),
    (
        re.compile(COMMAND_START + r"secret-set\b"),
        "Only the user runs secret-set. Ask them to run `secret-set NAME` and name the secret.",
    ),
    (
        re.compile(BARE_COMMAND_START + r"secret\s"),
        "A bare `secret NAME` prints the value. Use `with-secret VAR=NAME -- cmd`.",
    ),
    (
        re.compile(r"\b(?:echo|printf|print)\b[^;&|\n]*\$\(\s*secret\s"),
        "Never print a secret.",
    ),
]

try:
    command = (json.load(sys.stdin).get("tool_input") or {}).get("command") or ""
except Exception:
    sys.exit(0)

for pattern, reason in RULES:
    if pattern.search(command):
        print(f"guard-secrets: {reason}", file=sys.stderr)
        sys.exit(2)
