---
name: secrets
description: "Use when a command needs an API key, token, password, or connection string on this machine, when a secret is missing, or when the user asks to store, find, or list one. Reads secrets from the macOS Keychain through the secret helpers, inside the command that uses them, and never from chat or a plaintext file."
compatibility: "macOS Keychain through the security CLI. Elsewhere, read the secret from an environment variable."
---

# secrets

Secrets live in the macOS Keychain, one generic-password item per secret, under the account `atium`. Three zsh helpers in `dotfiles/dot_config/atium/zsh/functions.zsh` wrap the `security` CLI:

| Helper | Does |
|---|---|
| `secret-set NAME` | Prompts twice for the value and stores it. Replaces an existing value. |
| `secret NAME` | Prints the value, for use inside `$(...)`. |
| `secret-ls` | Lists the stored names, never the values. |

## Names

Name a secret `<system>-<environment>-<what>`, in lower case with hyphens: `acme-stage-api-key`, `acme-production-mongo-uri`. One name holds one value. Never put the value, a user name, or a host in the name.

## Read

Read the secret inside the same command that uses it. Each shell call starts fresh, so a value exported in an earlier call is gone.

```bash
API_KEY="$(secret acme-stage-api-key)" ./run-task --env stage
```

When the helpers are not loaded, call the CLI directly:

<!-- scan-skills: allow S001 N001 the keychain entry is this skill's documented secret source -->
```bash
API_KEY="$(security find-generic-password -a atium -s acme-stage-api-key -w)" ./run-task --env stage
```

Where `security` does not exist (Linux, CI), read the secret from the environment variable that the task documents.

## Find

Look in this order, and stop at the first hit:

1. Run `secret-ls`, then read the matching name with `secret`.
2. Check whether the environment already exports the variable that the command reads.
3. Ask the user to store the secret with `secret-set NAME`. Name the secret for them.

Do not read a secret from these sources:

- A value pasted into the chat. Tell the user to store it with `secret-set` instead.
- A plaintext `.env` file or a config file. Ask the user before you read one. Suggest that they move the value into the Keychain.
- A database collection that stores keys, such as an API-key table on a production database.
- A cloud secret store, a browser password store, or another user's files, unless the user asks for that source by name.

## Store

Only the user runs `secret-set`, because the prompt keeps the value out of the transcript and out of the shell history. Never run `security add-generic-password` with a value on the command line.

## Rules

- Never print, log, or echo a secret. Never write a secret to a file, a commit, a PR, or a message.
- To show which target a connection string points at, print the host only: `printf '%s' "$URI" | sed -E 's#^[a-z+]+://[^@]*@##; s#/.*$##'`.
- Before a command writes with a secret, check that host against the expected environment, and stop when it differs.

## Older items

`cloudflare-dns` keeps its token under the service `cloudflare-dns-token` with one account label per Cloudflare account. That skill documents its own read command. Store every new secret with `secret-set`.
