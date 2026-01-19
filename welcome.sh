#!/bin/bash
# clickterm welcome.sh - Display centered welcome screen (OpenCode-style)
# Usage: welcome.sh

# Nord color palette
NORD3="\033[38;2;76;86;106m"      # Muted/comments
NORD4="\033[38;2;216;222;233m"    # Primary text
NORD8="\033[38;2;136;192;208m"    # Frost cyan (accent)
RESET="\033[0m"
BOLD="\033[1m"

# Background colors
BG_NORD1="\033[48;2;59;66;82m"    # Input box background

# Get terminal dimensions
COLS=$(tput cols)
LINES=$(tput lines)

# ASCII art logo (compact version that looks clean)
read -r -d '' LOGO << 'EOF'
      _ _      _    _                      
  ___| (_) ___| | _| |_ ___ _ __ _ __ ___  
 / __| | |/ __| |/ / __/ _ \ '__| '_ ` _ \ 
| (__| | | (__|   <| ||  __/ |  | | | | | |
 \___|_|_|\___|_|\_\\__\___|_|  |_| |_| |_|
EOF

# Calculate logo width
LOGO_WIDTH=46

# Content block dimensions
CONTENT_WIDTH=60
INPUT_BOX_WIDTH=56

# Calculate number of content lines (for vertical centering)
# Logo: 5 lines + blank + tagline + 2 blanks + input box (3) + blank + tips (2) = ~14 lines
TOTAL_CONTENT_LINES=14

# Calculate vertical padding to center the whole block
VERTICAL_PAD=$(( (LINES - TOTAL_CONTENT_LINES) / 2 ))
[[ $VERTICAL_PAD -lt 1 ]] && VERTICAL_PAD=1

# Helper: center a line of text
center_text() {
    local text="$1"
    local visible_len="$2"  # Length without ANSI codes
    local pad=$(( (COLS - visible_len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%*s' "$pad" ''
    echo -e "$text"
}

# Helper: center a raw line (calculate length from text itself)
center_raw() {
    local text="$1"
    local len=${#text}
    local pad=$(( (COLS - len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf '%*s%s\n' "$pad" '' "$text"
}

# Clear screen and hide cursor during drawing
clear
tput civis

# Vertical padding (top)
for ((i=0; i<VERTICAL_PAD; i++)); do echo; done

# Logo - centered
while IFS= read -r line; do
    center_text "${NORD8}${BOLD}${line}${RESET}" ${#line}
done <<< "$LOGO"

# Blank line
echo

# Tagline - centered
TAGLINE="mouse-driven tmux environment"
center_text "${NORD3}${TAGLINE}${RESET}" ${#TAGLINE}

# Two blank lines before input box
echo
echo

# Input box - centered with border
INPUT_INNER=$((INPUT_BOX_WIDTH - 2))
INPUT_PAD=$(( (COLS - INPUT_BOX_WIDTH) / 2 ))
[[ $INPUT_PAD -lt 0 ]] && INPUT_PAD=0
IPAD=$(printf '%*s' "$INPUT_PAD" '')

# Top border
TOP_BORDER="$(printf '─%.0s' $(seq 1 $INPUT_INNER))"
echo -e "${IPAD}${NORD3}┌${TOP_BORDER}┐${RESET}"

# Input area (with background)
INNER_SPACES=$(printf '%*s' "$INPUT_INNER" '')
echo -e "${IPAD}${NORD3}│${RESET}${BG_NORD1}${INNER_SPACES}${RESET}${NORD3}│${RESET}"

# Bottom border
echo -e "${IPAD}${NORD3}└${TOP_BORDER}┘${RESET}"

# Blank line
echo

# Tips line - centered (mimicking OpenCode's style)
TIP_TEXT="Tip: Click buttons in the status bar below to manage panes and launch AI tools"
TIP_LEN=${#TIP_TEXT}
# Truncate if too wide
if [[ $TIP_LEN -gt $((COLS - 4)) ]]; then
    TIP_TEXT="Tip: Click status bar buttons to get started"
    TIP_LEN=${#TIP_TEXT}
fi
center_text "${NORD3}${TIP_TEXT}${RESET}" $TIP_LEN

# Keyboard hints line
HINTS="ctrl+c exit    [ ? ] help    [ opencode ] [ claude ]"
HINTS_LEN=${#HINTS}
center_text "${NORD3}${HINTS}${RESET}" $HINTS_LEN

# Restore cursor
tput cnorm

# Brief pause before shell prompt
sleep 0.3
