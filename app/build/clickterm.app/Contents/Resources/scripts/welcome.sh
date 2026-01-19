#!/bin/bash
# clickterm welcome.sh - Display centered welcome banner
# Static display, no input handling, no resize reactivity
# Called on session start and when user runs 'clear'

# Nord colors
NORD3="\033[38;2;76;86;106m"
NORD8="\033[38;2;136;192;208m"
RESET="\033[0m"
BOLD="\033[1m"

# Get terminal dimensions
COLS=$(tput cols)
LINES=$(tput lines)

# ASCII logo (46 chars wide, 5 lines tall)
LOGO='      _ _      _    _                      
  ___| (_) ___| | _| |_ ___ _ __ _ __ ___  
 / __| | |/ __| |/ / __/ _ \'"'"'__| '"'"'_ ` _ \ 
| (__| | | (__|   <| ||  __/ |  | | | | | |
 \___|_|_|\___|_|\_\\__\___|_|  |_| |_| |_|'

TAGLINE="mouse-driven tmux environment"
TIP="Tip: Click status bar buttons to manage panes and launch AI tools"
HINTS="[ | Split ]  [ - Stack ]  [ x Close ]  [ ? ]  [ opencode ]  [ claude ]"

# Helper: center and print text
center() {
    local text="$1"
    local width="${2:-${#text}}"
    local pad=$(( (COLS - width) / 2 ))
    (( pad < 0 )) && pad=0
    printf '%*s' "$pad" ''
    echo -e "$text"
}

# Clear screen
clear

# Calculate vertical centering
# Content: 5 (logo) + 1 (blank) + 1 (tagline) + 2 (blank) + 1 (tip) + 1 (hints) + 3 (blank before prompt) = 14
CONTENT_HEIGHT=14
TOP_PAD=$(( (LINES - CONTENT_HEIGHT) / 2 ))
(( TOP_PAD < 0 )) && TOP_PAD=0

# Print vertical padding (top)
for ((i=0; i<TOP_PAD; i++)); do echo; done

# Print logo (line by line, centered)
while IFS= read -r line; do
    center "${NORD8}${BOLD}${line}${RESET}" ${#line}
done <<< "$LOGO"

# Blank line after logo
echo

# Tagline (centered)
center "${NORD3}${TAGLINE}${RESET}" ${#TAGLINE}

# Blank lines before tips
echo
echo

# Tip line (centered)
center "${NORD3}${TIP}${RESET}" ${#TIP}

# Button hints (centered)
center "${NORD3}${HINTS}${RESET}" ${#HINTS}

# Blank lines before shell prompt appears
echo
echo
echo
