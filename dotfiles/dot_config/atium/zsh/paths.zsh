# Keep user-managed command locations ahead of system locations without
# hard-coding a user name or machine-specific directory.

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  $path
)
export PATH
