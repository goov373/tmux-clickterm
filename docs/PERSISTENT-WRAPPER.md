# Persistent Wrapper App Plan

## Problem

When clickterm launches, it opens iTerm2 with tmux. Since iTerm2 is the actual terminal process, it shows in the Dock and recent apps instead of clickterm. Users expect to see the clickterm icon.

## Current Architecture

```
clickterm.app (launcher)
       │
       ├── Launches iTerm2 with tmux session
       └── Exits (or sits idle with no window)
              │
              ▼
       iTerm2 (active app)
              │
              └── Shows in Dock/recent apps
```

## Proposed Architecture

```
clickterm.app (persistent wrapper)
       │
       ├── Embeds terminal view directly
       ├── Runs tmux session inside embedded terminal
       └── Stays as active app
              │
              ▼
       clickterm shows in Dock/recent apps
```

## Implementation Options

### Option A: Embed Terminal.app View (Recommended)

Use a WebView or pseudo-terminal (PTY) to run a shell session directly inside a native macOS window.

**Pros:**
- Full control over appearance
- clickterm icon always shows
- No dependency on iTerm2

**Cons:**
- More complex implementation
- Need to handle terminal emulation (or use a library)
- Loses iTerm2 features (split panes handled by tmux anyway)

**Technical approach:**
1. Create `NSWindow` with `NSView` for terminal content
2. Use `PseudoTerminal` (PTY) to spawn shell process
3. Run `tmux new-session -A -s clickterm` in the PTY
4. Render terminal output using a library like [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm)

### Option B: Proxy Window Pattern

Keep iTerm2 but create a clickterm window that stays in front and forwards focus.

**Pros:**
- Simpler than full terminal emulation
- Keeps iTerm2 features

**Cons:**
- Hacky - two apps running
- Focus/activation edge cases
- iTerm2 still visible in app switcher (Cmd+Tab)

**Technical approach:**
1. clickterm creates a borderless transparent window
2. Launches iTerm2 behind it
3. Monitors iTerm2 process and terminates when it closes
4. Uses Accessibility API to keep iTerm2 positioned

**Not recommended** - too fragile.

### Option C: Use Terminal.app Instead

Replace iTerm2 with built-in Terminal.app which can be scripted to hide from Dock.

**Pros:**
- No dependencies
- Simpler AppleScript integration

**Cons:**
- Terminal.app has fewer features
- Still shows in Cmd+Tab app switcher
- Doesn't solve the core problem

**Not recommended** - doesn't fully solve the icon issue.

---

## Recommended Implementation: Option A with SwiftTerm

### Phase 1: Basic Terminal Window

**Files to create:**
- `app/clickterm/TerminalView.swift` - Terminal rendering view
- `app/clickterm/SessionManager.swift` - PTY and tmux session handling

**Dependencies:**
- Add SwiftTerm via Swift Package Manager

**Tasks:**
1. Add SwiftTerm package to project
2. Create `NSWindow` with `TerminalView`
3. Spawn PTY with login shell
4. Connect PTY to SwiftTerm view
5. Test basic shell interaction

### Phase 2: tmux Integration

**Tasks:**
1. Auto-run `tmux new-session -A -s clickterm` on launch
2. Set correct TERM environment variable
3. Handle window resize → tmux resize
4. Test mouse support (clickterm buttons)

### Phase 3: Polish

**Tasks:**
1. Apply Nord theme colors to terminal view
2. Set window title from tmux
3. Handle Cmd+Q → detach tmux, then quit
4. Handle Dock click → reattach or new session
5. Add to Login Items option

### Phase 4: Remove iTerm2 Dependency

**Tasks:**
1. Update install.sh - no longer needs iTerm2 profile
2. Update README - reflect new architecture
3. Test on clean macOS install

---

## File Changes Summary

```
app/
├── clickterm/
│   ├── main.swift           # Modify - create window instead of launching iTerm
│   ├── AppDelegate.swift    # New - extracted from main.swift
│   ├── TerminalView.swift   # New - SwiftTerm wrapper
│   └── SessionManager.swift # New - PTY/tmux management
├── Package.swift            # New - SwiftTerm dependency
└── build-app.sh             # Modify - build with SPM
```

---

## Alternative: Simpler PTY Without SwiftTerm

If avoiding dependencies is preferred, use raw PTY with a basic `NSTextView`:

**Pros:**
- No external dependencies
- Smaller binary

**Cons:**
- Must handle ANSI escape codes manually
- No mouse support without significant work
- Limited terminal emulation

**Not recommended** for this project since mouse support is critical.

---

## Estimated Effort

| Phase | Time Estimate |
|-------|---------------|
| Phase 1: Basic terminal | 4-6 hours |
| Phase 2: tmux integration | 2-3 hours |
| Phase 3: Polish | 2-3 hours |
| Phase 4: Cleanup | 1-2 hours |
| **Total** | **9-14 hours** |

---

## Decision Needed

Before implementing, confirm:

1. **Acceptable to remove iTerm2 dependency?** 
   - Users would use the built-in clickterm terminal instead
   
2. **Acceptable to add SwiftTerm dependency?**
   - ~2MB added to app size
   - Well-maintained library by Miguel de Icaza (Mono/Xamarin creator)

3. **Priority level?**
   - This is a nice-to-have UX improvement
   - Current workaround: pin clickterm to Dock
