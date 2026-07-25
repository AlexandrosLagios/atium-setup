if (( $+commands[eza] )); then
  alias ls="eza --icons --grid"
  alias ll="eza --icons -lah --git"
fi

(( $+commands[bat] )) && alias cat="bat"
(( $+commands[claude] )) && alias c="claude"
(( $+commands[claude] )) && alias cw="claude -w"

killport() {
  if (( $# != 1 )); then
    print -u2 "usage: killport <port>"
    return 2
  fi

  local -a pids
  pids=("${(@f)$(lsof -ti ":$1" 2>/dev/null)}")
  if (( ${#pids[@]} == 0 )); then
    print "no process is listening on port $1"
    return 0
  fi

  kill "${pids[@]}"
}
