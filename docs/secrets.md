# Secrets and local overrides

All tracked files in this repository are intended to be safe to publish.
Configuration that contains a credential, private hostname, work-only value, or
machine-specific path belongs outside this repository.

The supported local overlay is:

```text
~/.config/atium/private.zsh
```

It is loaded last by the deployed `.zshrc`, so it can define variables used by
the portable configuration. Source values from a password manager, keychain, or
your local environment; do not copy a plaintext token into this file if an
external secret reference is available.

Before committing or publishing, run:

```sh
scripts/check-secrets
git diff --check
```

If a secret is committed, revoke it first. Removing it from a later commit does
not remove it from Git history; rotate the credential and follow the provider's
secret-removal guidance before rewriting history.
