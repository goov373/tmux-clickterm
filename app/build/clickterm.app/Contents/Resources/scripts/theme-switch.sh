#!/bin/bash
# theme-switch.sh - Switch between Nord dark and light themes
# Usage: ./theme-switch.sh [dark|light|toggle]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONF="$HOME/.tmux.conf"
OPENCODE_CONF="$HOME/.config/opencode/opencode.json"

# Detect current mode from tmux.conf
get_current_mode() {
    if grep -q "^source-file.*tmux-theme-light.conf" "$TMUX_CONF" 2>/dev/null; then
        echo "light"
    else
        echo "dark"
    fi
}

# Switch to dark mode
switch_dark() {
    # Update tmux.conf
    sed -i '' 's|^source-file.*tmux-theme-light.conf|source-file ~/.config/clickterm/tmux-theme-dark.conf|' "$TMUX_CONF"
    sed -i '' 's|^# source-file.*tmux-theme-dark.conf|source-file ~/.config/clickterm/tmux-theme-dark.conf|' "$TMUX_CONF"
    sed -i '' 's|^source-file.*tmux-theme-dark.conf|source-file ~/.config/clickterm/tmux-theme-dark.conf\n# source-file ~/.config/clickterm/tmux-theme-light.conf|' "$TMUX_CONF" 2>/dev/null || true
    
    # Update OpenCode config
    if [ -f "$OPENCODE_CONF" ]; then
        if command -v jq &> /dev/null; then
            jq '.theme = "nord"' "$OPENCODE_CONF" > "$OPENCODE_CONF.tmp" && mv "$OPENCODE_CONF.tmp" "$OPENCODE_CONF"
        fi
    fi
    
    echo "Switched to Nord Dark theme"
}

# Switch to light mode
switch_light() {
    # Update tmux.conf
    sed -i '' 's|^source-file.*tmux-theme-dark.conf|# source-file ~/.config/clickterm/tmux-theme-dark.conf|' "$TMUX_CONF"
    sed -i '' 's|^# source-file.*tmux-theme-light.conf|source-file ~/.config/clickterm/tmux-theme-light.conf|' "$TMUX_CONF"
    
    # Update OpenCode config
    if [ -f "$OPENCODE_CONF" ]; then
        if command -v jq &> /dev/null; then
            jq '.theme = "nord-light"' "$OPENCODE_CONF" > "$OPENCODE_CONF.tmp" && mv "$OPENCODE_CONF.tmp" "$OPENCODE_CONF"
        fi
    fi
    
    echo "Switched to Nord Light theme"
}

# Reload tmux if in session
reload_tmux() {
    if [ -n "$TMUX" ]; then
        tmux source-file ~/.tmux.conf
        echo "tmux configuration reloaded"
    fi
}

# Main
case "${1:-toggle}" in
    dark)
        switch_dark
        reload_tmux
        ;;
    light)
        switch_light
        reload_tmux
        ;;
    toggle)
        current=$(get_current_mode)
        if [ "$current" = "dark" ]; then
            switch_light
        else
            switch_dark
        fi
        reload_tmux
        ;;
    status)
        echo "Current mode: $(get_current_mode)"
        ;;
    *)
        echo "Usage: $0 [dark|light|toggle|status]"
        exit 1
        ;;
esac

echo ""
echo "Note: Restart OpenCode and switch iTerm2 profile to see full changes"
