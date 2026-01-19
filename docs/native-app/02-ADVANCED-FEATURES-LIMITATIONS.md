# Advanced Features: Terminal Stack Limitations

> Why pane management, sidebars, live preview, and session linking require a native app

## Overview

This document extends the analysis in `NATIVE-APP-RATIONALE.md` to cover advanced features we want to build:

1. **Custom AI coding agent** (our own "opencode")
2. **Git/file management sidebar**
3. **Session/agent management sidebar**
4. **Enhanced pane functionality** (file preview, live reload)
5. **Project/session linking and isolation**

For each feature, we analyze what the terminal stack can and cannot do.

---

## Feature 1: Building Our Own AI Coding Agent

### Vision

A custom AI coding assistant that:
- Lives in a pane or sidebar
- Shows file diffs with syntax highlighting
- Displays tool calls and their results
- Has conversation history
- Integrates with our theme and UI

### Terminal Stack Limitations

| Requirement | Terminal Capability | Limitation |
|-------------|---------------------|------------|
| Rich text rendering | ANSI codes only | No inline images, limited formatting |
| Diff viewer | Character-based | No collapsible hunks, no mini-map |
| Syntax highlighting | Depends on tool | Must shell out to `bat`, `delta`, etc. |
| Streaming responses | Possible | But cursor management is tricky |
| Tool call visualization | Text only | No progress bars, spinners are hacky |
| Conversation history | Scroll buffer | No search, no jump-to-message |
| File tree in responses | ASCII art | No clickable file links |
| Image display | iTerm2 inline images | Not in tmux panes reliably |
| Copy code blocks | Select + copy | No "click to copy" buttons |

#### The Real Problem: TUI Frameworks

To build a TUI-based agent, we'd use:
- **Ink** (React for CLI) - JavaScript
- **Bubble Tea** (Go)
- **Ratatui** (Rust)
- **opentui** (SolidJS) - what OpenCode uses

All of these have the same fundamental constraints:
- Character grid rendering
- Box-drawing borders only
- No CSS-style layouts
- Limited mouse interaction

**Building our own agent as a TUI means inheriting all of OpenCode's limitations.**

#### What We Actually Want

| Feature | TUI Reality | Native App Reality |
|---------|-------------|-------------------|
| Collapsible sections | Redraw entire screen | CSS `display: none` |
| Smooth scrolling | Jump by lines | Pixel-perfect scroll |
| Search in conversation | Complex state management | Browser `Ctrl+F` or custom |
| Markdown rendering | Limited libraries | Full CommonMark + extensions |
| Code blocks | Monospace box | Syntax highlighting + copy button |
| Inline buttons | Not possible | Full interactivity |
| Split view (code + diff) | Nested panes | Flexbox layout |
| Resizable panels | Fixed splits | Drag handles |

### Verdict

Building a custom AI agent as a TUI provides no advantage over forking OpenCode. A native/web app gives us:
- Full control over rendering
- Modern UI patterns (accordions, tabs, modals)
- Proper state management (React/Solid)
- Easy theming with CSS variables

---

## Feature 2: Git/File Management Sidebar

### Vision

A sidebar showing:
- File tree with git status indicators
- Staged/unstaged changes
- Commit history
- Branch management
- Quick actions (stage, commit, push)

### Terminal Stack Limitations

#### Layout Constraints

```
Current: tmux panes are rectangular splits

┌─────────────────────────────────────────┐
│                                         │
│              Main Pane                  │
│                                         │
├─────────────────────────────────────────┤
│           Status Bar                    │
└─────────────────────────────────────────┘

What we want: Persistent sidebar that doesn't resize with panes

┌──────────┬──────────────────────────────┐
│          │                              │
│  Sidebar │         Main Pane            │
│  (fixed) │         (flexible)           │
│          │                              │
│          ├──────────────────────────────┤
│          │         Status Bar           │
└──────────┴──────────────────────────────┘
```

**tmux cannot do this.** Sidebars would be regular panes that:
- Resize when other panes resize
- Can be accidentally closed
- Compete for the same split logic
- Have no "pinned" concept

#### File Tree Rendering

| Feature | Terminal Capability | Limitation |
|---------|---------------------|------------|
| Tree structure | ASCII (`├── └──`) | Works, but ugly |
| Git status colors | ANSI colors | Limited palette |
| File icons | Unicode/Nerd Fonts | Font dependency |
| Expand/collapse | Redraw tree | No animation, jarring |
| Click to open | Possible with mouse | But file opens in new pane? |
| Drag to move | Not possible | No drag events in tmux |
| Right-click menu | tmux menu | Limited, modal |
| Search/filter | Text input | No fuzzy dropdown |
| Hover preview | Not possible | No hover events |

