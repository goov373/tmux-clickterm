# Why clickterm Needs a Native App Rewrite

> Analysis of design expectations vs. terminal stack limitations

## Executive Summary

clickterm's vision is a **mouse-first, visually polished development environment**. The current implementation—tmux + iTerm2 + shell scripts—was the right choice for a quick prototype, but fundamentally cannot deliver the modern UI/UX expectations we're aiming for.

This document catalogs every specific limitation we've encountered and explains why a native fullstack app is the path forward.

---

## Design Expectations vs. Reality

### What We Want

| Expectation | Description |
|-------------|-------------|
| Modern visual design | Rounded corners, shadows, depth, polish |
| Consistent theming | One source of truth for all colors/styles |
| Smooth interactions | Hover states, transitions, animations |
| Intuitive pane selection | Clear visual indicators for active pane |
| Discoverable UI | Buttons, tooltips, contextual menus |
| Cross-tool consistency | Same look in terminal, AI tools, popups |

### What Terminal UIs Deliver

| Reality | Description |
|---------|-------------|
| Character grid | Everything is monospace text cells |
| Box-drawing borders | `─│╭╮╰╯` characters, not CSS |
| ANSI colors only | 256 or 24-bit colors, no gradients |
| No depth/layering | Flat rendering, no z-index |
| No hover states | Click-only, no pointer feedback |
| Fragmented theming | Each tool has its own config format |

---

## Specific Limitations Encountered

### 1. Visual Styling

#### Rounded Corners

| Layer | Capability | Notes |
|-------|------------|-------|
| tmux popups | `╭╮╰╯` box chars | Only option is `-b rounded` |
| tmux panes | None | Borders are `─│` lines only |
| tmux status bar | None | Flat bar, no shape control |
| iTerm2 window | macOS native | Not controllable by us |
| OpenCode TUI | Box chars | Hardcoded in source |

**Verdict:** Cannot achieve consistent rounded corners across the stack.

#### Drop Shadows

| Layer | Capability |
|-------|------------|
| tmux | Not possible |
| iTerm2 | macOS window shadow only |
| OpenCode TUI | Not possible |
| Any terminal UI | Not possible |

**Verdict:** Shadows are fundamentally impossible in terminal rendering.

#### Gradients

| Layer | Capability |
|-------|------------|
| All terminal layers | Not supported |

**Verdict:** Terminal UIs are solid colors only.

---

### 2. Theming & Consistency

#### Current State: Theme Fragmentation

We maintain **7+ separate files** with duplicated color values:

| File | Format | Controls |
|------|--------|----------|
| `theme.json` | JSON | Reference only (not consumed) |
| `tmux-theme.conf` | tmux syntax | Panes, status bar, buttons |
| `configs/iterm2/Nord.json` | iTerm JSON | Terminal colors |
| `configs/opencode/themes/nord-dark.json` | OpenCode JSON | AI tool UI |
| `welcome.sh` | ANSI escape codes | Banner colors |
| `help-viewer.sh` | Hardcoded chars | Popup styling |
| `dispatch.sh` | Inline values | Popup dimensions |

**Problems:**
- No single source of truth
- Manual sync required when changing colors
- Different syntax per tool (tmux vs JSON vs ANSI)
- OpenCode theme only controls colors, not borders/layout
- No build step to propagate changes

**What we'd need:** A theme compiler that generates all formats from one source—but even then, we can't control border styles or layout.

---

### 3. Pane Selection Indicators

#### What We Asked For
Clear visual indication of which pane is active.

#### What's Available

| Indicator Type | tmux Support | Effectiveness |
|----------------|--------------|---------------|
| Border color | Yes | Subtle, easy to miss |
| Border style (thick/double) | Yes | Still just lines |
| Pane dimming | Yes | Best option currently |
| Colored overlay | No | Not possible |
| Glow/shadow | No | Not possible |
| Animated indicator | No | Not possible |

**Current solution:** Dimmed inactive panes + colored active border
**Limitation:** Still subtle; no way to make it "pop"

---

### 4. Interactive Feedback

#### Hover States

| Element | Hover Support |
|---------|---------------|
| Status bar buttons | None |
| Pane borders | None |
| Help popup | None |
| Any tmux element | None |

Terminals don't report mouse hover—only clicks. There's no way to show "this button will do X" on hover.

#### Transitions/Animations

| Animation Type | Support |
|----------------|---------|
| Fade in/out | No |
| Slide transitions | No |
| Smooth resize | No (iTerm2 does this, not us) |
| Loading spinners | Character-based only |

---

### 5. Layout Constraints

#### Status Bar

| Constraint | Impact |
|------------|--------|
| Single line only | Can't have multi-row toolbars |
| Fixed position (top/bottom) | Can't float or dock elsewhere |
| Text only | No icons (except Unicode chars) |
| No grouping | Can't create button groups with borders |

#### Popups

| Constraint | Impact |
|------------|--------|
| Rectangular only | No custom shapes |
| Character grid sizing | Can't pixel-align |
| No backdrop blur | Can't dim background smoothly |
| Modal only | Can't have non-blocking popovers |

#### Panes

| Constraint | Impact |
|------------|--------|
| Grid-based splits | No free-form positioning |
| Equal split only | Manual resize required |
| No tabs within panes | Would need nested tmux |
| No minimize/maximize | Zoom exists but is awkward |

---

### 6. Tool Integration

#### OpenCode

