# clickterm - AI Development Guide

> This file provides context for AI coding assistants (OpenCode, Claude Code, etc.) working on this project.

## Project Overview

**clickterm** is a mouse-driven tmux development environment with a native macOS app. The core philosophy is: **click buttons instead of memorizing keyboard shortcuts**.

### Target Users
- Developers who prefer GUI-style interactions
- Users new to terminal multiplexers
- Anyone who wants a simpler tmux experience

### Design Principles
1. **Mouse-first** - Every action should be clickable
2. **Discoverable** - Buttons show what's possible
3. **Safe defaults** - Prevent destructive actions (can't close last pane, confirm before killing processes)
4. **Beautiful** - Nord color theme for visual consistency

---

## Architecture

clickterm has two main components:

### 1. Native macOS App (`clickterm.app`)

A Swift application (~115 lines) that:
- Launches iTerm2 with a tmux session
- Auto-installs scripts on first run
- Maintains Dock presence
- Reuses existing iTerm instance (no duplicate icons)

**Key file:** `app/clickterm/main.swift`

### 2. tmux Layer

Shell scripts and configuration that add clickable buttons to tmux's status bar.

### System Flow

```
User clicks status bar button
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ tmux.conf                                                    │
│   bind -n MouseUp1Status run-shell 'dispatch.sh "#{...}"'   │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ dispatch.sh                                                  │
│   Routes button ID to appropriate handler script            │
│   splitv → split.sh v                                       │
│   splith → split.sh h                                       │
│   close  → close.sh                                         │
│   exit   → exit.sh                                          │
│   help   → tmux display-popup (help-viewer.sh)              │
│   opencode/claude → launch.sh <tool>                        │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ Handler Scripts                                              │
│   Each script handles one action with safety checks         │
│   - split.sh: Enforces horizontal split limits              │
│   - close.sh: Protects last pane, confirms busy panes       │
│   - launch.sh: Detects busy panes, offers menu              │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│ tmux Commands                                                │
│   split-window, kill-pane, send-keys, display-message, etc  │
└─────────────────────────────────────────────────────────────┘
```

---

## File Responsibilities

### App Files

| File | Purpose | When to Modify |
|------|---------|----------------|
| `app/clickterm/main.swift` | App entry point, iTerm launcher | Changing app behavior |
| `app/build-app.sh` | Build script | Adding build steps |
| `app/build/clickterm.app` | Built application bundle | Auto-generated |

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
| `theme.json` | Master Nord color palette | Adding colors (reference only) |
| `tmux-theme.conf` | Nord Dark theme + buttons | Styling changes |
| `install.sh` | Manual installation script | Adding install steps |

### Button Definition (in tmux theme files)

Buttons are defined in `status-right` using tmux's `#[range=user|<id>]` syntax:

```tmux
set -g status-right "\
#[range=user|help]#[fg=#88c0d0] [ ? ] #[norange]\
#[range=user|opencode]#[fg=#eceff4,bold] [ opencode ] #[norange]"
```

The `<id>` (e.g., `help`, `opencode`) is passed to `dispatch.sh` when clicked.

---

## Coding Conventions

### Bash Scripts

```bash
#!/bin/bash
# clickterm <script>.sh - Brief description
# Usage: <script>.sh [args]

set -e  # Only if script should fail-fast

# Use functions for reusable logic
do_something() {
    local arg="$1"
    # ...
}

# Main logic at bottom
main() {
    # ...
}

main "$@"
```

**Style rules:**
- Use `$()` for command substitution, not backticks
- Quote all variables: `"$VAR"` not `$VAR`
- Use `[[` for conditionals in bash, `[` only for POSIX compatibility
- Add comments for non-obvious tmux commands
- Exit codes: 0 = success, 1 = error, no exit = continue

### Swift Code

```swift
// Keep main.swift minimal and focused
// Extract complex logic into separate methods
// Use guard for early returns
// Handle errors gracefully with user feedback
```

### tmux Commands (Common Patterns)

```bash
# Get tmux variable
VALUE=$(tmux display-message -p '#{pane_current_command}')

# Show user message (bottom status area)
tmux display-message "Your message here"

# Run command in pane
tmux send-keys "command" Enter

# Split pane
tmux split-window -h  # vertical split (side by side)
tmux split-window -v  # horizontal split (stacked)

# Show popup
tmux display-popup -E "command"

# Show menu
tmux display-menu -T "Title" \
    "Option 1" "key" "command1" \
    "Option 2" "key" "command2"

# Confirm before action
tmux confirm-before -p "Are you sure? [y/n]" "command"
```

### Theme Colors (Nord Dark Palette)

When adding UI elements, use these color references:

| Purpose | Color |
|---------|-------|
| Background | `#2e3440` (nord0) |
| Text | `#d8dee9` (nord4) |
| Accent | `#88c0d0` (nord8) |
| Error/Close | `#bf616a` (nord11) |
| Warning/Exit | `#d08770` (nord12) |
| Success | `#a3be8c` (nord14) |

---

## How to Add a New Button

### Step 1: Choose an ID
Pick a short, descriptive ID (e.g., `settings`, `newwin`, `layout`).

### Step 2: Add to Theme File
Edit `tmux-theme.conf`:

```tmux
# In status-right, add your button:
#[range=user|mybutton]#[fg=#d8dee9] [ My Button ] #[norange]
```

### Step 3: Add Handler to dispatch.sh

```bash
case "$BUTTON" in
    # ... existing cases ...
    mybutton)
        ~/.config/clickterm/mybutton.sh
        ;;
esac
```

### Step 4: Create Handler Script

```bash
#!/bin/bash
# clickterm mybutton.sh - Description of what it does

# Your logic here
tmux display-message "Button clicked!"
```

### Step 5: Update install.sh
Add your new script to the install process.

### Step 6: Rebuild App (if needed)
```bash
./app/build-app.sh
cp -r app/build/clickterm.app /Applications/
```

### Step 7: Test
```bash
make dev  # Install and reload
# Click your button
```

---

## How to Add a New Tool Launcher

To add a new AI tool or CLI program to the launcher buttons:

### Step 1: Add Button (same as above)
Add to theme file with ID like `mytool`.

### Step 2: Update dispatch.sh

```bash
mytool)
    ~/.config/clickterm/launch.sh mytool
    ;;
```

### Step 3: That's it!
`launch.sh` handles busy-pane detection automatically. It will:
- Launch directly if pane is free (showing shell)
- Show a menu if pane is busy (running a process)

---

## Testing Checklist

Before committing changes:

- [ ] `make lint` passes (shellcheck)
- [ ] `make install` works
- [ ] `make reload` applies changes
- [ ] Test each affected button
- [ ] Test edge cases (last pane, busy pane, etc.)
- [ ] If app changed: rebuild and test from /Applications

---

## Development Workflow

```bash
# Setup (first time)
git clone https://github.com/goov373/tmux-clickterm.git
cd tmux-clickterm
make install

# Development cycle for scripts
# 1. Edit files
# 2. Run: make dev    (install + reload)
# 3. Test in tmux
# 4. Repeat

# Development cycle for app
# 1. Edit app/clickterm/main.swift
# 2. Run: ./app/build-app.sh
# 3. Run: cp -r app/build/clickterm.app /Applications/
# 4. Test by launching from Dock
# 5. Repeat

# Before committing
make lint
git add -A
git commit -m "Description of changes"
git push
```

---

## Project Structure

```
tmux-clickterm/
├── app/
│   ├── clickterm/
│   │   └── main.swift          # Native macOS app source
│   ├── build/
│   │   └── clickterm.app/      # Built application bundle
│   └── build-app.sh            # Build script
├── assets/
│   ├── Logos/                  # Logo source files
│   └── clickterm.iconset/      # App icon set
├── configs/
│   ├── tmux.conf               # Main tmux configuration
│   └── iterm2/Nord.json        # iTerm2 color profile
├── docs/
│   ├── ARCHITECTURE.md         # Technical deep-dive
│   ├── EXTENDING.md            # How to add features
│   └── PERSISTENT-WRAPPER.md   # Future enhancement notes
├── *.sh                        # Handler scripts
├── tmux-theme.conf             # Nord Dark theme + button definitions
├── theme.json                  # Nord color palette reference
├── install.sh                  # Manual installation script
├── Makefile                    # Development commands
├── AGENTS.md                   # This file (AI assistant guide)
├── CLAUDE.md                   # Short reference for Claude
└── README.md                   # User documentation
```

---

## Future Roadmap

### Planned Features

1. **Session Management**
   - Save current layout to named session
   - Restore saved sessions
   - Session picker popup

2. **Workspace Support**
   - Project-based configurations
   - Auto-load workspace on directory entry
   - Per-project button customization

3. **Dynamic Button Config**
   - JSON-based button definitions
   - User-customizable buttons without editing scripts
   - Button visibility conditions

4. **Status Indicators**
   - Git branch/status in status bar
   - Current directory display
   - Process status indicators

### Technical Debt

- [ ] `help.txt` is unused (content is in help-viewer.sh)

---

## Quick Reference

### Make Targets
```
make install      # Install scripts to ~/.config/clickterm
make reload       # Reload tmux configuration  
make dev          # Install + reload
make lint         # Run shellcheck on all scripts
make clean        # Remove installed files
```

### Key Files to Read First
1. `app/clickterm/main.swift` - Understand the app
2. `dispatch.sh` - Understand button routing
3. `configs/tmux.conf` - See tmux configuration
4. `tmux-theme.conf` - See status bar styling

### Getting Help
- Click `[ ? ]` in tmux for quick reference
- Read `docs/ARCHITECTURE.md` for deep dive
- Read `docs/EXTENDING.md` for feature guides
