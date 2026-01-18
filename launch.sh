#!/bin/bash
# clickterm launch.sh - Launch tool with busy-pane detection
# Usage: launch.sh opencode|claude

TOOL="$1"

if [ -z "$TOOL" ]; then
    tmux display-message "Usage: launch.sh opencode|claude"
    exit 1
fi

# Get current pane's running command
CURRENT_CMD=$(tmux display-message -p '#{pane_current_command}')

# Check if pane is busy (not a shell)
if [ "$CURRENT_CMD" != "zsh" ] && [ "$CURRENT_CMD" != "bash" ] && [ "$CURRENT_CMD" != "sh" ]; then
    # Pane is busy - show menu
    tmux display-menu -T "Pane Busy: $CURRENT_CMD" \
        "Stop & Launch $TOOL" "s" "send-keys C-c ; run-shell 'sleep 0.3' ; send-keys '$TOOL' Enter" \
        "Open in New Pane" "n" "split-window -h '$TOOL'" \
        "" \
        "Cancel" "c" ""
else
    # Pane is free - launch directly
    tmux send-keys "$TOOL" Enter
fi
