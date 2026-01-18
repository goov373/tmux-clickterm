# clickterm - Claude Code Instructions

> This file provides context for Claude Code when working on this project.
> For detailed documentation, see AGENTS.md.

## Project Summary

**clickterm** is a mouse-driven tmux environment. Users click status bar buttons instead of using keyboard shortcuts.

**Philosophy:** Mouse-first, discoverable, safe defaults, beautiful (Nord theme).

## Quick Architecture

```
Button Click → dispatch.sh → handler script → tmux command
```

**Key files:**
- `dispatch.sh` - Routes button IDs to handlers
- `split.sh`, `close.sh`, `launch.sh` - Action handlers
- `tmux-theme-*.conf` - Theme and button definitions
- `configs/tmux.conf` - Main tmux config

## File Map

| Action | Files to Modify |
|--------|-----------------|
| Add new button | `tmux-theme-*.conf`, `dispatch.sh`, new handler script |
| Change button style | `tmux-theme-dark.conf`, `tmux-theme-light.conf` |
| Add new tool | `dispatch.sh`, update `launch.sh` case or add new handler |
| Change split behavior | `split.sh` |
| Change close behavior | `close.sh` |
| Update help | `help-viewer.sh` |

## Coding Style

- Bash scripts with `#!/bin/bash`
- Quote all variables: `"$VAR"`
- Use `$()` for command substitution
- Exit 0 on success, 1 on error
- Add comments for tmux commands

## Common tmux Patterns

```bash
# Get variable
VAL=$(tmux display-message -p '#{pane_current_command}')

# User message
tmux display-message "Hello"

# Send keystrokes
tmux send-keys "command" Enter

# Split
tmux split-window -h  # vertical (columns)
tmux split-window -v  # horizontal (rows)
```

## Adding a Button

1. Add to `status-right` in both theme files:
   ```
   #[range=user|myid] [ Label ] #[norange]
   ```

2. Add case to `dispatch.sh`:
   ```bash
   myid)
       ~/.config/clickterm/myhandler.sh
       ;;
   ```

3. Create handler script

4. Test: `make dev`

## Development Commands

```bash
make dev          # Install + reload tmux
make lint         # Check scripts with shellcheck
make theme-dark   # Switch to dark mode
make theme-light  # Switch to light mode
```

## Testing

Before committing:
- `make lint` passes
- Buttons work in both themes
- Edge cases handled (last pane, busy pane)

## Roadmap

Planned features:
- Session save/restore
- Workspace support
- Dynamic button config (JSON)
- Auto dark/light theme switching

## Full Documentation

See `AGENTS.md` for complete architecture details, coding conventions, and extension guides.
