#!/bin/bash
# theme-switch.sh - Switch between Nord dark and light themes
# Usage: ./theme-switch.sh [dark|light|toggle|auto|status]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONF="$HOME/.tmux.conf"
OPENCODE_CONF="$HOME/.config/opencode/opencode.json"

# Detect macOS appearance (dark or light)
get_macos_appearance() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        echo "dark"
    else
        echo "light"
    fi
}

# Detect current mode from tmux.conf
get_current_mode() {
    if grep -q "^source-file.*tmux-theme-light.conf" "$TMUX_CONF" 2>/dev/null; then
        echo "light"
    else
        echo "dark"
    fi
}

# Switch iTerm2 profile using escape sequence
switch_iterm_profile() {
    local profile="$1"
    # iTerm2 proprietary escape sequence to change profile
    # This works for all panes in the current tmux session
    if [ -n "$TMUX" ]; then
        # Send to all tmux panes
        for pane in $(tmux list-panes -a -F '#{pane_id}'); do
            tmux send-keys -t "$pane" -l $'\033]1337;SetProfile='"$profile"$'\007' 2>/dev/null
        done
    else
        # Direct output if not in tmux
        printf '\033]1337;SetProfile=%s\007' "$profile"
    fi
}

# Switch to dark mode
switch_dark() {
    local silent="${1:-false}"
    
    # Update tmux.conf to source dark theme
    if [ -f "$TMUX_CONF" ]; then
        sed -i '' 's|^source-file ~/.config/clickterm/tmux-theme-light.conf|source-file ~/.config/clickterm/tmux-theme-dark.conf|' "$TMUX_CONF"
    fi
    
    # Update OpenCode config
    if [ -f "$OPENCODE_CONF" ] && command -v jq &>/dev/null; then
        jq '.theme = "nord"' "$OPENCODE_CONF" > "$OPENCODE_CONF.tmp" && mv "$OPENCODE_CONF.tmp" "$OPENCODE_CONF"
    fi
    
    # Switch iTerm2 profile
    switch_iterm_profile "Nord"
    
    [ "$silent" != "true" ] && echo "Switched to Nord Dark theme"
}

# Switch to light mode
switch_light() {
    local silent="${1:-false}"
    
    # Update tmux.conf to source light theme
    if [ -f "$TMUX_CONF" ]; then
        sed -i '' 's|^source-file ~/.config/clickterm/tmux-theme-dark.conf|source-file ~/.config/clickterm/tmux-theme-light.conf|' "$TMUX_CONF"
    fi
    
    # Update OpenCode config
    if [ -f "$OPENCODE_CONF" ] && command -v jq &>/dev/null; then
        jq '.theme = "nord-light"' "$OPENCODE_CONF" > "$OPENCODE_CONF.tmp" && mv "$OPENCODE_CONF.tmp" "$OPENCODE_CONF"
    fi
    
    # Switch iTerm2 profile
    switch_iterm_profile "Nord Light"
    
    [ "$silent" != "true" ] && echo "Switched to Nord Light theme"
}

# Reload tmux if in session
reload_tmux() {
    if [ -n "$TMUX" ]; then
        tmux source-file ~/.tmux.conf 2>/dev/null
    fi
}

# Show message in tmux
show_message() {
    local msg="$1"
    if [ -n "$TMUX" ]; then
        tmux display-message "$msg"
    else
        echo "$msg"
    fi
}

# Sync theme to match macOS appearance
sync_to_macos() {
    local silent="${1:-false}"
    local macos_mode
    macos_mode=$(get_macos_appearance)
    local current_mode
    current_mode=$(get_current_mode)
    
    if [ "$macos_mode" != "$current_mode" ]; then
        if [ "$macos_mode" = "dark" ]; then
            switch_dark "$silent"
        else
            switch_light "$silent"
        fi
        reload_tmux
        return 0  # Changed
    fi
    return 1  # No change
}

# Watch for macOS appearance changes and auto-switch
watch_appearance() {
    echo "Watching for macOS appearance changes... (Ctrl+C to stop)"
    echo "Current: $(get_macos_appearance) mode"
    
    local last_mode
    last_mode=$(get_macos_appearance)
    
    while true; do
        sleep 2
        local current_mode
        current_mode=$(get_macos_appearance)
        
        if [ "$current_mode" != "$last_mode" ]; then
            echo "Detected change to $current_mode mode"
            if [ "$current_mode" = "dark" ]; then
                switch_dark true
            else
                switch_light true
            fi
            reload_tmux
            echo "Theme switched to Nord $(echo "$current_mode" | sed 's/./\U&/')"
            last_mode="$current_mode"
        fi
    done
}

# Main
case "${1:-toggle}" in
    dark)
        switch_dark
        reload_tmux
        show_message "Switched to Dark mode (restart OpenCode to apply)"
        ;;
    light)
        switch_light
        reload_tmux
        show_message "Switched to Light mode (restart OpenCode to apply)"
        ;;
    toggle)
        current=$(get_current_mode)
        if [ "$current" = "dark" ]; then
            switch_light
            reload_tmux
            show_message "Switched to Light mode (restart OpenCode to apply)"
        else
            switch_dark
            reload_tmux
            show_message "Switched to Dark mode (restart OpenCode to apply)"
        fi
        ;;
    auto)
        sync_to_macos
        if [ $? -eq 0 ]; then
            echo "Synced to macOS $(get_macos_appearance) mode"
        else
            echo "Already in sync with macOS $(get_macos_appearance) mode"
        fi
        ;;
    watch)
        watch_appearance
        ;;
    status)
        echo "tmux theme:       $(get_current_mode)"
        echo "macOS appearance: $(get_macos_appearance)"
        ;;
    *)
        echo "Usage: $0 [dark|light|toggle|auto|watch|status]"
        echo ""
        echo "Commands:"
        echo "  dark    - Switch to Nord Dark theme"
        echo "  light   - Switch to Nord Light theme"
        echo "  toggle  - Toggle between dark and light"
        echo "  auto    - Sync theme to current macOS appearance"
        echo "  watch   - Watch for macOS changes and auto-switch"
        echo "  status  - Show current theme and macOS mode"
        exit 1
        ;;
esac
