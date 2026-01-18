# OpenCode Project Rules

## Project Type
This is a bash/shell scripting project for tmux customization.

## Key Conventions

### File Types
- `.sh` files: Bash scripts (use `#!/bin/bash`)
- `.conf` files: tmux configuration
- `.json` files: Theme definitions and configs

### Bash Style
- Use `set -e` only when fail-fast is desired
- Quote all variables: `"$VAR"` not `$VAR`
- Use `$()` for command substitution
- Add comments for tmux-specific commands

### Testing
- Run `make lint` before committing
- Test buttons in both dark and light themes
- Test edge cases (last pane, busy pane)

## Quick Commands
```bash
make dev        # Install + reload tmux
make lint       # Check scripts with shellcheck
make theme-dark # Switch to dark mode
```

## File Locations
- Main scripts: `*.sh` in project root
- Theme files: `tmux-theme-*.conf`
- tmux config: `configs/tmux.conf`
- Docs: `docs/` and `AGENTS.md`

## Adding Features
1. Read `docs/EXTENDING.md` for guides
2. Add button to theme files
3. Add handler to `dispatch.sh`
4. Create handler script if needed
5. Test with `make dev`
