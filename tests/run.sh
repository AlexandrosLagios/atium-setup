#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dotfiles_dir="$repo_root/dotfiles"

if ! command -v zsh >/dev/null 2>&1; then
  printf '%s\n' 'zsh is required to validate zsh configuration' >&2
  exit 1
fi

if [ ! -d "$dotfiles_dir" ] || ! find "$dotfiles_dir" -type f -name '*.zsh' -print -quit | grep -q .; then
  printf '%s\n' 'expected at least one zsh configuration file' >&2
  exit 1
fi

find "$dotfiles_dir" -type f -name '*.zsh' -exec zsh -n {} \;
if [ -x "$repo_root/tests/sync-skills.test.sh" ]; then
  "$repo_root/tests/sync-skills.test.sh"
fi
if [ -x "$repo_root/tests/skill-compatibility.test.sh" ]; then
  "$repo_root/tests/skill-compatibility.test.sh"
fi
if [ -x "$repo_root/tests/global-guidance.test.sh" ]; then
  "$repo_root/tests/global-guidance.test.sh"
fi
if [ -x "$repo_root/tests/personal-skills-guard.test.sh" ]; then
  "$repo_root/tests/personal-skills-guard.test.sh"
fi
if [ -x "$repo_root/tests/plugin-delivery.test.sh" ]; then
  "$repo_root/tests/plugin-delivery.test.sh"
fi
if [ -x "$repo_root/tests/scan-skills.test.sh" ]; then
  "$repo_root/tests/scan-skills.test.sh"
fi
if [ -x "$repo_root/tests/agent-cost.test.sh" ]; then
  "$repo_root/tests/agent-cost.test.sh"
fi
if [ -x "$repo_root/tests/skill-prose.test.sh" ]; then
  "$repo_root/tests/skill-prose.test.sh"
fi
if [ -x "$repo_root/tests/skill-descriptions.test.sh" ]; then
  "$repo_root/tests/skill-descriptions.test.sh"
fi
if [ -x "$repo_root/tests/audit-harness.test.sh" ]; then
  "$repo_root/tests/audit-harness.test.sh"
fi

for operational_script in agent-cost audit-harness bootstrap check-secrets doctor install-global-guidance install-routines install-third-party refresh-plugins release-skills scan-skills sync-plugin-skills sync-skills; do
  script_path="$repo_root/scripts/$operational_script"
  if [ ! -x "$script_path" ]; then
    printf 'expected executable script: %s\n' "$script_path" >&2
    exit 1
  fi
  "$script_path" --help >/dev/null
done

printf '%s\n' 'zsh syntax checks passed'
