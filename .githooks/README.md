# Git Hooks

This directory contains git hooks for the clickterm project.

## Setup

To enable the hooks, run:

```bash
make hooks
```

Or manually:

```bash
git config core.hooksPath .githooks
```

## Available Hooks

### pre-commit

Runs `shellcheck` on all staged `.sh` files before allowing a commit.

- **Requires:** shellcheck (`brew install shellcheck`)
- **Bypass:** `git commit --no-verify` (not recommended)

## Disabling Hooks

To disable hooks temporarily:

```bash
git commit --no-verify -m "your message"
```

To disable hooks permanently:

```bash
git config --unset core.hooksPath
```
