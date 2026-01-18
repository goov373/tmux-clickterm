#!/bin/bash
# install.sh - Install clickterm to your system
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing tmux-clickterm..."
echo ""

# Create config directory
echo "Creating ~/.config/clickterm/..."
mkdir -p ~/.config/clickterm

# Copy scripts and configs
echo "Copying scripts and theme files..."
cp "$SCRIPT_DIR"/*.sh ~/.config/clickterm/
cp "$SCRIPT_DIR"/*.json ~/.config/clickterm/
cp "$SCRIPT_DIR"/*.conf ~/.config/clickterm/
cp "$SCRIPT_DIR"/*.txt ~/.config/clickterm/ 2>/dev/null || true

# Make scripts executable
chmod +x ~/.config/clickterm/*.sh

# Backup existing tmux.conf if it exists
if [ -f ~/.tmux.conf ]; then
    echo "Backing up existing ~/.tmux.conf to ~/.tmux.conf.backup..."
    cp ~/.tmux.conf ~/.tmux.conf.backup
fi

# Install tmux config
echo "Installing tmux configuration..."
cp "$SCRIPT_DIR/configs/tmux.conf" ~/.tmux.conf

# Install iTerm2 profiles (macOS only)
if [ -d ~/Library/Application\ Support/iTerm2 ]; then
    echo "Installing iTerm2 Nord profiles..."
    mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
    cp "$SCRIPT_DIR/configs/iterm2/Nord.json" ~/Library/Application\ Support/iTerm2/DynamicProfiles/
fi

# Install OpenCode themes
echo "Installing OpenCode Nord themes..."
mkdir -p ~/.config/opencode/themes
cp "$SCRIPT_DIR/configs/opencode/themes/"*.json ~/.config/opencode/themes/

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reload tmux: tmux source-file ~/.tmux.conf"
echo "  2. Select 'Nord' profile in iTerm2 Preferences → Profiles"
echo "  3. Add to ~/.config/opencode/opencode.json:"
echo '     { "theme": "nord" }'
echo ""
echo "For help, click the [ ? ] button in the tmux status bar."
