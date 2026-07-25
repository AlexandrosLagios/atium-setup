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
printf '%s\n' 'zsh syntax checks passed'
