# Canonical Local Setup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `atium-setup` a public-safe, canonical source for deployed dotfiles and shared Codex/Claude skills.

**Architecture:** The repository root uses a chezmoi source-root pointer; actual dotfiles live once under `dotfiles/` and deploy to `$HOME`. Canonical skills live once under `skills/`; a safe shell script links each directory into platform-specific skill locations without overwriting user-owned files.

**Tech Stack:** POSIX shell, zsh, chezmoi, Homebrew Bundle, pre-commit, Gitleaks, GitHub Actions.

---

## File Structure

- `.chezmoiroot` — makes `dotfiles/` the chezmoi source state.
- `.gitignore` — excludes private overlays, dotenv files, generated reports, and macOS metadata.
- `dotfiles/dot_zshrc` — deployed `~/.zshrc` entrypoint.
- `dotfiles/dot_config/atium/zsh/*.zsh` — real modular zsh configuration.
- `skills/atium-repository-maintenance/SKILL.md` — initial canonical skill.
- `scripts/{bootstrap,doctor,sync-skills,check-secrets}` — setup and safety tooling.
- `tests/{run.sh,sync-skills.test.sh}` — dependency-free behavioral and syntax tests.
- `Brewfile`, `.pre-commit-config.yaml`, `.github/workflows/secrets.yml` — reproducible dependencies and secret-scanning guards.
- `docs/secrets.md` and `README.md` — public setup, update, and private-overlay instructions.

### Task 1: Establish the canonical source and public-safety boundary

**Files:**
- Create: `.chezmoiroot`, `.gitignore`, `Brewfile`, `docs/secrets.md`
- Modify: `README.md`, `docs/superpowers/specs/2026-07-25-canonical-local-setup-design.md`

- [ ] Add `.chezmoiroot` with `dotfiles`, mapping `dotfiles/dot_zshrc` to `~/.zshrc` and `dotfiles/dot_config` to `~/.config`.
- [ ] Ignore actual local secret overlays and dotenv/key files, but no canonical configuration.
- [ ] Document that tracked files are real deployed configuration and `~/.config/atium/private.zsh` is the sole untracked overlay.
- [ ] Run `git diff --check` and commit the source-boundary changes.

### Task 2: Build and test modular zsh dotfiles

**Files:**
- Create: `dotfiles/dot_zshrc`
- Create: `dotfiles/dot_config/atium/zsh/{paths,runtimes,aliases,functions,prompt}.zsh`
- Create: `tests/run.sh`

- [ ] Write `tests/run.sh` first; it must fail if no zsh files exist and otherwise run `zsh -n` over all files under `dotfiles/`.
- [ ] Run `tests/run.sh` and confirm it fails because zsh source files are absent.
- [ ] Add the entrypoint and real modular configuration: portable PATH setup; optional NVM/Bun, zoxide, and Starship integration; NVM `.nvmrc` switching; safe aliases; and generic worktree/review helpers. Never include credentials, company configuration, or a user-specific absolute path.
- [ ] Re-run `tests/run.sh` and commit only after all zsh sources parse.

### Task 3: Deploy canonical skills without copies

**Files:**
- Create: `skills/atium-repository-maintenance/SKILL.md`
- Create: `scripts/sync-skills`, `tests/sync-skills.test.sh`
- Modify: `tests/run.sh`

- [ ] Write a failing linker test in a temporary directory. It must prove that `--dry-run` does not mutate files, a normal run creates absolute symlinks in both target roots, and an existing regular destination is never replaced.
- [ ] Run `tests/sync-skills.test.sh` and confirm failure because `scripts/sync-skills` is absent.
- [ ] Implement the smallest idempotent linker: find the repository from the script location; accept `ATIUM_CODEX_SKILLS_DIR` and `ATIUM_CLAUDE_SKILLS_DIR` overrides; default to the actual Codex and Claude skill folders; and create no duplicate skill text.
- [ ] Add the real initial repository-maintenance skill, run all tests, and commit.

### Task 4: Add bootstrap, diagnostics, and secret protection

**Files:**
- Create: `scripts/bootstrap`, `scripts/doctor`, `scripts/check-secrets`
- Create: `.pre-commit-config.yaml`, `.github/workflows/secrets.yml`
- Modify: `tests/run.sh`, `README.md`

- [ ] Extend the test harness first to require executable operational scripts and a non-mutating `--help` interface.
- [ ] Run it and confirm failure because the scripts are absent.
- [ ] Implement bootstrap with an explicit `--apply` gate; it installs declared Homebrew dependencies when available, initializes chezmoi from this repository, previews by default, and synchronizes skills after apply.
- [ ] Implement `doctor` and `check-secrets`; the latter invokes Gitleaks when available and otherwise provides installation guidance.
- [ ] Add Gitleaks to pre-commit and a GitHub Action for push, pull request, and manual scans.
- [ ] Run `tests/run.sh && scripts/check-secrets && git diff --check`, then commit.

### Task 5: Verify the public release workflow

**Files:**
- Modify: `README.md` only if verification exposes a documentation mismatch.

- [ ] Run `tests/run.sh && scripts/doctor && scripts/check-secrets && git status --short`.
- [ ] Verify that no tracked file contains values copied from the original credential-bearing `.zshrc`, no skill has a duplicate authored copy, and skill targets are links.
- [ ] Commit final documentation adjustments if necessary.
