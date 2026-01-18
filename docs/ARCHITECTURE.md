# clickterm Architecture

This document provides a deep technical dive into how clickterm works.

## Overview

clickterm is a layer on top of tmux that replaces keyboard-driven interaction with mouse-driven buttons. It consists of:

1. **tmux configuration** - Defines buttons and binds mouse events
2. **Dispatcher** - Routes button clicks to handler scripts
3. **Handler scripts** - Implement actions with safety logic
4. **Theme files** - Define visual styling

## System Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              iTerm2                                      │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                              tmux                                  │  │
│  │                                                                    │  │
│  │  ┌──────────────────────────────────────────────────────────────┐ │  │
│  │  │                         Panes                                 │ │  │
│  │  │                                                               │ │  │
│  │  │   ┌─────────────────┐     ┌─────────────────────────────┐    │ │  │
│  │  │   │                 │     │                             │    │ │  │
│  │  │   │   Shell/Tool    │     │        Shell/Tool           │    │ │  │
│  │  │   │                 │     │                             │    │ │  │
│  │  │   └─────────────────┘     └─────────────────────────────┘    │ │  │
│  │  │                                                               │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                                                                    │  │
│  │  ┌──────────────────────────────────────────────────────────────┐ │  │
│  │  │ [ │ Split ] [ ─ Stack ] [ × Close ] [ ⎋ Exit ] [ ? ] [tools] │ │  │
│  │  └──────────────────────────────────────────────────────────────┘ │  │
│  │                          Status Bar                                │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Click Flow

When a user clicks a button in the status bar:

```
1. User clicks [ Split ]
       │
       ▼
2. tmux detects MouseUp1Status event
       │
       ▼
3. tmux extracts button ID from #{mouse_status_range}
   (Returns "splitv" based on #[range=user|splitv] in theme)
       │
       ▼
4. tmux runs: dispatch.sh "splitv"
       │
       ▼
5. dispatch.sh matches "splitv" case
       │
       ▼
6. dispatch.sh executes: split.sh v
       │
       ▼
7. split.sh checks constraints (horizontal limit)
       │
       ▼
8. split.sh runs: tmux split-window -h
       │
       ▼
9. New pane appears
```

## Button Definition Syntax

Buttons are defined in the tmux theme files using the `#[range=user|<id>]` syntax:

```tmux
set -g status-right "\
#[range=user|splitv]#[fg=#d8dee9] [ │ Split ] #[norange]\
#[range=user|splith]#[fg=#d8dee9] [ ─ Stack ] #[norange]\
#[range=user|close]#[fg=#bf616a] [ × Close ] #[norange]"
```

**Breakdown:**
- `#[range=user|splitv]` - Start clickable region with ID "splitv"
- `#[fg=#d8dee9]` - Set foreground color
- ` [ │ Split ] ` - Visible button text
- `#[norange]` - End clickable region

When clicked, tmux returns the ID ("splitv") via `#{mouse_status_range}`.

## File Responsibilities

### configs/tmux.conf

The main tmux configuration file. Key sections:

```tmux
# Enable mouse support
set -g mouse on

# Source theme (defines buttons)
source-file ~/.config/clickterm/tmux-theme-dark.conf

# Bind button clicks to dispatcher
bind -n MouseUp1Status run-shell '~/.config/clickterm/dispatch.sh "#{mouse_status_range}"'
```

### dispatch.sh

Central router that maps button IDs to handlers:

```bash
case "$BUTTON" in
    splitv)   ~/.config/clickterm/split.sh v ;;
    splith)   ~/.config/clickterm/split.sh h ;;
    close)    ~/.config/clickterm/close.sh ;;
    exit)     ~/.config/clickterm/exit.sh ;;
    help)     tmux display-popup ... ;;
    opencode) ~/.config/clickterm/launch.sh opencode ;;
    claude)   ~/.config/clickterm/launch.sh claude ;;
esac
```

### Handler Scripts

Each handler implements one action with appropriate safety checks:

| Script | Purpose | Safety Logic |
|--------|---------|--------------|
| `split.sh` | Split panes | Limits horizontal splits to 1 per column |
| `close.sh` | Close pane | Prevents closing last pane, confirms busy panes |
| `exit.sh` | Send Ctrl+C | Simple, no safety needed |
| `launch.sh` | Launch tools | Detects busy panes, offers menu |
| `help-viewer.sh` | Show help | Handles input/mouse cleanly |

