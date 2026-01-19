#!/bin/bash
# clickterm welcome.sh - Display welcome banner (top-left justified)
# Called on session start and when user runs 'clear'

# Nord colors
NORD4="\033[38;2;216;222;233m"
NORD8="\033[38;2;136;192;208m"
RESET="\033[0m"
BOLD="\033[1m"

# Clear screen
clear

# ASCII logo
echo -e "${NORD8}${BOLD}      __ __      __    __                       ${RESET}"
echo -e "${NORD8}${BOLD}.----|  |__.----.|  |--|  |_.-----.----.--------.${RESET}"
echo -e "${NORD8}${BOLD}|  __|  |  |  __||    <|   _|  -__|   _|        |${RESET}"
echo -e "${NORD8}${BOLD}|____|__|__|____||__|__|____|_____|__| |__|__|__|${RESET}"
echo
echo -e "${NORD4}mouse-driven tmux environment${RESET}"
echo
echo -e "${NORD4}Tip: Click status bar buttons to manage panes and launch AI tools${RESET}"
echo -e "${NORD4}[ | Split ]  [ - Stack ]  [ x Close ]  [ ? ]  [ opencode ]  [ claude ]${RESET}"
echo
