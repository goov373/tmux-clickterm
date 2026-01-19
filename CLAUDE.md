# clickterm - Claude Code Instructions

> This file provides context for Claude Code when working on this project.
> For detailed documentation, see AGENTS.md.

## Project Summary

**clickterm** is a mouse-driven tmux environment with a native macOS app. Users click status bar buttons instead of using keyboard shortcuts.

**Philosophy:** Mouse-first, discoverable, safe defaults, beautiful (Nord theme).

## Architecture

Two components:

1. **Native macOS App** (`app/clickterm/main.swift`)
   - Launches iTerm2 with tmux session
   - Auto-installs scripts on first run
   - Reuses existing iTerm instance (no duplicate dock icons)

2. **tmux Layer** (shell scripts)
   - Clickable buttons in status bar
   - Handler scripts for each action

```
Button Click → dispatch.sh → handler script → tmux command
```

## Key Files

| Action | Files to Modify |
|--------|-----------------|
| Change app behavior | `app/clickterm/main.swift`, then `./app/build-app.sh` |
| Add new button | `tmux-theme-*.conf`, `dispatch.sh`, new handler script |
| Change button style | `tmux-theme-dark.conf`, `tmux-theme-light.conf` |
| Add new tool | `dispatch.sh` (use `launch.sh` for busy-pane detection) |
| Change split behavior | `split.sh` |
| Change close behavior | `close.sh` |
| Update help | `help-viewer.sh` |

## File Map

```
tmux-clickterm/
├── app/
│   ├── clickterm/main.swift    # macOS app source
│   ├── build/clickterm.app     # Built app bundle
│   └── build-app.sh            # Build script
├── configs/tmux.conf           # Main tmux config
├── dispatch.sh                 # Routes button clicks
├── split.sh, close.sh, ...     # Handler scripts
├── tmux-theme-dark.conf        # Dark theme + buttons
├── tmux-theme-light.conf       # Light theme + buttons
└── install.sh                  # Manual install (no app)
```

## Coding Style

**Bash:**
- Quote all variables: `"$VAR"`
- Use `$()` for command substitution
- Exit 0 on success, 1 on error

**Swift:**
- Keep main.swift minimal
- Use guard for early returns

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
# Scripts
make dev          # Install + reload tmux
make lint         # Check scripts with shellcheck

# App
./app/build-app.sh                              # Build
cp -r app/build/clickterm.app /Applications/    # Install

# Themes
make theme-dark   # Switch to dark mode
make theme-light  # Switch to light mode
```

## Testing

Before committing:
- `make lint` passes
- Buttons work in both themes
- Edge cases handled (last pane, busy pane)
- If app changed: rebuild and test from /Applications

## Full Documentation

See `AGENTS.md` for complete architecture details, coding conventions, and extension guides.
