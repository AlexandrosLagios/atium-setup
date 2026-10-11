---
name: secrets
description: "Use when a command needs an API key, token, password, or connection string on this machine, when a secret is missing, or when the user asks to store, find, or list one. Reads secrets from the macOS Keychain through the secret helpers, inside the command that uses them, and never from chat or a plaintext file."
compatibility: "macOS Keychain through the security CLI. Elsewhere, read the secret from an environment variable."
---

# secrets

Secrets live in the macOS Keychain, one generic-password item per secret, under the account `atium`. Zsh helpers in `dotfiles/dot_config/atium/zsh/functions.zsh` wrap the `security` CLI:

| Helper | Does |
|---|---|
| `secret-set NAME` | Prompts once for the value, trims the whitespace around it, stores it, and prints the stored length. Replaces an existing value. |
| `with-secret VAR=NAME... -- COMMAND` | Runs the command with each secret in its variable, and replaces each value with `***` in stdout and stderr. |
| `secret NAME` | Prints the value, for use inside `$(...)`. |
| `secret-ls` | Lists the stored names, never the values. |
| `emu-login PREFIX` | Types `PREFIX-email` and `PREFIX-password` into the login fields of the Android emulator. |

## Names

Name a secret `<system>-<environment>-<what>`, in lower case with hyphens: `acme-stage-api-key`, `acme-production-mongo-uri`. One name holds one value. Never put the value, a user name, or a host in the name.

## Read

Read a secret with `with-secret`, in the same command that uses the secret. Each shell call starts fresh, so a value exported in an earlier call is gone.

```bash
with-secret API_KEY=acme-stage-api-key -- ./run-task --env stage
```

Your shell expands `$API_KEY` before `with-secret` sets the variable. To use the value in an argument or a pipe, give the command as one single-quoted string:

```bash
with-secret TOKEN=acme-stage-api-key -- 'curl -s -H "Authorization: Bearer $TOKEN" https://example.com/me | jq .id'
```

The mask replaces the exact value only. A value that the command encodes, for example in Base64 for HTTP Basic authentication, stays visible. Do not use `curl -v` with Basic authentication.

`$(secret NAME)` inside a command also works, but the output of that command is not masked.

Where `security` does not exist (Linux, CI), read the secret from the environment variable that the task documents.

## Log in on the Android emulator

To log in to an app on the emulator, open the login screen, then run `emu-login PREFIX`:

```bash
emu-login box-stage
```

`emu-login` finds the email field and the password field with `uiautomator`, then types the values through `adb`. You never see the password. Then tap the login button yourself. When the field already contains text, `emu-login` appends to that text. Set `ANDROID_SERIAL` when more than one device is connected.

## Find

Look in this order, and stop at the first hit:

1. Run `secret-ls`, then read the matching name with `with-secret`.
2. Check whether the environment already exports the variable that the command reads.
3. Ask the user to store the secret with `secret-set NAME`. Name the secret for them.

Do not read a secret from these sources:

- A value pasted into the chat. Tell the user to store it with `secret-set` instead.
- A plaintext `.env` file or a config file. Ask the user before you read one. Suggest that they move the value into the Keychain.
- A database collection that stores keys, such as an API-key table on a production database.
- A cloud secret store, a browser password store, or another user's files, unless the user asks for that source by name.

## Store

Only the user runs `secret-set`, because the prompt keeps the value out of the transcript and out of the shell history. Never call the `security` CLI to store a secret.

## Guard hook

In Claude Code, the `atium-skills` plugin installs a PreToolUse hook, `guard-secrets.py`. The hook blocks these Bash commands:

- A direct call to the `security` CLI.
- A call to `secret-set`.
- A bare `secret NAME` outside `$(...)`, because it prints the value.
- `echo`, `printf`, or `print` with `$(secret ...)`.

The hook stops an accident, not a determined command: `s=$(secret x); echo "$s"` passes the hook. Obey the rules below as well.

## Rules

- Never print, log, or echo a secret. Never write a secret to a file, a commit, a PR, or a message.
- To show which target a connection string points at, print the host only: `with-secret URI=acme-stage-mongo-uri -- 'printf "%s\n" "$URI" | sed -E "s#^[a-z+]+://[^@]*@##; s#/.*\$##"'`.
- Before a command writes with a secret, check that host against the expected environment, and stop when the host differs.
