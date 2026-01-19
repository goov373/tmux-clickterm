# clickterm

A mouse-driven tmux development environment with a native macOS app.

**Philosophy:** Click buttons instead of memorizing keyboard shortcuts.

## Quick Start

```bash
git clone https://github.com/goov373/tmux-clickterm.git
cd tmux-clickterm
./app/build-app.sh
cp -r app/build/clickterm.app /Applications/
```

Then launch **clickterm** from your Applications folder or Dock.

## Features

- **Native macOS app** - Proper Dock icon, click to launch
- **Mouse-driven workflow** - Click status bar buttons for all actions
- **Nord Dark theme** - Consistent colors across iTerm2, tmux, and AI tools
- **Smart pane management** - Split limits, busy-pane detection, last-pane protection
- **Tool launchers** - One-click OpenCode and Claude Code buttons

## How It Works

clickterm is a native Swift app that:
1. Launches iTerm2 with a tmux session
2. Installs clickable button scripts on first run
3. Provides a clickable status bar for all common actions

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              iTerm2                                      │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                              tmux                                  │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                                                              │  │  │
│  │  │                     Your Terminal Panes                      │  │  │
│  │  │                                                              │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                                                                    │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │ [ Split ] [ Stack ] [ Close ] [ Exit ] [ ? ] [ opencode ]   │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  │                          ↑ Click these buttons                     │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## Status Bar Buttons

| Button | Action |
|--------|--------|
| `[ │ Split ]` | Split pane vertically (side by side) |
| `[ ─ Stack ]` | Split pane horizontally (stacked) |
| `[ × Close ]` | Close current pane (protected - can't close last pane) |
| `[ ⎋ Exit ]` | Send Ctrl+C to stop current program |
| `[ ? ]` | Show help popup |
| `[ opencode ]` | Launch OpenCode AI assistant |
| `[ claude ]` | Launch Claude Code AI assistant |

## Alternative: Scripts Only

If you prefer to use your own terminal setup:

```bash
./install.sh
tmux new-session -A -s clickterm
```

This installs the scripts and tmux configuration without the macOS app wrapper.

## Requirements

- macOS 12+
- tmux 3.0+
- iTerm2

## Performance Tips

For the smoothest pane resize experience, ensure these iTerm2 settings:

1. **Enable GPU Rendering**  
   Settings → General → Magic → **GPU Rendering** ✓

2. **Disable Throughput Mode**  
   Settings → General → Magic → **Disable** "Maximize throughput..."  
   (Allows higher frame rate during drag operations)

## Project Structure

```
tmux-clickterm/
├── app/
│   ├── clickterm/
│   │   └── main.swift          # Native macOS app source
│   ├── build/
│   │   └── clickterm.app       # Built application bundle
│   └── build-app.sh            # Build script
├── configs/
│   ├── tmux.conf               # Main tmux configuration
│   └── iterm2/Nord.json        # iTerm2 color profile
├── docs/
│   ├── ARCHITECTURE.md         # Technical deep-dive
│   └── EXTENDING.md            # How to add features
├── *.sh                        # Handler scripts
├── tmux-theme.conf             # Nord Dark theme + button definitions
└── install.sh                  # Manual installation script
```

## Development

```bash
make dev          # Install scripts + reload tmux
make lint         # Run shellcheck on all scripts
```

See `docs/EXTENDING.md` for how to add new buttons and features.

## Changelog

### v1.1.0
- Fixed duplicate iTerm dock icon issue
- Reorganized logo assets
- App now reuses existing iTerm instance

### v1.0.0
- Native macOS app for Dock integration
- Opens in new iTerm window (not tab)
- Auto-installs scripts on first run
- Nord Dark theme

## License

MIT
