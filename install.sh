#!/bin/bash
# install.sh - Install clickterm to your system
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing clickterm..."
echo ""

# Create config directory
echo "Creating ~/.config/clickterm/..."
mkdir -p ~/.config/clickterm

# Clean up old theme-switching files if they exist
echo "Cleaning up old files..."
rm -f ~/.config/clickterm/theme-switch.sh
rm -f ~/.config/clickterm/sync-theme.sh
rm -f ~/.config/clickterm/tmux-theme-dark.conf
rm -f ~/.config/clickterm/tmux-theme-light.conf

# Unload and remove old launchd agent if it exists
if [ -f ~/Library/LaunchAgents/com.clickterm.theme-watcher.plist ]; then
    launchctl unload ~/Library/LaunchAgents/com.clickterm.theme-watcher.plist 2>/dev/null || true
    rm -f ~/Library/LaunchAgents/com.clickterm.theme-watcher.plist
    echo "Removed old theme-watcher agent"
fi

# Copy scripts
echo "Copying scripts..."
for script in dispatch.sh split.sh close.sh exit.sh launch.sh help-viewer.sh welcome.sh; do
    cp "$SCRIPT_DIR/$script" ~/.config/clickterm/
done

# Copy theme and config files
echo "Copying theme files..."
cp "$SCRIPT_DIR/tmux-theme.conf" ~/.config/clickterm/
cp "$SCRIPT_DIR/theme.json" ~/.config/clickterm/
cp "$SCRIPT_DIR"/*.txt ~/.config/clickterm/ 2>/dev/null || true

# Make scripts executable
chmod +x ~/.config/clickterm/*.sh

# Backup existing tmux.conf if it exists and is not ours
if [ -f ~/.tmux.conf ]; then
    if ! grep -q "clickterm" ~/.tmux.conf 2>/dev/null; then
        echo "Backing up existing ~/.tmux.conf to ~/.tmux.conf.backup..."
        cp ~/.tmux.conf ~/.tmux.conf.backup
    fi
fi

# Install tmux config
echo "Installing tmux configuration..."
cp "$SCRIPT_DIR/configs/tmux.conf" ~/.tmux.conf

# Install iTerm2 Nord profile (macOS only)
if [ -d ~/Library/Application\ Support/iTerm2 ]; then
    echo "Installing iTerm2 Nord profile..."
    mkdir -p ~/Library/Application\ Support/iTerm2/DynamicProfiles
    cp "$SCRIPT_DIR/configs/iterm2/Nord.json" ~/Library/Application\ Support/iTerm2/DynamicProfiles/
fi

# Install OpenCode Nord theme
echo "Installing OpenCode Nord theme..."
mkdir -p ~/.config/opencode/themes
cp "$SCRIPT_DIR/configs/opencode/themes/nord-dark.json" ~/.config/opencode/themes/

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Reload tmux: tmux source-file ~/.tmux.conf"
echo "  2. In iTerm2: Preferences → Profiles → Select 'Nord' → Set as Default"
echo "  3. (Optional) Add '\"theme\": \"nord-dark\"' to ~/.config/opencode/opencode.json"
echo ""
echo "For help, click the [ ? ] button in the tmux status bar."
