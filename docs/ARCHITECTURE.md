# clickterm Architecture

This document provides a deep technical dive into how clickterm works.

## Overview

clickterm consists of two main components:

1. **Native macOS App** (`clickterm.app`) - Swift application that launches iTerm2 with tmux
2. **tmux Layer** - Configuration and scripts that add clickable buttons to the status bar

## System Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          clickterm.app                                    │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │ main.swift                                                           │ │
│  │   - Installs scripts to ~/.config/clickterm on first run            │ │
│  │   - Launches iTerm2 with tmux session                                │ │
│  │   - Maintains Dock presence                                          │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                              iTerm2                                       │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                              tmux                                   │  │
│  │                                                                     │  │
│  │  ┌───────────────────────────────────────────────────────────────┐ │  │
│  │  │                         Panes                                  │ │  │
│  │  │   ┌─────────────────┐     ┌─────────────────────────────┐     │ │  │
│  │  │   │  Shell/Tool     │     │        Shell/Tool           │     │ │  │
│  │  │   └─────────────────┘     └─────────────────────────────┘     │ │  │
│  │  └───────────────────────────────────────────────────────────────┘ │  │
│  │                                                                     │  │
│  │  ┌───────────────────────────────────────────────────────────────┐ │  │
│  │  │ [ Split ] [ Stack ] [ Close ] [ Exit ] [ ? ] [ opencode ]     │ │  │
│  │  └───────────────────────────────────────────────────────────────┘ │  │
│  │                          Status Bar (clickable)                     │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

## macOS App Architecture

### main.swift

The native app is a minimal Swift application (~115 lines) with these responsibilities:

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_:) {
        installScriptsIfNeeded()  // First-run setup
        launchiTermWithTmux()     // Launch terminal
        NSApp.setActivationPolicy(.regular)  // Show in Dock
    }
    
    func applicationShouldHandleReopen(_:hasVisibleWindows:) {
        launchiTermWithTmux()  // Dock icon clicked again
        return true
    }
}
```

### Script Installation

On first run, the app:

1. Creates `~/.config/clickterm/` directory
2. Copies bundled scripts from `Resources/scripts/`
3. Makes scripts executable (chmod 755)
4. Installs `~/.tmux.conf` (backs up existing)

### iTerm Integration

The app launches iTerm2 with:

```swift
process.arguments = ["-a", "iTerm", "--args", scriptPath.path]
```

Key: Uses `-a` (not `-n`) to reuse existing iTerm instance, preventing duplicate Dock icons.

### Build Process

```bash
./app/build-app.sh
```

This script:
1. Compiles Swift source with `swiftc`
2. Creates `.app` bundle structure
3. Copies scripts to `Resources/scripts/`
4. Generates app icon from iconset
5. Signs with ad-hoc signature

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

### App Files

| File | Purpose |
|------|---------|
| `app/clickterm/main.swift` | App entry point, iTerm launcher |
| `app/build-app.sh` | Build script for the app |
| `app/build/clickterm.app` | Built application bundle |

### Script Files

| File | Purpose | When to Modify |
|------|---------|----------------|
| `configs/tmux.conf` | Main tmux configuration | Adding keybinds, settings |
| `dispatch.sh` | Routes button clicks to handlers | Adding new button handlers |
| `split.sh` | Pane splitting with constraints | Changing split behavior/limits |
| `close.sh` | Safe pane closing | Changing close confirmation logic |
| `exit.sh` | Send Ctrl+C to pane | Changing exit behavior |
| `launch.sh` | Tool launcher with busy detection | Adding new tools |
| `help-viewer.sh` | Interactive help popup | Updating help content |
| `theme-switch.sh` | Toggle dark/light themes | Changing theme behavior |
| `tmux-theme-dark.conf` | Dark theme + buttons | Styling, adding buttons |
| `tmux-theme-light.conf` | Light theme + buttons | Styling, adding buttons |
| `install.sh` | Manual installation script | Adding install steps |

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

The Nord palette is used throughout:

| Color | Hex | Usage |
|-------|-----|-------|
| nord0 | `#2e3440` | Dark background |
| nord4 | `#d8dee9` | Light text |
| nord6 | `#eceff4` | Light background |
| nord8 | `#88c0d0` | Accent/cyan |
| nord11 | `#bf616a` | Error/red |
| nord12 | `#d08770` | Warning/orange |
| nord14 | `#a3be8c` | Success/green |

### Theme Files

Two theme files provide dark and light variants:

- `tmux-theme-dark.conf` - Dark mode (default)
- `tmux-theme-light.conf` - Light mode

### Theme Switching

The `theme-switch.sh` script modifies `~/.tmux.conf` to source the appropriate theme file.

## Installation Layouts

### App Bundle (Installed)

```
/Applications/clickterm.app/
└── Contents/
    ├── MacOS/clickterm           # Compiled binary
    ├── Resources/
    │   ├── AppIcon.icns          # App icon
    │   ├── scripts/              # Bundled handler scripts
    │   │   ├── dispatch.sh
    │   │   ├── split.sh
    │   │   └── ...
    │   └── tmux.conf             # Bundled tmux config
    ├── Info.plist
    └── _CodeSignature/
```

### User Config (Auto-installed on first run)

```
~/.config/clickterm/
├── close.sh
├── dispatch.sh
├── exit.sh
├── help-viewer.sh
├── launch.sh
├── split.sh
├── theme-switch.sh
├── theme.json
├── tmux-theme-dark.conf
└── tmux-theme-light.conf

~/.tmux.conf (sources theme from above)
```

## tmux Format Strings

Common format strings used:

| Format | Returns |
|--------|---------|
| `#{pane_current_command}` | Running process name (zsh, vim, etc.) |
| `#{window_panes}` | Number of panes in window |
| `#{pane_at_top}` | 1 if pane is at top edge, 0 otherwise |
| `#{pane_at_bottom}` | 1 if pane is at bottom edge |
| `#{mouse_status_range}` | Button ID from status bar click |

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

## Performance Considerations

1. **Static hex colors** - No runtime computation for colors
2. **Direct script execution** - No intermediate interpreters
3. **Minimal tmux queries** - Only fetch needed variables
4. **No polling** - Event-driven via mouse clicks
5. **Reuses iTerm instance** - No duplicate processes

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
