#!/bin/bash
# clickterm-shell.sh - TUI wrapper with OpenCode-style centered layout
# Provides a clean, centered welcome screen with integrated command input

# Nord color palette
NORD3="\033[38;2;76;86;106m"      # Muted/comments
NORD4="\033[38;2;216;222;233m"    # Primary text
NORD8="\033[38;2;136;192;208m"    # Frost cyan (accent)
RESET="\033[0m"
BOLD="\033[1m"

# Background colors
BG_NORD1="\033[48;2;59;66;82m"    # Input box background

# Interactive commands that need full terminal control
INTERACTIVE_CMDS="vim nvim vi nano emacs less more man top htop opencode claude ssh fzf tmux"

# Check if command is interactive
is_interactive() {
    local cmd="$1"
    local base_cmd=$(echo "$cmd" | awk '{print $1}')
    for ic in $INTERACTIVE_CMDS; do
        [[ "$base_cmd" == "$ic" ]] && return 0
    done
    return 1
}

# Get terminal dimensions
get_dimensions() {
    COLS=$(tput cols)
    LINES=$(tput lines)
}

# ASCII art logo
LOGO='      _ _      _    _                      
  ___| (_) ___| | _| |_ ___ _ __ _ __ ___  
 / __| | |/ __| |/ / __/ _ \'"'"'__| '"'"'_ ` _ \ 
| (__| | | (__|   <| ||  __/ |  | | | | | |
 \___|_|_|\___|_|\_\\__\___|_|  |_| |_| |_|'

LOGO_WIDTH=46
INPUT_BOX_WIDTH=56
INPUT_BOX_INNER=$((INPUT_BOX_WIDTH - 2))

# Center a line of text (provide visible length for ANSI strings)
center_text() {
    local text="$1"
    local visible_len="$2"
    local pad=$(( (COLS - visible_len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%*s' "$pad" ''
    echo -e "$text"
}

# Draw the welcome screen
draw_welcome() {
    get_dimensions
    clear
    
    # Total content height:
    # - Logo: 5 lines
    # - Blank + tagline: 2 lines
    # - Blank x2 + input box (3 lines) + blank: 6 lines  
    # - Tips: 2 lines
    # Total: ~15 lines
    local TOTAL_CONTENT_LINES=15
    local VERTICAL_PAD=$(( (LINES - TOTAL_CONTENT_LINES) / 2 ))
    [[ $VERTICAL_PAD -lt 1 ]] && VERTICAL_PAD=1
    
    # Vertical padding (top)
    for ((i=0; i<VERTICAL_PAD; i++)); do echo; done
    
    # Logo - centered line by line
    while IFS= read -r line; do
        center_text "${NORD8}${BOLD}${line}${RESET}" ${#line}
    done <<< "$LOGO"
    
    # Blank line
    echo
    
    # Tagline - centered
    local TAGLINE="mouse-driven tmux environment"
    center_text "${NORD3}${TAGLINE}${RESET}" ${#TAGLINE}
    
    # Blank lines before input box
    echo
    echo
}

# Draw the input box and position cursor for input
draw_input_box() {
    get_dimensions
    
    local INPUT_PAD=$(( (COLS - INPUT_BOX_WIDTH) / 2 ))
    [[ $INPUT_PAD -lt 0 ]] && INPUT_PAD=0
    local IPAD=$(printf '%*s' "$INPUT_PAD" '')
    
    # Top border
    local TOP_BORDER=$(printf '─%.0s' $(seq 1 $INPUT_BOX_INNER))
    echo -e "${IPAD}${NORD3}┌${TOP_BORDER}┐${RESET}"
    
    # Input line with prompt
    local PROMPT_TEXT=" \$ "
    local PROMPT_LEN=3
    local REMAINING_SPACE=$((INPUT_BOX_INNER - PROMPT_LEN))
    local INNER_SPACES=$(printf '%*s' "$REMAINING_SPACE" '')
    
    echo -en "${IPAD}${NORD3}│${RESET}${BG_NORD1}${NORD8}${PROMPT_TEXT}${RESET}${BG_NORD1}"
    
    # Save cursor position for input
    tput sc
    
    # Fill rest with background and close border
    echo -e "${INNER_SPACES}${RESET}${NORD3}│${RESET}"
    
    # Bottom border
    echo -e "${IPAD}${NORD3}└${TOP_BORDER}┘${RESET}"
    
    # Move cursor back to input position
    tput rc
}

# Draw tips below input box
draw_tips() {
    get_dimensions
    
    echo
    
    # Tip line
    local TIP_TEXT="Tip: Click status bar buttons to manage panes and launch AI tools"
    if [[ ${#TIP_TEXT} -gt $((COLS - 4)) ]]; then
        TIP_TEXT="Tip: Click status bar buttons to get started"
    fi
    center_text "${NORD3}${TIP_TEXT}${RESET}" ${#TIP_TEXT}
    
    # Keyboard hints
    local HINTS="ctrl+c exit    [ ? ] help    [ opencode ] [ claude ]"
    center_text "${NORD3}${HINTS}${RESET}" ${#HINTS}
}

# Read command with cursor inside the box
read_command() {
    local input=""
    read -e -r input
    echo "$input"
}

# Handle window resize
handle_resize() {
    draw_welcome
    draw_input_box
    draw_tips
    # Reposition cursor in input box
    get_dimensions
    local INPUT_PAD=$(( (COLS - INPUT_BOX_WIDTH) / 2 ))
    [[ $INPUT_PAD -lt 0 ]] && INPUT_PAD=0
    # Move cursor to the input line (VERTICAL_PAD + logo lines + tagline + blanks + 1 for border + 1 for input row)
    local TOTAL_CONTENT_LINES=15
    local VERTICAL_PAD=$(( (LINES - TOTAL_CONTENT_LINES) / 2 ))
    [[ $VERTICAL_PAD -lt 1 ]] && VERTICAL_PAD=1
    local INPUT_ROW=$((VERTICAL_PAD + 5 + 2 + 2 + 2))  # after logo, tagline, blanks, top border
    tput cup $INPUT_ROW $((INPUT_PAD + 4))
}

# Set up signal handlers
trap 'handle_resize' WINCH
trap 'echo ""; exit 0' INT

# Main loop
main() {
    # Initialize history
    HISTFILE=~/.clickterm_history
    HISTSIZE=1000
    history -r 2>/dev/null
    
    while true; do
        draw_welcome
        draw_input_box
        draw_tips
        
        # Reposition cursor inside input box
        get_dimensions
        local INPUT_PAD=$(( (COLS - INPUT_BOX_WIDTH) / 2 ))
        [[ $INPUT_PAD -lt 0 ]] && INPUT_PAD=0
        local TOTAL_CONTENT_LINES=15
        local VERTICAL_PAD=$(( (LINES - TOTAL_CONTENT_LINES) / 2 ))
        [[ $VERTICAL_PAD -lt 1 ]] && VERTICAL_PAD=1
        # Row: vertical pad + 5 (logo) + 1 (blank) + 1 (tagline) + 2 (blanks) + 1 (top border) + 1 (input line)
        local INPUT_ROW=$((VERTICAL_PAD + 5 + 1 + 1 + 2 + 1))
        tput cup $INPUT_ROW $((INPUT_PAD + 5))
        
        # Read command
        cmd=$(read_command)
        
        # Save to history
        [[ -n "$cmd" ]] && history -s "$cmd" 2>/dev/null
        
        # Handle empty input
        [[ -z "$cmd" ]] && continue
        
        # Handle exit
        if [[ "$cmd" == "exit" || "$cmd" == "quit" ]]; then
            history -w 2>/dev/null
            clear
            exit 0
        fi
        
        # Handle clear
        if [[ "$cmd" == "clear" ]]; then
            continue
        fi
        
        # Execute command
        clear
        
        if is_interactive "$cmd"; then
            # Run interactive commands directly
            eval "$cmd"
        else
            # Run non-interactive commands and show output
            echo -e "${NORD3}$ ${NORD4}${cmd}${RESET}"
            echo ""
            eval "$cmd"
            echo ""
            echo -e "${NORD3}Press Enter to continue...${RESET}"
            read -r
        fi
    done
}

# Run
main
