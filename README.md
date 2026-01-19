# clickterm

A mouse-driven tmux development environment with a native macOS Dock app.

## Quick Start (Recommended)

```bash
git clone https://github.com/goov373/tmux-clickterm.git
cd tmux-clickterm
./app/build-app.sh
cp -r app/build/clickterm.app /Applications/
```

Then click **clickterm** in your Dock.

## Features

- **Native macOS app** - Click to launch from Dock
- **Mouse-driven workflow** - Click buttons instead of keyboard shortcuts
- **Nord color theme** - Unified colors across iTerm2, tmux, and AI tools
- **Smart pane management** - Auto limits, busy-pane detection
- **Tool launchers** - One-click OpenCode/Claude Code

## Alternative: Scripts Only

If you prefer your own terminal:

```bash
./install.sh
tmux new-session -A -s clickterm
```

## Status Bar Buttons

| Button | Action |
|--------|--------|
| `[ │ Split ]` | Split pane vertically (side by side) |
| `[ ─ Stack ]` | Split pane horizontally (stacked) |
| `[ × Close ]` | Close current pane |
| `[ ⎋ Exit ]` | Send Ctrl+C to exit current program |
| `[ ? ]` | Show help popup |
| `[ opencode ]` | Launch OpenCode AI assistant |
| `[ claude ]` | Launch Claude Code AI assistant |

## Switching Themes

```bash
~/.config/clickterm/theme-switch.sh toggle  # or: dark / light
```

## Requirements

- macOS 12+
- tmux 3.0+
- iTerm2

## License

MIT