#### The Pane Problem

If we build a file tree as a tmux pane:
- Where do files open? New pane? Popup? Replace tree?
- How do we maintain the tree state across pane operations?
- How do we prevent the tree from being closed?
- How do we sync the tree with the active pane's directory?

**None of these have clean solutions in tmux.**

#### Git Operations

| Operation | Terminal Approach | Problem |
|-----------|-------------------|---------|
| Stage file | Run `git add` | Need to refresh tree |
| View diff | Run `git diff` in pane | Separate pane, context switch |
| Commit | Interactive or command | Modal input is clunky |
| Push | Run `git push` | Output goes where? |
| Conflict resolution | External tool | Leaves our environment |

### What We Actually Want

A proper git sidebar needs:
- **Persistent panel** that survives pane operations
- **Click handlers** on every file/line
- **Inline diff preview** on hover or click
- **Staged changes section** with drag-to-stage
- **Commit message input** with preview
- **Branch dropdown** with search
- **Conflict markers** with resolve buttons

**None of this is achievable in a terminal UI without heroic effort.**

### Verdict

A git/file sidebar requires a native app where:
- Sidebar is a separate component, not a pane
- File tree is a proper tree widget
- Git operations have inline feedback
- State syncs automatically with filesystem

---

## Feature 3: Session/Agent Management Sidebar

### Vision

A sidebar showing:
- Active AI sessions (OpenCode, Claude, custom agents)
- Session history and conversations
- Agent status (thinking, idle, waiting)
- Token usage and costs
- Quick session switching
- Session linking (same project) or isolation

### Terminal Stack Limitations

#### What is a "Session"?

In terminal land:
- tmux session = named collection of windows/panes
- AI agent session = conversation state (stored by agent)
- Shell session = environment variables, history

**These are three different things with no unifying concept.**

#### Multi-Agent Orchestration

| Requirement | Terminal Capability | Limitation |
|-------------|---------------------|------------|
| Multiple agents running | Multiple panes | Each is isolated |
| Shared context | File system only | No IPC between agents |
| Status indicators | Poll process status | Hacky, delayed |
| Token counters | Parse agent output | Fragile, agent-specific |
| Session switching | tmux window switch | Loses scroll position |
| Conversation history | Agent-managed | Different formats per agent |
| Kill/restart agent | Kill pane process | Loses all state |

#### The Linking Problem

"Link panes to the same project" means:
- Pane A (shell) is in `/project-a`
- Pane B (opencode) is working on `/project-a`
- Pane C (shell) is in `/project-b`
- Pane D (claude) is working on `/project-b`

**How do we know which panes are linked?**

tmux has no concept of this. We'd have to:
1. Track pane → project mapping ourselves
2. Store in external file or tmux environment
3. Update on every directory change
4. Handle edge cases (pane changes directory)

This is **extremely fragile**.

#### Session Persistence

| Requirement | Terminal Capability | Limitation |
|-------------|---------------------|------------|
| Save session state | tmux-resurrect plugin | Panes only, not agent state |
| Restore AI conversation | Agent must support | Different per agent |
| Resume mid-task | Agent must support | Often not possible |
| Cross-device sync | Manual | No built-in solution |

### What We Actually Want

```
┌─────────────────────────────────────────────────────────────┐
│  Sessions                                          [+] [-]  │
├─────────────────────────────────────────────────────────────┤
│  ▼ Project: clickterm                                       │
│    ├─ 🤖 OpenCode (active, 12.4k tokens)                   │
│    │     └─ "Analyzing NATIVE-APP-RATIONALE.md..."         │
│    ├─ 📁 Shell: ~/Developers/clickterm                     │
│    └─ 🔗 Linked: 2 panes                                   │
│                                                             │
│  ▶ Project: my-saas-app (collapsed)                        │
│                                                             │
│  ─────────────────────────────────────────────────────────  │
│  Unlinked Panes                                             │
│    └─ 📁 Shell: ~/Downloads                                │
└─────────────────────────────────────────────────────────────┘
```

This requires:
- **Project/session abstraction** above tmux
- **Agent communication protocol** for status
- **Persistent state management** across restarts
- **Visual hierarchy** with collapse/expand

**All impossible in terminal UI without building a full application layer.**

### Verdict

