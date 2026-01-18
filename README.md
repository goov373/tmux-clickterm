# tmux-clickterm

A mouse-driven tmux development environment for non-technical users, featuring the Nord color theme across the entire terminal stack.

![Nord Theme](https://raw.githubusercontent.com/nordtheme/nord/develop/assets/nord-overview.svg)

## Overview

clickterm transforms tmux into a click-to-navigate interface with status bar buttons for common operations. No keyboard shortcuts required.

**Status bar buttons:**
```
[ │ Split ] [ ─ Stack ] [ × Close ] [ ⎋ Exit ]  [ ? ] [ opencode ] [ claude ]
```

## Features

- **Mouse-driven workflow** - Click buttons instead of memorizing keyboard shortcuts
- **Nord color theme** - Beautiful, unified colors across iTerm2, tmux, OpenCode, and Claude Code
- **Smart pane management** - Automatic horizontal pane limits, busy-pane detection
- **Tool launchers** - One-click launch for AI coding assistants (OpenCode, Claude Code)
- **Dark/Light mode** - Full theme support for both modes

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/goov373/tmux-clickterm.git
cd tmux-clickterm
```

### 2. Run the install script

```bash
./install.sh
```

Or install manually:

### Manual Installation

#### Copy clickterm scripts
```bash
mkdir -p ~/.config/clickterm
cp *.sh *.json *.conf *.txt ~/.config/clickterm/
chmod +x ~/.config/clickterm/*.sh
```

#### Install tmux config
```bash
cp configs/tmux.conf ~/.tmux.conf
```

#### Install iTerm2 Nord profiles
```bash
cp configs/iterm2/Nord.json ~/Library/Application\ Support/iTerm2/DynamicProfiles/
```

#### Install OpenCode Nord themes
```bash
mkdir -p ~/.config/opencode/themes
cp configs/opencode/themes/*.json ~/.config/opencode/themes/
```

### 3. Configure OpenCode to use Nord theme

Add to `~/.config/opencode/opencode.json`:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "theme": "nord"
}
```

### 4. Select Nord profile in iTerm2

Open iTerm2 → Preferences → Profiles → Select "Nord" or "Nord Light"

### 5. Reload tmux

```bash
tmux source-file ~/.tmux.conf
```

## Usage

### Status Bar Buttons

| Button | Action |
|--------|--------|
| `[ │ Split ]` | Split pane vertically (side by side) |
| `[ ─ Stack ]` | Split pane horizontally (stacked) |
| `[ × Close ]` | Close current pane |
| `[ ⎋ Exit ]` | Send Ctrl+C to exit current program |
| `[ ? ]` | Show help popup |
| `[ opencode ]` | Launch OpenCode AI assistant |
| `[ claude ]` | Launch Claude Code AI assistant |

### Switching Themes

Toggle between dark and light mode:
```bash
~/.config/clickterm/theme-switch.sh toggle
```

Or switch directly:
```bash
~/.config/clickterm/theme-switch.sh dark
~/.config/clickterm/theme-switch.sh light
```

**Note:** You'll also need to switch your iTerm2 profile and restart OpenCode for full effect.

## File Structure

```
~/.config/clickterm/
├── close.sh              # Close pane handler
├── dispatch.sh           # Routes button clicks to scripts
├── exit.sh               # Send Ctrl+C handler
├── help-viewer.sh        # Help popup display
├── help.txt              # Help content
├── launch.sh             # Tool launcher (opencode/claude)
├── split.sh              # Pane splitting handler
├── theme-switch.sh       # Dark/light mode toggle
├── theme.json            # Master Nord color definitions
├── tmux-theme-dark.conf  # Nord dark tmux theme
└── tmux-theme-light.conf # Nord light tmux theme
```

## Nord Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| nord0 | `#2e3440` | Dark background |
| nord1 | `#3b4252` | Elevated UI |
| nord2 | `#434c5e` | Selection |
| nord3 | `#4c566a` | Comments, muted text |
| nord4 | `#d8dee9` | Primary text (dark mode) |
| nord5 | `#e5e9f0` | Secondary text |
| nord6 | `#eceff4` | Light background |
| nord8 | `#88c0d0` | Primary accent (cyan) |
| nord10 | `#5e81ac` | Secondary accent (blue) |
| nord11 | `#bf616a` | Error (red) |
| nord12 | `#d08770` | Warning (orange) |
| nord14 | `#a3be8c` | Success (green) |

## Requirements

- macOS (tested on macOS 15+)
- tmux 3.0+
- iTerm2
- Optional: OpenCode, Claude Code

## License

MIT License - see [LICENSE](LICENSE)

## Credits

- [Nord Theme](https://www.nordtheme.com/) - The beautiful color palette
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
