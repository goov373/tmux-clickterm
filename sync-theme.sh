#!/bin/bash
# sync-theme.sh - Generate OpenCode and tmux themes from master theme.json
# Usage: ./sync-theme.sh [--reload]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_FILE="$SCRIPT_DIR/theme.json"
OPENCODE_THEME="$SCRIPT_DIR/opencode-theme.json"
TMUX_THEME="$SCRIPT_DIR/tmux-theme.conf"

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
fi

# Check theme file exists
if [ ! -f "$THEME_FILE" ]; then
    echo "Error: theme.json not found at $THEME_FILE"
    exit 1
fi

echo "Reading theme from $THEME_FILE..."

# Extract colors from theme.json
BG_BASE=$(jq -r '.colors["bg-base"]' "$THEME_FILE")
BG_PANEL=$(jq -r '.colors["bg-panel"]' "$THEME_FILE")
BG_ELEMENT=$(jq -r '.colors["bg-element"]' "$THEME_FILE")
FG_PRIMARY=$(jq -r '.colors["fg-primary"]' "$THEME_FILE")
FG_MUTED=$(jq -r '.colors["fg-muted"]' "$THEME_FILE")
FG_DIM=$(jq -r '.colors["fg-dim"]' "$THEME_FILE")
ACCENT=$(jq -r '.colors["accent"]' "$THEME_FILE")
BORDER=$(jq -r '.colors["border"]' "$THEME_FILE")
BORDER_ACTIVE=$(jq -r '.colors["border-active"]' "$THEME_FILE")
ERROR=$(jq -r '.colors["error"]' "$THEME_FILE")
WARNING=$(jq -r '.colors["warning"]' "$THEME_FILE")
SUCCESS=$(jq -r '.colors["success"]' "$THEME_FILE")
INFO=$(jq -r '.colors["info"]' "$THEME_FILE")

echo "Generating OpenCode theme..."

# Generate OpenCode theme
cat > "$OPENCODE_THEME" << EOF
{
  "\$schema": "https://opencode.ai/theme.json",
  "defs": {
    "bg-base": "$BG_BASE",
    "bg-panel": "$BG_PANEL",
    "bg-element": "$BG_ELEMENT",
    "fg-primary": "$FG_PRIMARY",
    "fg-muted": "$FG_MUTED",
    "fg-dim": "$FG_DIM",
    "accent": "$ACCENT",
    "border": "$BORDER",
    "border-active": "$BORDER_ACTIVE",
    "error": "$ERROR",
    "warning": "$WARNING",
    "success": "$SUCCESS",
    "info": "$INFO"
  },
  "theme": {
    "primary": {
      "dark": "accent",
      "light": "info"
    },
    "secondary": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "accent": {
      "dark": "accent",
      "light": "info"
    },
    "error": {
      "dark": "error",
      "light": "error"
    },
    "warning": {
      "dark": "warning",
      "light": "warning"
    },
    "success": {
      "dark": "success",
      "light": "success"
    },
    "info": {
      "dark": "info",
      "light": "info"
    },
    "text": {
      "dark": "fg-primary",
      "light": "bg-base"
    },
    "textMuted": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "background": {
      "dark": "bg-base",
      "light": "accent"
    },
    "backgroundPanel": {
      "dark": "bg-panel",
      "light": "fg-primary"
    },
    "backgroundElement": {
      "dark": "bg-element",
      "light": "fg-muted"
    },
    "border": {
      "dark": "border",
      "light": "border"
    },
    "borderActive": {
      "dark": "border-active",
      "light": "border-active"
    },
    "borderSubtle": {
      "dark": "border",
      "light": "border"
    },
    "diffAdded": {
      "dark": "success",
      "light": "success"
    },
    "diffRemoved": {
      "dark": "error",
      "light": "error"
    },
    "diffContext": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "diffHunkHeader": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "diffHighlightAdded": {
      "dark": "success",
      "light": "success"
    },
    "diffHighlightRemoved": {
      "dark": "error",
      "light": "error"
    },
    "diffAddedBg": {
      "dark": "bg-panel",
      "light": "bg-panel"
    },
    "diffRemovedBg": {
      "dark": "bg-panel",
      "light": "bg-panel"
    },
    "diffContextBg": {
      "dark": "bg-base",
      "light": "bg-base"
    },
    "diffLineNumber": {
      "dark": "fg-dim",
      "light": "fg-dim"
    },
    "diffAddedLineNumberBg": {
      "dark": "bg-panel",
      "light": "bg-panel"
    },
    "diffRemovedLineNumberBg": {
      "dark": "bg-panel",
      "light": "bg-panel"
    },
    "markdownText": {
      "dark": "fg-primary",
      "light": "bg-base"
    },
    "markdownHeading": {
      "dark": "accent",
      "light": "info"
    },
    "markdownLink": {
      "dark": "info",
      "light": "info"
    },
    "markdownLinkText": {
      "dark": "accent",
      "light": "info"
    },
    "markdownCode": {
      "dark": "success",
      "light": "success"
    },
    "markdownBlockQuote": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "markdownEmph": {
      "dark": "warning",
      "light": "warning"
    },
    "markdownStrong": {
      "dark": "accent",
      "light": "info"
    },
    "markdownHorizontalRule": {
      "dark": "border",
      "light": "border"
    },
    "markdownListItem": {
      "dark": "accent",
      "light": "info"
    },
    "markdownListEnumeration": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "markdownImage": {
      "dark": "info",
      "light": "info"
    },
    "markdownImageText": {
      "dark": "accent",
      "light": "info"
    },
    "markdownCodeBlock": {
      "dark": "fg-primary",
      "light": "bg-base"
    },
    "syntaxComment": {
      "dark": "fg-muted",
      "light": "fg-muted"
    },
    "syntaxKeyword": {
      "dark": "info",
      "light": "info"
    },
    "syntaxFunction": {
      "dark": "accent",
      "light": "info"
    },
    "syntaxVariable": {
      "dark": "fg-primary",
      "light": "bg-base"
    },
    "syntaxString": {
      "dark": "success",
      "light": "success"
    },
    "syntaxNumber": {
      "dark": "warning",
      "light": "warning"
    },
    "syntaxType": {
      "dark": "info",
      "light": "info"
    },
    "syntaxOperator": {
      "dark": "fg-primary",
      "light": "bg-base"
    },
    "syntaxPunctuation": {
      "dark": "fg-muted",
      "light": "fg-muted"
    }
  }
}
EOF

