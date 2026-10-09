gwr() {
  local worktree
  worktree="$(git worktree list --porcelain | awk -v branch="refs/heads/$1" '
    $1 == "worktree" { current = $2 }
    $1 == "branch" && $2 == branch { print current; exit }
  ')"
  [[ -n "$worktree" ]] && git worktree remove "$worktree"
  git worktree prune
}

gwfr() {
  local worktree
  worktree="$(git worktree list --porcelain | awk -v branch="refs/heads/$1" '
    $1 == "worktree" { current = $2 }
    $1 == "branch" && $2 == branch { print current; exit }
  ')"
  [[ -n "$worktree" ]] && git worktree remove --force "$worktree"
  git worktree prune
}

review() {
  if (( ! $+commands[difit] )); then
    print -u2 "difit is required for review"
    return 1
  fi

  local base="${ATIUM_REVIEW_BASE:-origin/development}"
  difit "${1:-HEAD}" "${2:-$base}" --merge-base "${@:3}"
}

secret-set() {
  (( $# == 1 )) || { print -u2 "usage: secret-set NAME"; return 2; }
  security add-generic-password -U -a atium -s "$1" -w
}

secret() {
  (( $# == 1 )) || { print -u2 "usage: secret NAME"; return 2; }
  security find-generic-password -a atium -s "$1" -w
}

secret-ls() {
  security dump-keychain | awk -F'"' '
    /^keychain:|^class:/ { acct = ""; svce = "" }
    /"acct"<blob>=/ { acct = $4 }
    /"svce"<blob>=/ { svce = $4 }
    acct == "atium" && svce != "" { print svce; acct = ""; svce = "" }
  ' | sort -u
}
