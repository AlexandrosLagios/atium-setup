# Node via Homebrew NVM. Every dependency is optional so a new machine can
# source this file before its bootstrap is complete.

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if (( $+commands[brew] )); then
  atium_nvm_prefix="$(brew --prefix nvm 2>/dev/null)"
  [[ -s "$atium_nvm_prefix/nvm.sh" ]] && source "$atium_nvm_prefix/nvm.sh"
  [[ -s "$atium_nvm_prefix/etc/bash_completion.d/nvm" ]] && source "$atium_nvm_prefix/etc/bash_completion.d/nvm"
  unset atium_nvm_prefix
fi

load-nvmrc() {
  (( $+functions[nvm_find_nvmrc] )) || return 0

  local nvmrc_path nvmrc_node_version
  nvmrc_path="$(nvm_find_nvmrc)"
  if [[ -n "$nvmrc_path" ]]; then
    nvmrc_node_version="$(nvm version "$(cat "$nvmrc_path")")"
    if [[ "$nvmrc_node_version" == "N/A" ]]; then
      nvm install
    elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
      nvm use
    fi
  elif [[ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ]] && [[ "$(nvm version)" != "$(nvm version default)" ]]; then
    nvm use default
  fi
}

if (( $+functions[nvm_find_nvmrc] )); then
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" $path)
[[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
export PATH
