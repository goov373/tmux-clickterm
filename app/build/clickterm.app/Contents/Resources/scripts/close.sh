#!/bin/bash
# clickterm close.sh - Close pane with last-pane protection and busy confirmation

# Count panes in current window
PANE_COUNT=$(tmux display-message -p '#{window_panes}')

if [ "$PANE_COUNT" = "1" ]; then
    tmux display-message "Can't close last pane"
    exit 0
fi

# Get current pane's running command
CURRENT_CMD=$(tmux display-message -p '#{pane_current_command}')

# Check if pane is busy (not a shell)
if [ "$CURRENT_CMD" != "zsh" ] && [ "$CURRENT_CMD" != "bash" ] && [ "$CURRENT_CMD" != "sh" ]; then
    # Confirm before closing busy pane
    tmux confirm-before -p "Process '$CURRENT_CMD' running. Close? [y/n]" kill-pane
else
    # Close immediately
    tmux kill-pane
fi
