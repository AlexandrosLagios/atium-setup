---
name: difit-review
description: Use when the user wants to visually read or review a git diff in a GitHub-style local web UI instead of raw diff text — the current branch vs its base, a specific commit, staged/working changes, or a GitHub PR. Launches difit as a background server and hands back the localhost URL.
---

# difit-review

Open a diff in [difit](https://github.com/yoshiko-pg/difit), a local GitHub-style "Files changed" viewer, so the user can read code in the browser (e.g. cmux's browser pane) while Claude Code stays in the terminal.

`difit` is installed globally (`difit --version` should print 5.x). If it is missing, tell the user to run `npm install -g difit`; do not auto-install.

## Pick the target

Map the request to a difit invocation. Default base for branch comparisons is `origin/development`.

| User wants | Command target |
|---|---|
| This branch's changes (default) | `difit HEAD origin/development --merge-base` |
| A named branch vs base | `difit <branch> origin/development --merge-base` |
| One specific commit | `difit <sha>` (or `difit HEAD~1 HEAD`) |
| Uncommitted (staged + unstaged) | `difit .` |
| Staged only / unstaged only | `difit staged` / `difit working` |
| A GitHub PR | `difit --pr <pr-url>` |

Always use `--merge-base` when comparing a branch against a base — it resolves the true 3-dot diff (only what the branch added), matching the user's review habit. Do not use it for single-commit or `.`/`staged`/`working` modes.

## Launch it (non-blocking)

difit runs a blocking server, so launch it as a **background process** with `--no-open` and a fixed `--port`, then confirm the listening port:

1. Start the server through the host's non-blocking command facility. In Claude
   Code, use a background command; in Codex, keep it in a background terminal
   session:
   ```bash
   difit <target...> --no-open --port 4966
   ```
2. Wait ~2s, then confirm the port (difit auto-reassigns if 4966 is taken):
   ```bash
   lsof -nP -iTCP -sTCP:LISTEN | grep -i node
   ```
   Find difit's pid (the most recent node listener) and read its port.
3. Hand the user the URL: **http://localhost:<port>** — tell them to open it in cmux's browser pane or any browser.

If the diff is empty (clean tree, or branch is even with base), say so instead of launching — point them at a meaningful target (e.g. `HEAD~1 HEAD`).

## Stopping / re-running

- One difit server per port. To review a different diff, either kill the prior background task first or let difit pick a new port.
- The inline-comment → "copy as AI prompt" feature in difit's UI is the intended handoff: the user copies review comments out and pastes them back to the coding agent.

## Shell alias

The user also has a `review` zsh function (in `~/.zshrc`) wrapping the branch-vs-base case: `review [target] [base] [extra flags]`. Mention it if they'd rather launch from their own terminal than through Claude Code.
