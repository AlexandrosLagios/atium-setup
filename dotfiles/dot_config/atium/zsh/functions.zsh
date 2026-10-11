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
  setopt localoptions extendedglob
  local raw value escaped note=""
  read -rs "raw?value for $1: " || return 1
  print -u2
  value=${${raw##[[:space:]]#}%%[[:space:]]#}
  [[ -n $value ]] || { print -u2 "secret-set: empty value, nothing stored"; return 1; }
  # security -i reads the command from stdin, so the value never reaches argv.
  escaped=${${value//\\/\\\\}//\"/\\\"}
  print -r -- "add-generic-password -U -a atium -s \"$1\" -w \"$escaped\"" | security -i
  [[ "$(secret "$1")" == "$value" ]] || { print -u2 "secret-set: $1 was not stored"; return 1; }
  (( ${#raw} != ${#value} )) && note=", trimmed $(( ${#raw} - ${#value} )) whitespace"
  print -u2 "stored $1: ${#value} chars$note"
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

with-secret() {
  local -a pairs
  while (( $# )) && [[ $1 != -- ]]; do pairs+=("$1"); shift; done
  (( ${#pairs} && $# > 1 )) || { print -u2 "usage: with-secret VAR=NAME... -- COMMAND..."; return 2; }
  shift
  # One argument runs as a shell string, so it can expand $VAR and use pipes.
  (( $# == 1 )) && set -- eval "$1"
  (
    setopt pipefail nomultios
    local pair value
    for pair in $pairs; do
      [[ $pair == [A-Za-z_]*=?* ]] || { print -u2 "with-secret: expected VAR=NAME, got $pair"; exit 2; }
      value=$(secret "${pair#*=}") || exit 1
      export "${pair%%=*}=$value"
    done
    export WITH_SECRET_VARS="${(j: :)pairs%%=*}"
    { "$@" 2>&1 1>&3 3>&- | _with_secret_mask >&2 } 3>&1 | _with_secret_mask
  )
}

_with_secret_mask() {
  awk '
    BEGIN { n = split(ENVIRON["WITH_SECRET_VARS"], vars, " ") }
    {
      line = $0
      for (i = 1; i <= n; i++) {
        s = ENVIRON[vars[i]]
        if (s == "") continue
        out = ""
        while ((p = index(line, s)) > 0) {
          out = out substr(line, 1, p - 1) "***"
          line = substr(line, p + length(s))
        }
        line = out line
      }
      print line
      fflush()
    }'
}

emu-login() {
  (( $# == 1 )) || { print -u2 "usage: emu-login PREFIX (types PREFIX-email and PREFIX-password)"; return 2; }
  local email password xml
  email=$(secret "$1-email") && password=$(secret "$1-password") || return 1
  xml=$(adb exec-out uiautomator dump /dev/tty) || return 1
  local -a fields=(${(f)"$(print -r -- "$xml" | grep -o '<node [^>]*class="android.widget.EditText"[^>]*>')"})
  local email_field=${fields[(r)*password=?false?*]} password_field=${fields[(r)*password=?true?*]}
  [[ -n $email_field && -n $password_field ]] || { print -u2 "emu-login: no email and password fields on screen"; return 1; }
  _emu_type "$email_field" "$email" && _emu_type "$password_field" "$password"
}

_emu_type() {
  [[ $1 =~ 'bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"' ]] || return 1
  local x=$(( (match[1] + match[3]) / 2 )) y=$(( (match[2] + match[4]) / 2 ))
  local text=${${2//\'/\'\\\'\'}// /%s}
  # ponytail: appends to prefilled text; clear the field first if a login screen prefills it.
  # The command goes through stdin, so the value never reaches the host argv.
  print -r -- "input tap $x $y && input text '$text'" | adb shell -T
}
