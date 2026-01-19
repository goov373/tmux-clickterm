# Future Enhancement: Embedded Terminal

> **Status:** Planning document for potential future enhancement.
> The original "duplicate dock icon" issue has been resolved (see below).

## Problem (Resolved)

~~When clickterm launches, iTerm2 shows a duplicate Dock icon because we used `open -n` which forces a new instance.~~

**Resolution:** Removed the `-n` flag from the `open` command in `main.swift`. Now iTerm2 reuses an existing instance, showing only one Dock icon.

## Current Architecture

```
clickterm.app (launcher)
       │
       ├── Launches iTerm2 with tmux session
       ├── Reuses existing iTerm instance (no duplicate icon)
       └── Stays running to maintain Dock presence
              │
              ▼
       iTerm2 (single instance)
              │
              └── Runs tmux clickterm session
```

This works well and provides a good user experience.

---

## Future Enhancement: Embedded Terminal

A potential future enhancement would be to embed a terminal emulator directly in clickterm.app, removing the iTerm2 dependency entirely.

### Why Consider This?

1. **Single app** - No external dependencies
2. **Full control** - Custom theming, behavior
3. **Cleaner UX** - Only clickterm in Dock/app switcher

### Why Not Do This Now?

1. **Current solution works well** - No user complaints
2. **Significant effort** - 10-15 hours of development
3. **Adds complexity** - Terminal emulation is non-trivial
4. **Loses iTerm2 features** - Though tmux handles most

### If We Proceed: Technical Approach

Use [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) library:

1. Add SwiftTerm via Swift Package Manager
2. Create `NSWindow` with `TerminalView`
3. Spawn PTY with login shell
4. Auto-run `tmux new-session -A -s clickterm`
5. Handle window resize → tmux resize

### Estimated Effort

| Phase | Time |
|-------|------|
| Basic terminal window | 4-6 hours |
| tmux integration | 2-3 hours |
| Polish (theming, Cmd+Q) | 2-3 hours |
| Remove iTerm dependency | 1-2 hours |
| **Total** | **9-14 hours** |

### Files That Would Change

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

## Decision

**Current decision:** Keep the iTerm2 integration. It works well, users are familiar with iTerm2, and the simpler architecture is easier to maintain.

**Revisit if:** Users request removing the iTerm2 dependency or we need features that iTerm2 can't provide.
