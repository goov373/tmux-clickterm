#!/bin/bash
# clickterm shell-init.sh - Initialize clickterm shell environment
# Sourced on tmux session start to set up aliases and show welcome banner

# Define clear alias to show welcome banner instead of just clearing
alias clear='~/.config/clickterm/welcome.sh'

# Show welcome banner on startup
~/.config/clickterm/welcome.sh
