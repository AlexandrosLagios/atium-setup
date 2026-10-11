#!/bin/zsh -f
set -eu

repo_root=${0:A:h:h}
source "$repo_root/dotfiles/dot_config/atium/zsh/functions.zsh"

secret() {
  case $1 in
    api-key) print -r -- 'hunter2' ;;
    app-stage-email) print -r -- 'qa@example.com' ;;
    app-stage-password) print -r -- "p ss'w" ;;
    *) return 1 ;;
  esac
}

out=$(with-secret KEY=api-key -- sh -c 'echo "out=$KEY"; echo "err=$KEY" >&2' 2>&1)
[[ $out == *'out=***'* && $out == *'err=***'* && $out != *hunter2* ]]

out=$(with-secret KEY=api-key -- sh -c 'echo "out=$KEY"; echo "err=$KEY" >&2' 2>/dev/null)
[[ $out == 'out=***' ]]

out=$(with-secret KEY=api-key -- 'echo "Bearer $KEY" | sed s/Bearer/Token/')
[[ $out == 'Token ***' ]]

with-secret KEY=api-key -- sh -c 'exit 3' && exit 1 || [[ $? == 3 ]]
with-secret KEY=missing -- true 2>/dev/null && exit 1
with-secret -- true 2>/dev/null && exit 1

adb_log=$(mktemp)
adb() {
  case $1 in
    exec-out) print -r -- '<hierarchy><node index="0" text="" class="android.widget.EditText" password="false" bounds="[0,100][200,140]" /><node index="1" text="" class="android.widget.EditText" password="true" bounds="[0,200][200,260]" /></hierarchy>UI hierchary dumped to: /dev/tty' ;;
    shell) cat >> "$adb_log" ;;
  esac
}
emu-login app-stage
grep -Fxq "input tap 100 120 && input text 'qa@example.com'" "$adb_log"
grep -Fxq "input tap 100 230 && input text 'p%sss'\\''w'" "$adb_log"
rm -f "$adb_log"

printf '%s\n' 'secret helper tests passed'
