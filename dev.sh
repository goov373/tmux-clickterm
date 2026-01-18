#!/bin/bash
# dev.sh - Interactive development helper for clickterm
# Usage: ./dev.sh [command]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/clickterm"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  clickterm development helper${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

cmd_install() {
    echo -e "${GREEN}Installing clickterm...${NC}"
    make -s install
}

cmd_reload() {
    echo -e "${GREEN}Reloading tmux...${NC}"
    make -s reload
}

cmd_dev() {
    echo -e "${GREEN}Development cycle: install + reload${NC}"
    make -s dev
}

cmd_lint() {
    echo -e "${GREEN}Running shellcheck...${NC}"
    if command -v shellcheck >/dev/null 2>&1; then
        local failed=0
        for script in "$SCRIPT_DIR"/*.sh; do
            if [ -f "$script" ]; then
                if shellcheck -x "$script" 2>/dev/null; then
                    echo -e "  ${GREEN}✓${NC} $(basename "$script")"
                else
                    echo -e "  ${RED}✗${NC} $(basename "$script")"
                    failed=1
                fi
            fi
        done
        if [ $failed -eq 0 ]; then
            echo -e "${GREEN}All scripts passed!${NC}"
        else
            echo -e "${RED}Some scripts have issues.${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}shellcheck not installed. Install with: brew install shellcheck${NC}"
        return 1
    fi
}

cmd_status() {
    print_header
    echo ""
    
    # Check installation
    if [ -d "$CONFIG_DIR" ]; then
        echo -e "  Installation: ${GREEN}Installed${NC} at $CONFIG_DIR"
        local file_count
        file_count=$(find "$CONFIG_DIR" -type f | wc -l | tr -d ' ')
        echo -e "                $file_count files"
    else
        echo -e "  Installation: ${YELLOW}Not installed${NC}"
    fi
    
    # Check current theme
    if [ -f ~/.tmux.conf ]; then
        if grep -q "^source-file.*tmux-theme-light" ~/.tmux.conf 2>/dev/null; then
            echo -e "  Theme:        ${BLUE}Nord Light${NC}"
        else
            echo -e "  Theme:        ${BLUE}Nord Dark${NC}"
        fi
    fi
    
    # Check tmux
    if [ -n "$TMUX" ]; then
        echo -e "  tmux:         ${GREEN}Running${NC}"
    else
        echo -e "  tmux:         ${YELLOW}Not in tmux session${NC}"
    fi
    
    # Check shellcheck
    if command -v shellcheck >/dev/null 2>&1; then
        echo -e "  shellcheck:   ${GREEN}Available${NC}"
    else
        echo -e "  shellcheck:   ${YELLOW}Not installed${NC}"
    fi
    
    # Git status
    if git -C "$SCRIPT_DIR" status --porcelain 2>/dev/null | grep -q .; then
        echo -e "  Git:          ${YELLOW}Uncommitted changes${NC}"
    else
        echo -e "  Git:          ${GREEN}Clean${NC}"
    fi
    
    echo ""
}

cmd_watch() {
    echo -e "${GREEN}Watching for changes... (Ctrl+C to stop)${NC}"
    echo -e "${YELLOW}Note: Requires fswatch. Install with: brew install fswatch${NC}"
    
    if ! command -v fswatch >/dev/null 2>&1; then
        echo -e "${RED}fswatch not installed.${NC}"
        return 1
    fi
    
    fswatch -o "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/*.conf "$SCRIPT_DIR"/*.json | while read -r; do
        echo -e "${BLUE}Change detected, reloading...${NC}"
        cmd_dev
    done
}

cmd_theme() {
    local mode="$1"
    case "$mode" in
        dark)
            make -s theme-dark
            echo -e "${GREEN}Switched to Nord Dark${NC}"
            ;;
        light)
            make -s theme-light
            echo -e "${GREEN}Switched to Nord Light${NC}"
            ;;
        *)
            echo -e "${YELLOW}Usage: $0 theme [dark|light]${NC}"
            return 1
            ;;
    esac
}

cmd_help() {
    print_header
    echo ""
    echo "  Commands:"
    echo ""
    echo "    install     Install clickterm to ~/.config/clickterm"
    echo "    reload      Reload tmux configuration"
    echo "    dev         Install + reload (development cycle)"
    echo "    lint        Run shellcheck on all scripts"
    echo "    status      Show installation and environment status"
    echo "    watch       Watch files and auto-reload on changes"
    echo "    theme       Switch theme: theme dark | theme light"
    echo "    help        Show this help"
    echo ""
    echo "  Examples:"
    echo ""
    echo "    ./dev.sh dev           # Quick development iteration"
    echo "    ./dev.sh lint          # Check scripts before commit"
    echo "    ./dev.sh theme dark    # Switch to dark mode"
    echo "    ./dev.sh watch         # Auto-reload on file changes"
    echo ""
}

# Main
case "${1:-help}" in
    install)
        cmd_install
        ;;
    reload)
        cmd_reload
        ;;
    dev)
        cmd_dev
        ;;
    lint)
        cmd_lint
        ;;
    status)
        cmd_status
        ;;
    watch)
        cmd_watch
        ;;
    theme)
        cmd_theme "$2"
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        cmd_help
        exit 1
        ;;
esac