| What We Want | What's Possible |
|--------------|-----------------|
| Match our theme exactly | Colors only—borders/layout hardcoded |
| Rounded containers | Would require forking OpenCode |
| Custom fonts | Inherited from terminal |
| Embedded in our UI | Runs as separate process |

#### Claude Code

| What We Want | What's Possible |
|--------------|-----------------|
| Same as OpenCode | Same limitations |
| Unified experience | Different codebase, different styling |

**Maintaining forks is not sustainable.** Every update requires rebasing our changes.

---

### 7. Performance & Responsiveness

#### Current Architecture

```
User Click → tmux event → bash script → tmux command → render
```

Each step adds latency:
- tmux event processing: ~5-10ms
- Bash script startup: ~10-20ms
- tmux command execution: ~5-10ms
- Screen redraw: ~16ms (60fps)

**Total:** 35-55ms per action (acceptable but not instant)

#### What Native Apps Achieve

```
User Click → Event handler → Render
```

**Total:** <16ms (feels instant)

---

## Summary: What We Cannot Do

| Capability | Terminal Stack | Native App |
|------------|----------------|------------|
| Rounded corners | Limited | Full control |
| Drop shadows | No | Yes |
| Gradients | No | Yes |
| Hover states | No | Yes |
| Animations | No | Yes |
| Single theme source | Fragmented | Unified |
| Custom fonts | No | Yes |
| Pixel-perfect layout | No | Yes |
| <16ms interactions | Difficult | Easy |
| Embedded tool views | No | WebView/native |
| Non-rectangular UI | No | Yes |
| Backdrop blur | No | Yes |
| Custom cursors | No | Yes |
| Drag-and-drop | Limited | Full |
| Tooltips | No | Yes |
| Context menus | tmux menus only | Native menus |

---

## The Path Forward

### Option 1: Accept Terminal Limitations

Keep the current stack, accept that:
- Visual polish is limited
- Theming is fragmented
- Each tool looks different
- No hover/animation feedback

**Pros:** Already built, works today
**Cons:** Will never feel "modern"

### Option 2: Native App Wrapping Terminal

Build a native app that embeds a terminal view:
- SwiftUI/AppKit for chrome (buttons, sidebar, etc.)
- Terminal emulator view for actual shell
- Native UI around terminal edges

**Pros:** Best of both worlds
**Cons:** Complex integration, two rendering systems

### Option 3: Full Native Rewrite

Build a native app from scratch:
- SwiftUI or Electron/Tauri for UI
- PTY for shell integration
- Custom pane management
- Unified theming system

**Pros:** Full control, modern UX
**Cons:** Significant effort, rebuilding tmux functionality

### Option 4: Web-Based (Electron/Tauri)

Build with web technologies:
- React/SolidJS for UI
- xterm.js for terminal
- CSS for all styling
- Single theme system

**Pros:** Familiar tech, cross-platform potential, full CSS control
**Cons:** Electron overhead, not "truly native"

---

## Recommended Architecture

For a 2026-ready clickterm, we recommend **Option 4 (Tauri + Web UI)**:

```
┌─────────────────────────────────────────────────────────────────┐
│                        Tauri Shell                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     Web UI (SolidJS)                       │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Toolbar (native-feeling, full CSS control)          │  │  │
│  │  ├─────────────────────────────────────────────────────┤  │  │
│  │  │  ┌─────────────────┐  ┌─────────────────────────┐   │  │  │
│  │  │  │  Terminal Pane  │  │     Terminal Pane       │   │  │  │
│  │  │  │  (xterm.js)     │  │     (xterm.js)          │   │  │  │
│  │  │  │                 │  │                         │   │  │  │
│  │  │  │  - Rounded      │  │  - Shadows on focus     │   │  │  │
│  │  │  │  - Shadows      │  │  - Hover indicators     │   │  │  │
│  │  │  │  - Themed       │  │  - Smooth resize        │   │  │  │
│  │  │  └─────────────────┘  └─────────────────────────┘   │  │  │
│  │  ├─────────────────────────────────────────────────────┤  │  │
│  │  │  Status Bar (CSS buttons, hover states, tooltips)    │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Why Tauri?

| Factor | Electron | Tauri |
|--------|----------|-------|
| Bundle size | ~150MB | ~5MB |
| Memory usage | High | Low |
| macOS native feel | Okay | Better |
| Rust backend | No | Yes (fast PTY) |
| Web UI | Yes | Yes |

### Key Components

1. **Theme System**
   - Single JSON/CSS source
   - CSS variables for all colors
   - Runtime theme switching
   - Light/dark mode support

2. **Terminal Rendering**
   - xterm.js with WebGL renderer
   - Custom CSS for pane chrome
   - Rounded corners via CSS
   - Shadow on active pane

3. **Pane Management**
   - Custom implementation (not tmux)
   - Drag-to-resize with smooth animation
   - Free-form or grid layouts
   - Tabs within panes

4. **Tool Integration**
   - AI tools run in terminal panes
   - Or: embedded WebViews for `opencode web`
   - Unified appearance

5. **Button System**
   - Real buttons with hover states
   - Tooltips
   - Keyboard shortcuts shown
   - Customizable toolbar

---

## Conclusion

The terminal stack (tmux + iTerm2 + shell scripts) is fundamentally limited by the character-grid rendering model. No amount of configuration or scripting can overcome these constraints.

To build a modern, visually polished development environment, we need to move to a native or web-based app architecture where we control the full rendering pipeline.

The clickterm prototype proves the concept works. Now it's time to rebuild it properly.
