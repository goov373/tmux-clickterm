#!/bin/bash
# clickterm split.sh - Smart split with horizontal limit enforcement
# Usage: split.sh v (vertical/column) or split.sh h (horizontal/stack)

DIRECTION="$1"

if [ "$DIRECTION" = "h" ]; then
    # Horizontal split (stack) - check if already stacked
    PANE_AT_TOP=$(tmux display-message -p '#{pane_at_top}')
    PANE_AT_BOTTOM=$(tmux display-message -p '#{pane_at_bottom}')
    
    if [ "$PANE_AT_TOP" = "0" ] || [ "$PANE_AT_BOTTOM" = "0" ]; then
        # Already in a horizontal stack - reject
        tmux display-message "Column already stacked (max 1 horizontal split)"
        exit 0
    fi
    
    # Allow horizontal split, then launch TUI shell
    tmux split-window -v "~/.config/clickterm/clickterm-shell.sh"
    
elif [ "$DIRECTION" = "v" ]; then
    # Vertical split (new column) - always allowed, then launch TUI shell
    tmux split-window -h "~/.config/clickterm/clickterm-shell.sh"
else
    tmux display-message "Usage: split.sh v|h"
fi
