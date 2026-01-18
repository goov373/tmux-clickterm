# Extending clickterm

Step-by-step guides for adding features to clickterm.

## Table of Contents

1. [Adding a New Button](#adding-a-new-button)
2. [Adding a New Tool Launcher](#adding-a-new-tool-launcher)
3. [Creating a Popup Dialog](#creating-a-popup-dialog)
4. [Adding a New Color Theme](#adding-a-new-color-theme)
5. [Adding Session Management](#adding-session-management)

---

## Adding a New Button

This example adds a "New Window" button.

### Step 1: Choose Your Button

Decide on:
- **ID**: `newwin` (used internally)
- **Label**: `[ + New ]` (shown to user)
- **Position**: Right side, before tools

### Step 2: Add to Theme Files

Edit `tmux-theme-dark.conf`:

```tmux
# Find status-right and add your button
set -g status-right "\
#[fg=#4c566a]│\
#[bg=#3b4252,fg=#d8dee9] [ │ Split ] \
...existing buttons...
#[range=user|newwin]#[bg=#3b4252,fg=#a3be8c] [ + New ] #[norange]\
#[fg=#4c566a]│\
...tools..."
```

Do the same for `tmux-theme-light.conf`.

### Step 3: Add Handler to dispatch.sh

```bash
case "$BUTTON" in
    # ... existing cases ...
    newwin)
        tmux new-window
        ;;
    # ... rest of cases ...
esac
```

For simple actions like this, you can put the command directly in dispatch.sh.

### Step 4: Test

```bash
make dev
# Click your new button
```

---

## Adding a New Tool Launcher

This example adds support for launching `lazygit`.

### Step 1: Add Button to Theme Files

In both `tmux-theme-dark.conf` and `tmux-theme-light.conf`:

```tmux
#[range=user|lazygit]#[bg=#5e81ac,fg=#eceff4,bold] [ lazygit ] #[norange]
```

### Step 2: Add to dispatch.sh

```bash
lazygit)
    ~/.config/clickterm/launch.sh lazygit
    ;;
```

### Step 3: That's It!

The existing `launch.sh` handles:
- Launching directly if pane is free
- Showing a menu if pane is busy
- The tool name is passed as the command

### Step 4: Test

```bash
make dev
# Click [ lazygit ]
```

---

## Creating a Popup Dialog

This example creates a session picker popup.

### Step 1: Create the Viewer Script

Create `session-picker.sh`:

```bash
#!/bin/bash
# clickterm session-picker.sh - Interactive session picker

# Save terminal state
stty_orig=$(stty -g)
stty -echo -icanon
tput civis

cleanup() {
    tput cnorm
    stty "$stty_orig"
}
trap cleanup EXIT

clear

echo "  Select Session"
echo "  ─────────────────────────────"
echo ""

# Get sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)
i=1
declare -a session_arr

while IFS= read -r session; do
    echo "    $i) $session"
    session_arr+=("$session")
    ((i++))
done <<< "$sessions"

echo ""
echo "  Press number to switch, q to cancel"

# Read input
while true; do
    read -rsn1 char
    case "$char" in
        [1-9])
            idx=$((char - 1))
            if [ $idx -lt ${#session_arr[@]} ]; then
                tmux switch-client -t "${session_arr[$idx]}"
                exit 0
            fi
            ;;
        q|Q)
            exit 0
            ;;
    esac
done
```

### Step 2: Make Executable

```bash
chmod +x session-picker.sh
```

### Step 3: Add Button and Handler

In theme files:
```tmux
#[range=user|sessions]#[fg=#88c0d0] [ Sessions ] #[norange]
```

In dispatch.sh:
```bash
sessions)
    tmux display-popup -b rounded -w 40 -h 15 -E "~/.config/clickterm/session-picker.sh"
    ;;
```

---

## Adding a New Color Theme

This example creates a "Dracula" theme variant.

### Step 1: Create Theme File

Create `tmux-theme-dracula.conf`:

```tmux
# ═══════════════════════════════════════════════════════════════
# clickterm - Dracula Theme
# ═══════════════════════════════════════════════════════════════

# Dracula colors
# Background: #282a36
# Foreground: #f8f8f2
# Comment:    #6272a4
# Cyan:       #8be9fd
# Green:      #50fa7b
# Orange:     #ffb86c
# Pink:       #ff79c6
# Purple:     #bd93f9
# Red:        #ff5555
# Yellow:     #f1fa8c

# Pane borders
set -g pane-border-style "fg=#6272a4"
set -g pane-active-border-style "fg=#bd93f9"

# Status bar
set -g status-style "bg=#44475a,fg=#f8f8f2"
set -g status-position bottom

# ... continue with button definitions using Dracula colors ...
```

### Step 2: Update theme-switch.sh

Add Dracula support:

```bash
switch_dracula() {
    sed -i '' 's|^source-file.*tmux-theme-.*\.conf|source-file ~/.config/clickterm/tmux-theme-dracula.conf|' ~/.tmux.conf
    echo "Switched to Dracula theme"
}

case "${1:-toggle}" in
    dracula)
        switch_dracula
        reload_tmux
        ;;
    # ... existing cases ...
esac
```

### Step 3: Create OpenCode Theme (Optional)

Create `configs/opencode/themes/dracula.json` following the OpenCode theme format.

---

## Adding Session Management

This is a more complex feature. Here's the architecture:

### Feature: Save/Restore Layouts

#### Step 1: Create Layout Storage

Create `layouts/` directory and `layout-manager.sh`:

```bash
#!/bin/bash
# layout-manager.sh - Save and restore window layouts

LAYOUT_DIR="$HOME/.config/clickterm/layouts"
mkdir -p "$LAYOUT_DIR"

save_layout() {
    local name="$1"
    local layout_file="$LAYOUT_DIR/$name.layout"
    
    # Save window layout
    tmux list-windows -F "#{window_layout}" > "$layout_file"
    
    # Save pane commands (what's running)
    tmux list-panes -F "#{pane_current_command}" >> "$layout_file"
    
    echo "Layout saved: $name"
}

restore_layout() {
    local name="$1"
    local layout_file="$LAYOUT_DIR/$name.layout"
    
    if [ ! -f "$layout_file" ]; then
        echo "Layout not found: $name"
        return 1
    fi
    
    # Read and apply layout
    local layout
    layout=$(head -1 "$layout_file")
    tmux select-layout "$layout"
    
    echo "Layout restored: $name"
}

list_layouts() {
    ls -1 "$LAYOUT_DIR"/*.layout 2>/dev/null | xargs -I {} basename {} .layout
}

case "$1" in
    save)   save_layout "$2" ;;
    restore) restore_layout "$2" ;;
    list)   list_layouts ;;
    *)      echo "Usage: layout-manager.sh [save|restore|list] [name]" ;;
esac
```

#### Step 2: Create Layout Picker UI

Create a popup that:
1. Lists saved layouts
2. Allows selection with number keys
3. Has option to save current layout

#### Step 3: Add Buttons

```tmux
#[range=user|layout-save] [ Save ] #[norange]
#[range=user|layout-load] [ Load ] #[norange]
```

#### Step 4: Wire Up Dispatch

```bash
layout-save)
    # Prompt for name and save
    tmux command-prompt -p "Layout name:" "run-shell '~/.config/clickterm/layout-manager.sh save %%'"
    ;;
layout-load)
    tmux display-popup -E "~/.config/clickterm/layout-picker.sh"
    ;;
```

---

## Best Practices

### Error Handling

Always provide feedback to the user:

```bash
if some_condition; then
    tmux display-message "Action completed"
else
    tmux display-message "Error: reason here"
fi
```

### Safety Checks

Before destructive actions:

```bash
# Confirm before closing
tmux confirm-before -p "Close this pane? [y/n]" kill-pane

# Or use display-menu for options
tmux display-menu -T "Confirm" \
    "Yes, close" "y" "kill-pane" \
    "Cancel" "c" ""
```

### Testing

1. Test in fresh tmux session
2. Test with multiple panes
3. Test with busy panes (running processes)
4. Test both dark and light themes
5. Run `make lint` before committing

### Documentation

When adding features:
1. Update `AGENTS.md` with new file responsibilities
2. Add comments in scripts explaining non-obvious logic
3. Update help content if adding user-facing features