Session management is fundamentally an **application-level concern** that tmux wasn't designed for. We need:
- Custom data model for sessions
- Database or file-based persistence
- IPC with AI agents
- Native UI for visualization

---

## Feature 4: Enhanced Pane Functionality

### Vision

Panes that can:
- Preview files (markdown, images, PDFs)
- Show live diffs during AI rewrites
- Run dev servers with hot reload
- Display test results inline
- Link to related panes (code ↔ preview)

### 4A: File Preview Pane

#### What We Want

Click a file → see preview:
- Markdown renders as HTML
- Images display inline
- Code has syntax highlighting
- PDFs are viewable
- Preview updates on file save

#### Terminal Limitations

| File Type | Terminal Capability | Quality |
|-----------|---------------------|---------|
| Markdown | `glow`, `mdcat` | Okay, no CSS |
| Images | iTerm2 inline images | Unreliable in tmux |
| PDFs | Not possible | Must use external app |
| Code | `bat`, `cat` | Good, but read-only |
| HTML | Text only | No rendering |
| SVG | Not possible | External app |

**The fundamental problem:** Terminals render text. Previewing rich content requires a graphical context.

iTerm2's inline images work, but:
- Broken in tmux without special config
- Fixed size, no zoom
- No interaction (can't click links in image)

### 4B: Live Diff During AI Rewrite

#### What We Want

While AI is editing a file:
- See the diff in real-time
- Unified or split view
- Accept/reject individual hunks
- Syntax highlighting preserved

#### Terminal Limitations

| Feature | Terminal Capability | Problem |
|---------|---------------------|---------|
| Real-time updates | Possible | Agent must stream diffs |
| Split view | Two panes | Manual setup, no sync scroll |
| Unified diff | `delta`, `diff-so-fancy` | Static, not interactive |
| Hunk accept/reject | Not built-in | Would need custom TUI |
| Syntax highlighting | In diff tools | But not interactive |

**OpenCode shows diffs**, but:
- After the fact, not during
- No partial accept/reject
- Requires their specific UI

Building our own diff viewer as TUI means reimplementing OpenCode's work.

### 4C: Dev Server with Hot Reload

#### What We Want

Run `npm run dev` in a pane, and:
- See server status (starting, ready, error)
- Click to open browser preview
- Errors highlighted and clickable
- Auto-restart on crash
- Link to code pane (click error → jump to file)

#### Terminal Limitations

| Feature | Terminal Capability | Problem |
|---------|---------------------|---------|
| Run dev server | Just run command | Works |
| Parse output | Regex on stream | Fragile, per-framework |
| Status indicator | Parse "ready" message | Fragile |
| Click to open browser | `open` command | Manual or script |
| Clickable errors | iTerm2 semantic prompts | Limited, setup required |
| Link to code pane | Not possible | No pane-to-pane IPC |
| Auto-restart | Wrapper script | More moving parts |

**The real limitation:** Dev servers are just processes. Making them "smart" requires wrapping them in our own tooling that:
- Parses their output
- Maintains state
- Provides UI feedback

This is a **monitoring application**, not a terminal feature.

### 4D: Test Results Inline

#### What We Want

Run tests and:
- See pass/fail summary
- Expand failing tests for details
- Click to jump to test file
- Re-run individual tests
- See coverage inline

#### Terminal Limitations

| Feature | Terminal Capability | Problem |
|---------|---------------------|---------|
| Run tests | Just run command | Works |
| Parse results | Regex or TAP/JUnit | Fragile, format-dependent |
| Collapsible results | TUI required | Would need custom viewer |
| Click to file | iTerm2 or TUI | Limited |
| Re-run single test | Command with args | UI for selection? |
| Coverage display | External tool | Separate report |

**Test runners output text.** Making that text interactive requires building a test result viewer application.

### Verdict

Enhanced pane functionality fundamentally requires:
- **Rich content rendering** (not just text)
- **Bidirectional communication** with processes
- **Structured data** (not text parsing)
- **Interactive UI** (buttons, clickable elements)

Terminals are text pipes. We need an application layer.

---

## Feature 5: Project/Session Linking

### Vision

- Panes can be "linked" to a project
- Linked panes share context (directory, git state, env vars)
- Sessions can span multiple projects
- Unlinked panes are isolated
- Visual indicator of link status

### Terminal Stack Limitations

#### No Concept of "Project"

tmux knows about:
- Sessions (named)
- Windows (tabs within session)
- Panes (splits within window)

tmux does NOT know about:
- Projects
- Git repositories
- Working directories (per-pane, but not enforced)
- Relationships between panes

**We'd have to build this abstraction entirely ourselves.**

#### Implementation Attempt

```bash
# Store project mapping in tmux environment
tmux set-environment -t $PANE_ID PROJECT "/path/to/project"

# Query linked panes
for pane in $(tmux list-panes -F '#{pane_id}'); do
    project=$(tmux show-environment -t $pane PROJECT 2>/dev/null)
    # ... build mapping
done
```

**Problems:**
1. Must update on every `cd`
2. Hook into shell is fragile (PROMPT_COMMAND, precmd)
3. External processes don't trigger hooks
4. AI agents change directories internally
5. Subshells inherit but don't update
6. tmux environment isn't reactive

#### Visual Indicators

How do we show link status?

| Approach | Limitation |
|----------|------------|
| Pane border color | Only 1 color at a time |
| Pane title | Requires manual setting |
| Status bar | Global, not per-pane |
| Popup on hover | No hover events |

**There's no good way to visually indicate pane relationships in tmux.**

### What We Actually Want

```
┌─ Project: clickterm ─────────────────────────────────────────┐
│ ┌─────────────────────────┐ ┌─────────────────────────────┐ │
│ │ 🔗 Shell                │ │ 🔗 OpenCode                 │ │
│ │ ~/Dev/clickterm         │ │ Context: clickterm          │ │
│ │                         │ │                             │ │
│ └─────────────────────────┘ └─────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘

┌─ Unlinked ───────────────────────────────────────────────────┐
│ ┌─────────────────────────┐                                  │
│ │ 📁 Shell                │                                  │
│ │ ~/Downloads             │                                  │
│ └─────────────────────────┘                                  │
└──────────────────────────────────────────────────────────────┘
```

This requires:
- **Project as first-class entity**
- **Pane grouping** that survives splits
- **Visual containers** (not just borders)
- **Header/chrome** per group
- **Drag-and-drop** to relink

**None of this exists in tmux.**

### Verdict

Project linking requires an application layer that:
- Defines what a "project" is
- Tracks pane membership
- Enforces directory consistency
- Provides visual grouping
- Persists across restarts

---

## Synthesis: What We're Really Building

Looking at all five features, we're not enhancing a terminal—we're building an **IDE**.

| Feature | What It Really Is |
|---------|-------------------|
| Custom AI agent | IDE plugin with AI integration |
| Git sidebar | Source control panel |
| Session manager | Workspace/project manager |
| File preview | Editor preview pane |
| Live reload | Integrated dev server |
| Project linking | Workspace concept |

### The IDE We Want

```
┌─────────────────────────────────────────────────────────────────────────┐
│  clickterm                                              [−] [□] [×]     │
├─────────────────────────────────────────────────────────────────────────┤
│  │ File │ Edit │ View │ Project │ AI │ Help │                          │
├──┼──────────────────────────────────────────────────────────────────────┤
│  │                                                                      │
│  │  ┌─ Git ─────────────┐  ┌─ Terminal ──────────────────────────────┐ │
│  │  │ ▼ Changes (3)     │  │ ~/Dev/clickterm $ npm run dev           │ │
│  │  │   M src/app.ts    │  │ Server running on http://localhost:3000 │ │
│  │  │   M README.md     │  │                                         │ │
│S │  │   A new-file.ts   │  ├─────────────────────────────────────────┤ │
│I │  ├───────────────────┤  │ ~/Dev/clickterm $                       │ │
│D │  │ ▶ Staged (1)      │  │                                         │ │
│E │  ├───────────────────┤  └─────────────────────────────────────────┘ │
│B │  │ ▶ Branches        │                                              │
│A │  └───────────────────┘  ┌─ AI Agent ──────────────────────────────┐ │
│R │                         │ 🤖 Working on: "Add user auth..."       │ │
│  │  ┌─ Sessions ────────┐  │                                         │ │
│  │  │ ● clickterm       │  │ [Thinking...] ████████░░ 80%            │ │
│  │  │   ├─ Terminal ×2  │  │                                         │ │
│  │  │   └─ AI Agent ×1  │  │ Last action: Modified src/auth.ts       │ │
│  │  │ ○ other-project   │  │ Tokens: 12,432 / Cost: $0.24            │ │
│  │  └───────────────────┘  └─────────────────────────────────────────┘ │
├──┴──────────────────────────────────────────────────────────────────────┤
│  [│ Split] [─ Stack] [× Close] [⎋ Exit]  │ Project: clickterm │ 3 panes │
└─────────────────────────────────────────────────────────────────────────┘
```

### Why Terminal Stack Can't Do This

| IDE Concept | Terminal Equivalent | Why It Fails |
|-------------|---------------------|--------------|
| Sidebar | Pane | Resizes, can close, no persistence |
| Panel | Pane | Same problems |
| Tab bar | tmux windows | No custom rendering |
| Status bar | tmux status | One line, limited |
| Tree widget | TUI tree | No click, no drag |
| Preview pane | Pane with viewer | Text only |
| Integrated terminal | It IS the terminal | Can't layer on top |

**The terminal is a component of an IDE, not the container for one.**

---

## Recommended Architecture for Advanced Features

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        Tauri Application                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    UI Layer (SolidJS)                     │   │
│  │                                                           │   │
│  │  ┌─────────────┐  ┌────────────────────────────────────┐ │   │
│  │  │  Sidebar    │  │         Main Area                   │ │   │
│  │  │  Component  │  │  ┌──────────────────────────────┐  │ │   │
│  │  │             │  │  │     Terminal Component       │  │ │   │
│  │  │  - Git      │  │  │     (xterm.js + PTY)         │  │ │   │
│  │  │  - Files    │  │  └──────────────────────────────┘  │ │   │
│  │  │  - Sessions │  │  ┌──────────────────────────────┐  │ │   │
│  │  │             │  │  │     AI Agent Component       │  │ │   │
│  │  │             │  │  │     (custom, not OpenCode)   │  │ │   │
│  │  └─────────────┘  │  └──────────────────────────────┘  │ │   │
│  │                    └────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                      Backend Layer (Rust)                        │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ PTY Manager  │  │ Git Service  │  │ Project/Session DB   │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ File Watcher │  │ AI Agent IPC │  │ Dev Server Manager   │   │
│  └──────────────┘  └──────────────┘  └──────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Data Model

```typescript
interface Project {
  id: string;
  name: string;
  path: string;
  gitRepo?: GitRepository;
  sessions: Session[];
}

interface Session {
  id: string;
  projectId: string;
  panes: Pane[];
  agents: AgentInstance[];
  createdAt: Date;
  lastActiveAt: Date;
}

interface Pane {
  id: string;
  sessionId: string;
  type: 'terminal' | 'preview' | 'agent' | 'custom';
  pty?: PtyHandle;
  workingDirectory: string;
  linkedPanes: string[]; // IDs of related panes
}

interface AgentInstance {
  id: string;
  sessionId: string;
  type: 'opencode' | 'claude' | 'custom';
  status: 'idle' | 'thinking' | 'acting' | 'waiting';
  tokenUsage: number;
  conversationId: string;
}
```

### Key Capabilities Unlocked

| Feature | Implementation |
|---------|----------------|
| Persistent sidebar | Native component, not a pane |
| Git integration | Rust `git2` library, custom UI |
| Session management | SQLite database, reactive UI |
| File preview | WebView with marked.js, etc. |
| Live diff | Virtual DOM diffing, highlight.js |
| Dev server | PTY + output parser + status UI |
| Project linking | First-class data model |
| Agent orchestration | IPC protocol, shared context |

---

## Migration Path

### Phase 1: Foundation
- Set up Tauri + SolidJS project
- Implement basic PTY terminal
- Single-pane, no splitting yet
- Theme system with CSS variables

### Phase 2: Pane Management
- Split/stack panes (replicate tmux)
- Drag-to-resize
- Pane close with protection
- Status bar with buttons

### Phase 3: Sidebars
- File tree sidebar
- Basic git status
- Collapsible panels

### Phase 4: Sessions
- Project concept
- Session persistence
- Pane linking

### Phase 5: AI Integration
- Agent pane type
- Custom agent implementation
- Or: embed OpenCode web UI

### Phase 6: Advanced Features
- Live preview
- Dev server integration
- Test result viewer
- Cross-pane linking

---

## Conclusion

Every advanced feature we want requires:

1. **Structured data** (not text streams)
2. **Persistent state** (not tmux environment hacks)
3. **Rich UI components** (not character grids)
4. **Inter-component communication** (not shell pipes)
5. **Application-level abstractions** (projects, sessions, agents)

The terminal stack was designed for running programs and viewing their output. We're trying to build an integrated development environment.

**clickterm as a tmux wrapper was the right proof-of-concept. clickterm as a native app is the right product.**