## Safety Patterns

### Last Pane Protection (close.sh)

```bash
PANE_COUNT=$(tmux display-message -p '#{window_panes}')
if [ "$PANE_COUNT" = "1" ]; then
    tmux display-message "Can't close last pane"
    exit 0
fi
```

### Busy Pane Detection (close.sh, launch.sh)

```bash
CURRENT_CMD=$(tmux display-message -p '#{pane_current_command}')
if [ "$CURRENT_CMD" != "zsh" ] && [ "$CURRENT_CMD" != "bash" ]; then
    # Pane is busy - confirm or offer options
fi
```

### Horizontal Split Limit (split.sh)

```bash
PANE_AT_TOP=$(tmux display-message -p '#{pane_at_top}')
PANE_AT_BOTTOM=$(tmux display-message -p '#{pane_at_bottom}')

if [ "$PANE_AT_TOP" = "0" ] || [ "$PANE_AT_BOTTOM" = "0" ]; then
    tmux display-message "Column already stacked (max 1 horizontal split)"
    exit 0
fi
```

## Theme System

### Color Definitions

The Nord palette is defined in `theme.json`:

```json
{
  "palette": {
    "nord0": "#2e3440",
    "nord1": "#3b4252",
    ...
  },
  "dark": {
    "bg-base": "#2e3440",
    "fg-primary": "#d8dee9",
    ...
  },
  "light": {
    "bg-base": "#eceff4",
    "fg-primary": "#2e3440",
    ...
  }
}
```

### Theme Files

Two theme files provide dark and light variants:

- `tmux-theme-dark.conf` - Dark mode (default)
- `tmux-theme-light.conf` - Light mode

### Theme Switching

The `theme-switch.sh` script modifies `~/.tmux.conf` to source the appropriate theme file.

## Popup System

The help popup uses tmux's `display-popup` command with a custom viewer script:

```bash
tmux display-popup -b rounded -w 72 -h 30 -E "~/.config/clickterm/help-viewer.sh"
```

The viewer script (`help-viewer.sh`):
1. Disables terminal echo
2. Hides cursor
3. Displays formatted help content
4. Enables mouse tracking for X button
5. Waits for q, Escape, or X click
6. Restores terminal state

## tmux Format Strings

Common format strings used:

| Format | Returns |
|--------|---------|
| `#{pane_current_command}` | Running process name (zsh, vim, etc.) |
| `#{window_panes}` | Number of panes in window |
| `#{pane_at_top}` | 1 if pane is at top edge, 0 otherwise |
| `#{pane_at_bottom}` | 1 if pane is at bottom edge |
| `#{mouse_status_range}` | Button ID from status bar click |

## Installation Layout

```
~/.config/clickterm/
├── close.sh
├── dispatch.sh
├── exit.sh
├── help-viewer.sh
├── help.txt (legacy)
├── launch.sh
├── split.sh
├── sync-theme.sh (legacy)
├── theme-switch.sh
├── theme.json
├── tmux-theme-dark.conf
└── tmux-theme-light.conf

~/.tmux.conf (sources theme from above)

~/.config/opencode/themes/
├── nord-dark.json
└── nord-light.json

~/Library/Application Support/iTerm2/DynamicProfiles/
└── Nord.json
```

## Performance Considerations

1. **Static hex colors** - No runtime computation for colors
2. **Direct script execution** - No intermediate interpreters
3. **Minimal tmux queries** - Only fetch needed variables
4. **No polling** - Event-driven via mouse clicks

## Extension Points

### Adding a Button

1. Add `#[range=user|newid]` section to theme files
2. Add case to `dispatch.sh`
3. Create handler script

### Adding a Theme

1. Create new `tmux-theme-<name>.conf`
2. Update `theme-switch.sh` to support new theme
3. Add corresponding OpenCode theme if needed

### Adding Safety Checks

Follow the pattern in existing handlers:
1. Query relevant tmux state
2. Check conditions
3. Show message or confirm dialog if unsafe
4. Execute action if safe
