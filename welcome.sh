#!/bin/bash
# clickterm welcome.sh - Display centered ASCII logo on startup
# Usage: welcome.sh

# Nord color palette
NORD3="\033[38;2;76;86;106m"     # Muted/comments
NORD4="\033[38;2;216;222;233m"   # Primary text
NORD8="\033[38;2;136;192;208m"   # Frost cyan (accent)
NORD11="\033[38;2;191;97;106m"   # Aurora red
NORD12="\033[38;2;208;135;112m"  # Aurora orange
NORD14="\033[38;2;163;190;140m"  # Aurora green
RESET="\033[0m"
BOLD="\033[1m"

# Get terminal dimensions
COLS=$(tput cols)
LINES=$(tput lines)

# ASCII art logo
read -r -d '' LOGO << 'EOF'
      _ _      _    _                      
  ___| (_) ___| | _| |_ ___ _ __ _ __ ___  
 / __| | |/ __| |/ / __/ _ \ '__| '_ ` _ \ 
| (__| | | (__|   <| ||  __/ |  | | | | | |
 \___|_|_|\___|_|\_\\__\___|_|  |_| |_| |_|
EOF

# Compact logo for narrow terminals
read -r -d '' LOGO_SMALL << 'EOF'
 ┌─┐┬  ┬┌─┐┬┌─┌┬┐┌─┐┬─┐┌┬┐
 │  │  ││  ├┴┐ │ ├┤ ├┬┘│││
 └─┘┴─┘┴└─┘┴ ┴ ┴ └─┘┴└─┴ ┴
EOF

# Choose logo based on terminal width
if [[ $COLS -ge 50 ]]; then
    DISPLAY_LOGO="$LOGO"
    LOGO_WIDTH=46
else
    DISPLAY_LOGO="$LOGO_SMALL"
    LOGO_WIDTH=29
fi

# Content width for tips section (width of separator line)
CONTENT_WIDTH=56

# Calculate centering
LOGO_PAD=$(( (COLS - LOGO_WIDTH) / 2 ))
CONTENT_PAD=$(( (COLS - CONTENT_WIDTH) / 2 ))
[[ $LOGO_PAD -lt 0 ]] && LOGO_PAD=0
[[ $CONTENT_PAD -lt 0 ]] && CONTENT_PAD=0

# Padding strings
LPAD=$(printf '%*s' "$LOGO_PAD" '')
CPAD=$(printf '%*s' "$CONTENT_PAD" '')

# Calculate vertical centering
TOTAL_CONTENT_LINES=24
VERTICAL_PAD=$(( (LINES - TOTAL_CONTENT_LINES) / 3 ))
[[ $VERTICAL_PAD -lt 1 ]] && VERTICAL_PAD=1

# Helper: print centered text with color
center() {
    local text="$1"
    local color="${2:-}"
    local width=${#text}
    local pad=$(( (COLS - width) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%*s' "$pad" ''
    if [[ -n "$color" ]]; then
        echo -e "${color}${text}${RESET}"
    else
        echo "$text"
    fi
}

# Clear screen and hide cursor
clear
tput civis

# Vertical padding
for ((i=0; i<VERTICAL_PAD; i++)); do echo ""; done

# Logo
echo "$DISPLAY_LOGO" | while IFS= read -r line; do
    echo -e "${LPAD}${NORD8}${BOLD}${line}${RESET}"
done

# Tagline
echo ""
center "mouse-driven tmux environment" "$NORD3"

# Separator
echo ""
echo -e "${CPAD}${NORD3}────────────────────────────────────────────────────────${RESET}"

# Section: Pane Management
echo ""
echo -e "${CPAD}  ${NORD4}${BOLD}Pane Management${RESET}"
echo ""
echo -e "${CPAD}  ${NORD4}[ │ Split ]${RESET}    ${NORD3}Create a new pane to the right${RESET}"
echo -e "${CPAD}  ${NORD4}[ ─ Stack ]${RESET}    ${NORD3}Create a new pane below${RESET}"
echo -e "${CPAD}  ${NORD11}[ × Close ]${RESET}    ${NORD3}Close the current pane${RESET}"
echo -e "${CPAD}  ${NORD12}[ ⎋ Exit  ]${RESET}    ${NORD3}Send Ctrl+C to stop running process${RESET}"

# Section: Tools
echo ""
echo -e "${CPAD}  ${NORD4}${BOLD}AI Tools${RESET}"
echo ""
echo -e "${CPAD}  ${NORD8}[ opencode ]${RESET}    ${NORD3}Launch OpenCode in current pane${RESET}"
echo -e "${CPAD}  ${NORD8}[ claude   ]${RESET}    ${NORD3}Launch Claude Code in current pane${RESET}"

# Section: Help
echo ""
echo -e "${CPAD}  ${NORD4}${BOLD}Help${RESET}"
echo ""
echo -e "${CPAD}  ${NORD14}[ ?        ]${RESET}    ${NORD3}Open quick reference popup${RESET}"

# Separator
echo ""
echo -e "${CPAD}${NORD3}────────────────────────────────────────────────────────${RESET}"

# Footer hint
echo ""
center "click any button in the status bar below to get started" "$NORD3"

# Show cursor
echo ""
tput cnorm

# Brief pause
sleep 0.5
