#!/bin/bash
# clickterm shell-init.sh - Initialize clickterm shell environment
# Sourced on tmux session start to set up aliases and show welcome banner

# Source standard bash profile/rc for normal environment
[[ -f ~/.bash_profile ]] && source ~/.bash_profile
[[ -f ~/.bashrc ]] && source ~/.bashrc

# ─────────────────────────────────────────────────────────────────
# Terminal capability exports for TUI applications (OpenCode, etc.)
# ─────────────────────────────────────────────────────────────────

# Ensure TUI apps detect truecolor support (prevents color approximation overhead)
export COLORTERM=truecolor

# Help TUI apps detect iTerm2 for optimized rendering paths
export TERM_PROGRAM="${TERM_PROGRAM:-iTerm.app}"

# Define clear alias to show welcome banner instead of just clearing
alias clear='~/.config/clickterm/welcome.sh'

# Show welcome banner on startup
~/.config/clickterm/welcome.sh
