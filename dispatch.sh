#!/bin/bash
# clickterm dispatch.sh - Handle status bar button clicks
# Usage: dispatch.sh <button_id>

BUTTON="$1"

case "$BUTTON" in
    splitv)
        ~/.config/clickterm/split.sh v
        ;;
    splith)
        ~/.config/clickterm/split.sh h
        ;;
    close)
        ~/.config/clickterm/close.sh
        ;;
    exit)
        ~/.config/clickterm/exit.sh
        ;;
    help)
        tmux display-popup -b rounded -w 72 -h 30 -E "~/.config/clickterm/help-viewer.sh"
        ;;
    opencode)
        ~/.config/clickterm/launch.sh opencode
        ;;
    claude)
        ~/.config/clickterm/launch.sh claude
        ;;
    theme)
        ~/.config/clickterm/theme-switch.sh toggle
        ;;
    *)
        # Unknown button or empty - do nothing
        ;;
esac