echo "Generated: $OPENCODE_THEME"

echo "Generating tmux theme..."

# Generate tmux theme
cat > "$TMUX_THEME" << EOF
# ═══════════════════════════════════════════════════════════════
# clickterm tmux theme - generated from theme.json
# DO NOT EDIT DIRECTLY - run sync-theme.sh to regenerate
# ═══════════════════════════════════════════════════════════════

# Pane borders
set -g pane-active-border-style "fg=$BORDER_ACTIVE"
set -g pane-border-style "fg=$BORDER"

# Pane dimming (inactive vs active)
set -g window-style "fg=$FG_DIM"
set -g window-active-style "fg=$FG_PRIMARY"

# Pane title bar
set -g pane-border-status top
set -g pane-border-format " #[fg=$FG_PRIMARY]#{pane_current_command}#[default] "

# Status bar base
set -g status-position bottom
set -g status-style "bg=$BG_PANEL,fg=$FG_PRIMARY"
set -g status-left-length 100
set -g status-right-length 100

# Status bar buttons (left side - pane actions)
set -g status-left "#[range=user|splitv]#[fg=$FG_PRIMARY][ │ Split ]#[norange] #[range=user|splith]#[fg=$FG_PRIMARY][ ─ Stack ]#[norange] #[range=user|close]#[fg=$FG_PRIMARY][ × Close ]#[norange] #[range=user|exit]#[fg=$FG_PRIMARY][ ⎋ Exit ]#[norange]  "

# Status bar buttons (right side - tools)
set -g status-right "#[range=user|help]#[fg=$FG_PRIMARY][ ? ]#[norange] #[range=user|opencode]#[fg=$FG_PRIMARY][ opencode ]#[norange] #[range=user|claude]#[fg=$FG_PRIMARY][ claude ]#[norange] "

# Window list (hidden - we use custom buttons)
set -g window-status-format ""
set -g window-status-current-format ""

# ═══════════════════════════════════════════════════════════════
# END clickterm theme
# ═══════════════════════════════════════════════════════════════
EOF

echo "Generated: $TMUX_THEME"

# Reload tmux if requested
if [ "$1" = "--reload" ]; then
    if [ -n "$TMUX" ]; then
        echo "Reloading tmux configuration..."
        tmux source-file ~/.tmux.conf
        echo "tmux reloaded."
    else
        echo "Not in tmux session, skipping reload."
    fi
fi

echo ""
echo "Theme sync complete!"
echo ""
echo "To apply changes:"
echo "  1. Reload tmux: tmux source-file ~/.tmux.conf"
echo "  2. Restart OpenCode to see theme changes"
