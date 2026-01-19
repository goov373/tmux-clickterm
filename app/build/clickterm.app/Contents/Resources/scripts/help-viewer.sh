#!/bin/bash
# clickterm help-viewer.sh - Clean help popup with proper input handling

# Save terminal state and disable echo
stty_orig=$(stty -g)
stty -echo -icanon

# Hide cursor
tput civis

# Cleanup function
cleanup() {
    printf '\033[?1000l'  # Disable mouse tracking
    printf '\033[?1006l'  # Disable SGR mouse mode
    tput cnorm            # Show cursor
    stty "$stty_orig"     # Restore terminal
}
trap cleanup EXIT INT TERM

# Clear screen
clear

# Print help content - X on first line, compact layout
cat << 'EOF'
  clickterm · Quick Reference                                    ✕
──────────────────────────────────────────────────────────────────

  Navigation

      Click pane                   Focus (others dim)
      Drag border                  Resize panes

──────────────────────────────────────────────────────────────────

  Pane Actions

      │ Split                      New column
      ─ Stack                      Stack (1 per column)
      × Close                      Close pane
      ⎋ Exit                       Stop tool → shell

──────────────────────────────────────────────────────────────────

  Tools

      opencode                     OpenCode AI
      claude                       Claude Code

──────────────────────────────────────────────────────────────────

  Tip: Enable GPU Rendering in iTerm2 for smooth resizing

                          q  or  ✕  to close
EOF

# Enable mouse tracking for X button
printf '\033[?1000h'
printf '\033[?1006h'

# Input loop - only respond to q, Q, Escape, and mouse on X
while true; do
    char=$(dd bs=1 count=1 2>/dev/null)
    
    case "$char" in
        q|Q)
            exit 0
            ;;
        $'\033')
            # Read rest of escape sequence
            read -rsn5 -t 0.01 rest
            
            # Check for plain Escape (no additional chars)
            if [[ -z "$rest" ]]; then
                exit 0
            fi
            
            # Check for mouse click: ESC [ < btn ; col ; row M
            if [[ "$rest" =~ ^\[?\<([0-9]+)\;([0-9]+)\;([0-9]+) ]]; then
                col="${BASH_REMATCH[2]}"
                row="${BASH_REMATCH[3]}"
                # X button is at row 1, rightmost columns
                if [[ "$row" -le 1 && "$col" -ge 60 ]]; then
                    exit 0
                fi
            fi
            ;;
        *)
            # Ignore all other input - do nothing
            ;;
    esac
done
