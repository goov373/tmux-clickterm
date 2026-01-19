# clickterm v2: Architecture Recommendations

> Technical blueprint for rebuilding clickterm as a native application

## Overview

This document provides concrete architectural recommendations for building clickterm v2—a modern, native development environment that preserves the "click, don't memorize" philosophy while overcoming the terminal stack limitations documented in:

- `01-TERMINAL-STACK-LIMITATIONS.md` - Core visual/theming constraints
- `02-ADVANCED-FEATURES-LIMITATIONS.md` - Feature-specific analysis

---

## Recommended Stack

### Primary Recommendation: Tauri + SolidJS

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Shell** | Tauri 2.0 | Rust backend, ~5MB bundle, native performance |
| **UI Framework** | SolidJS | Fine-grained reactivity, fast, familiar JSX |
| **Terminal** | xterm.js + WebGL | Industry standard, GPU-accelerated |
| **PTY** | Rust `portable-pty` | Cross-platform, async |
| **Styling** | Tailwind CSS | Utility-first, easy theming |
| **State** | Solid stores + SQLite | Reactive UI + persistent storage |
| **Git** | `git2` (libgit2 bindings) | Native performance, no CLI parsing |
| **IPC** | Tauri commands + events | Type-safe, bidirectional |

### Why Not Electron?

| Factor | Electron | Tauri |
|--------|----------|-------|
| Bundle size | ~150MB | ~5MB |
| Memory baseline | ~100MB | ~30MB |
| Startup time | 1-2s | <500ms |
| Native APIs | Via Node | Native Rust |
| Security model | Node access | Capability-based |

### Why SolidJS Over React?

| Factor | React | SolidJS |
|--------|-------|---------|
| Bundle size | ~40KB | ~7KB |
| Reactivity | Virtual DOM diffing | Fine-grained signals |
| Terminal perf | Re-renders on updates | Surgical updates |
| Learning curve | Familiar | Similar JSX |
| OpenCode uses | No | Yes (easier to borrow patterns) |

---

## Application Architecture

### High-Level Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Tauri Shell                                 │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                         Rust Backend                               │  │
│  │                                                                    │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │  │
│  │  │ PTY Manager  │  │ Git Service  │  │ Project/Session Store    │ │  │
│  │  │              │  │              │  │ (SQLite)                 │ │  │
│  │  │ - spawn      │  │ - status     │  │                          │ │  │
│  │  │ - resize     │  │ - stage      │  │ - projects               │ │  │
│  │  │ - write      │  │ - commit     │  │ - sessions               │ │  │
│  │  │ - read       │  │ - branch     │  │ - pane configs           │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │  │
│  │                                                                    │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │  │
│  │  │ File Watcher │  │ AI Agent     │  │ Dev Server Manager       │ │  │
│  │  │ (notify-rs)  │  │ Bridge       │  │                          │ │  │
│  │  │              │  │              │  │ - process spawn          │ │  │
│  │  │ - changes    │  │ - spawn      │  │ - output parsing         │ │  │
│  │  │ - debounce   │  │ - status     │  │ - restart logic          │ │  │
│  │  │ - filter     │  │ - tokens     │  │ - port management        │ │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                    │                                     │
│                          Tauri IPC │ (commands + events)                 │
│                                    ▼                                     │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                       SolidJS Frontend                             │  │
│  │                                                                    │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │                      App Shell                               │  │  │
│  │  │  ┌─────────┐  ┌───────────────────────────────────────────┐ │  │  │
│  │  │  │ Sidebar │  │              Main Area                     │ │  │  │
│  │  │  │         │  │  ┌─────────────────────────────────────┐  │ │  │  │
│  │  │  │ - Files │  │  │          Pane Container             │  │ │  │  │
│  │  │  │ - Git   │  │  │  ┌───────────┐  ┌───────────────┐   │  │ │  │  │
│  │  │  │ - Sess. │  │  │  │ Terminal  │  │ Terminal      │   │  │ │  │  │
│  │  │  │         │  │  │  │ Pane      │  │ Pane          │   │  │ │  │  │
│  │  │  │         │  │  │  └───────────┘  └───────────────┘   │  │ │  │  │
│  │  │  │         │  │  │  ┌─────────────────────────────────┐│  │ │  │  │
│  │  │  │         │  │  │  │ AI Agent Pane                   ││  │ │  │  │
│  │  │  │         │  │  │  └─────────────────────────────────┘│  │ │  │  │
│  │  │  │         │  │  └─────────────────────────────────────┘  │ │  │  │
│  │  │  └─────────┘  └───────────────────────────────────────────┘ │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐│  │  │
│  │  │  │                    Status Bar                           ││  │  │
│  │  │  └─────────────────────────────────────────────────────────┘│  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Data Model

### Core Entities

```typescript
// Project: A git repository or directory
interface Project {
  id: string;
  name: string;
  path: string;
  gitRemote?: string;
  createdAt: Date;
  lastOpenedAt: Date;
  settings: ProjectSettings;
}

interface ProjectSettings {
  defaultShell: string;
  env: Record<string, string>;
  devServerCommand?: string;
  testCommand?: string;
}

// Session: A workspace within a project
interface Session {
  id: string;
  projectId: string;
  name: string;
  layout: PaneLayout;
  createdAt: Date;
  lastActiveAt: Date;
}

// PaneLayout: Recursive split structure
type PaneLayout = 
  | { type: 'pane'; paneId: string }
  | { type: 'split'; direction: 'horizontal' | 'vertical'; children: PaneLayout[]; sizes: number[] };

// Pane: A single terminal, preview, or agent view
interface Pane {
  id: string;
  sessionId: string;
  type: PaneType;
  title?: string;
  workingDirectory: string;
  // Type-specific data
  terminal?: TerminalPaneData;
  preview?: PreviewPaneData;
  agent?: AgentPaneData;
}

type PaneType = 'terminal' | 'preview' | 'agent' | 'diff' | 'test-results';

interface TerminalPaneData {
  ptyId: string;
  shell: string;
  scrollback: number;
}

interface PreviewPaneData {
  filePath: string;
  renderer: 'markdown' | 'image' | 'code' | 'html';
}

interface AgentPaneData {
  agentType: 'builtin' | 'opencode' | 'claude';
  conversationId: string;
  status: AgentStatus;
  tokenUsage: number;
  costUsd: number;
}

type AgentStatus = 'idle' | 'thinking' | 'acting' | 'waiting-input' | 'error';
```

### Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| Projects | SQLite | Queryable, persistent |
| Sessions | SQLite | Persist across restarts |
| Pane layouts | SQLite (JSON column) | Flexible structure |
| Git state | Live queries | Always fresh |
| Terminal scrollback | File-backed ring buffer | Large, ephemeral |
| Conversation history | SQLite + files | Searchable + large content |
| Theme/settings | JSON file | User-editable |

---

## Component Architecture

### Frontend Components

```
src/
├── components/
│   ├── app/
│   │   ├── App.tsx                 # Root component
│   │   ├── Titlebar.tsx            # Custom window controls
│   │   └── StatusBar.tsx           # Bottom bar with buttons
│   │
│   ├── sidebar/
│   │   ├── Sidebar.tsx             # Container with tabs
│   │   ├── FileTree.tsx            # File explorer
│   │   ├── GitPanel.tsx            # Git status/actions
│   │   └── SessionList.tsx         # Project/session manager
│   │
│   ├── panes/
│   │   ├── PaneContainer.tsx       # Manages splits/layout
│   │   ├── PaneChrome.tsx          # Title bar, controls per pane
│   │   ├── TerminalPane.tsx        # xterm.js wrapper
│   │   ├── PreviewPane.tsx         # File preview
│   │   ├── AgentPane.tsx           # AI agent UI
│   │   ├── DiffPane.tsx            # Live diff viewer
│   │   └── TestResultsPane.tsx     # Test output viewer
│   │
│   ├── agent/
│   │   ├── AgentChat.tsx           # Conversation view
│   │   ├── AgentToolCall.tsx       # Tool execution display
│   │   ├── AgentDiff.tsx           # File change preview
│   │   └── AgentStatus.tsx         # Status indicator
│   │
│   └── shared/
│       ├── Button.tsx
│       ├── Dropdown.tsx
│       ├── Modal.tsx
│       ├── Tree.tsx
│       └── Tooltip.tsx
│
├── stores/
│   ├── project.ts                  # Project state
│   ├── session.ts                  # Session/pane state
│   ├── git.ts                      # Git state
│   ├── terminal.ts                 # PTY connections
│   ├── agent.ts                    # AI agent state
│   └── theme.ts                    # Theme/settings
│
├── hooks/
│   ├── useTerminal.ts              # xterm.js integration
│   ├── usePty.ts                   # Tauri PTY bridge
│   ├── useGit.ts                   # Git operations
│   ├── useAgent.ts                 # AI agent interaction
│   └── useHotkey.ts                # Keyboard shortcuts
│
└── lib/
    ├── tauri.ts                    # Tauri command wrappers
    ├── theme.ts                    # Theme utilities
    └── keybindings.ts              # Keymap definitions
```

### Backend Services (Rust)

```
src-tauri/
├── src/
│   ├── main.rs                     # Tauri entry point
│   │
│   ├── commands/
│   │   ├── mod.rs
│   │   ├── pty.rs                  # PTY commands
│   │   ├── git.rs                  # Git commands
│   │   ├── project.rs              # Project CRUD
│   │   ├── session.rs              # Session CRUD
│   │   ├── fs.rs                   # File operations
│   │   └── agent.rs                # Agent management
│   │
│   ├── services/
│   │   ├── mod.rs
│   │   ├── pty_manager.rs          # PTY lifecycle
│   │   ├── git_service.rs          # Git operations
│   │   ├── file_watcher.rs         # FS change detection
│   │   ├── project_store.rs        # SQLite for projects
│   │   └── agent_bridge.rs         # AI agent IPC
│   │
│   └── models/
│       ├── mod.rs
│       ├── project.rs
│       ├── session.rs
│       └── pane.rs
│
├── Cargo.toml
└── tauri.conf.json
```

---

## Key Implementation Details

### Terminal Rendering

```typescript
// TerminalPane.tsx
import { Terminal } from 'xterm';
import { WebglAddon } from 'xterm-addon-webgl';
import { FitAddon } from 'xterm-addon-fit';

export function TerminalPane(props: { paneId: string }) {
  let terminalRef: HTMLDivElement;
  const [terminal, setTerminal] = createSignal<Terminal>();
  
  onMount(async () => {
    const term = new Terminal({
      fontFamily: 'JetBrains Mono, monospace',
      fontSize: 14,
      theme: getTerminalTheme(), // From our theme system
      cursorBlink: true,
      cursorStyle: 'block',
    });
    
    term.loadAddon(new WebglAddon());
    term.loadAddon(new FitAddon());
    term.open(terminalRef);
    
    // Connect to Rust PTY
    const ptyId = await invoke('pty_spawn', { 
      paneId: props.paneId,
      shell: '/bin/zsh',
      cwd: await getWorkingDirectory(props.paneId),
    });
    
    // Bidirectional data flow
    term.onData((data) => invoke('pty_write', { ptyId, data }));
    await listen(`pty_output_${ptyId}`, (event) => term.write(event.payload));
    
    setTerminal(term);
  });
  
  return (
    <div 
      ref={terminalRef!} 
      class="terminal-container rounded-lg overflow-hidden shadow-lg"
    />
  );
}
```

### Pane Layout System

```typescript
// PaneContainer.tsx
export function PaneContainer(props: { layout: PaneLayout }) {
  return (
    <Switch>
      <Match when={props.layout.type === 'pane'}>
        <PaneWrapper paneId={(props.layout as any).paneId} />
      </Match>
      <Match when={props.layout.type === 'split'}>
        <SplitContainer layout={props.layout as SplitLayout} />
      </Match>
    </Switch>
  );
}

function SplitContainer(props: { layout: SplitLayout }) {
  const [sizes, setSizes] = createSignal(props.layout.sizes);
  
  return (
    <div class={`flex ${props.layout.direction === 'horizontal' ? 'flex-row' : 'flex-col'} h-full`}>
      <For each={props.layout.children}>
        {(child, index) => (
          <>
            <div style={{ flex: sizes()[index()] }}>
              <PaneContainer layout={child} />
            </div>
            {index() < props.layout.children.length - 1 && (
              <ResizeHandle 
                direction={props.layout.direction}
                onResize={(delta) => handleResize(index(), delta)}
              />
            )}
          </>
        )}
      </For>
    </div>
  );
}
```

### Theme System

```typescript
// theme.ts
export interface Theme {
  name: string;
  colors: {
    // Backgrounds
    bgBase: string;
    bgPanel: string;
    bgElement: string;
    bgHover: string;
    bgActive: string;
    
    // Text
    textPrimary: string;
    textMuted: string;
    textBright: string;
    
    // Accents
    accent: string;
    accentHover: string;
    
    // Semantic
    error: string;
    warning: string;
    success: string;
    info: string;
    
    // Borders
    border: string;
    borderActive: string;
    
    // Terminal (ANSI)
    ansi: {
      black: string;
      red: string;
      green: string;
      yellow: string;
      blue: string;
      magenta: string;
      cyan: string;
      white: string;
      // ... bright variants
    };
  };
  
  // Design tokens
  borderRadius: {
    sm: string;
    md: string;
    lg: string;
  };
  
  shadows: {
    sm: string;
    md: string;
    lg: string;
    paneActive: string;
  };
}

// Single source generates:
// 1. CSS variables for UI
// 2. xterm.js theme object
// 3. Tailwind config
export function applyTheme(theme: Theme) {
  const root = document.documentElement;
  Object.entries(flattenTheme(theme)).forEach(([key, value]) => {
    root.style.setProperty(`--${key}`, value);
  });
}
```

### Git Integration

```rust
// git_service.rs
use git2::{Repository, StatusOptions};

#[tauri::command]
pub async fn git_status(path: String) -> Result<GitStatus, String> {
    let repo = Repository::open(&path).map_err(|e| e.to_string())?;
    
    let mut opts = StatusOptions::new();
    opts.include_untracked(true);
    
    let statuses = repo.statuses(Some(&mut opts)).map_err(|e| e.to_string())?;
    
    let mut result = GitStatus::default();
    
    for entry in statuses.iter() {
        let status = entry.status();
        let path = entry.path().unwrap_or("").to_string();
        
        if status.is_wt_new() {
            result.untracked.push(path);
        } else if status.is_wt_modified() {
            result.modified.push(path);
        } else if status.is_index_new() || status.is_index_modified() {
            result.staged.push(path);
        }
    }
    
    Ok(result)
}

#[derive(Serialize, Default)]
pub struct GitStatus {
    pub staged: Vec<String>,
    pub modified: Vec<String>,
    pub untracked: Vec<String>,
    pub branch: Option<String>,
    pub ahead: u32,
    pub behind: u32,
}
```

---

## Development Phases

### Phase 1: Foundation (2-3 weeks)

**Goal:** Basic app shell with single terminal pane

- [ ] Tauri + SolidJS project setup
- [ ] Basic window with titlebar
- [ ] Single terminal pane with xterm.js
- [ ] PTY integration (spawn shell, I/O)
- [ ] Theme system with CSS variables
- [ ] Nord dark theme implementation

**Deliverable:** Working terminal app, equivalent to a basic terminal emulator

### Phase 2: Pane Management (2-3 weeks)

**Goal:** Replicate tmux pane functionality

- [ ] Split horizontal/vertical
- [ ] Drag-to-resize
- [ ] Pane close with confirmation
- [ ] Active pane indicator (shadow, border)
- [ ] Status bar with clickable buttons
- [ ] Keyboard shortcuts

**Deliverable:** Multi-pane terminal, feature parity with clickterm v1

### Phase 3: Sidebars (2-3 weeks)

**Goal:** File and git sidebars

- [ ] Collapsible sidebar container
- [ ] File tree component
- [ ] Click to open file in $EDITOR or preview
- [ ] Git status panel
- [ ] Stage/unstage files
- [ ] Commit with message input

**Deliverable:** Basic IDE-like experience

### Phase 4: Projects & Sessions (2 weeks)

**Goal:** Persistent workspace management

- [ ] SQLite integration
- [ ] Project CRUD
- [ ] Session save/restore
- [ ] Pane layout persistence
- [ ] Recent projects list
- [ ] Session switcher

**Deliverable:** Workspaces that survive restarts

### Phase 5: AI Integration (3-4 weeks)

**Goal:** Built-in AI agent

- [ ] Agent pane type
- [ ] Conversation UI
- [ ] Streaming responses
- [ ] Tool call visualization
- [ ] Diff preview for edits
- [ ] Accept/reject changes
- [ ] Token usage display

**Deliverable:** Integrated AI coding assistant

### Phase 6: Advanced Features (Ongoing)

**Goal:** Power-user features

- [ ] Preview pane (markdown, images)
- [ ] Live diff during AI edits
- [ ] Dev server integration
- [ ] Test result viewer
- [ ] Cross-pane linking
- [ ] Custom themes
- [ ] Plugin system

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| xterm.js performance issues | Low | High | WebGL addon, virtualized scrollback |
| PTY edge cases (signals, resize) | Medium | Medium | Use battle-tested `portable-pty` |
| Complex layout state | Medium | Medium | Solid stores + persistence |
| AI API changes | Medium | Low | Abstract provider interface |
| Theme consistency | Low | Medium | Single source of truth |
| Scope creep | High | High | Strict phase boundaries |

---

## Success Criteria

### v2.0 Release Requirements

- [ ] Feature parity with clickterm v1
- [ ] Persistent sessions
- [ ] File/git sidebar
- [ ] Built-in AI agent
- [ ] <500ms cold start
- [ ] <50MB memory baseline
- [ ] <10MB app bundle
- [ ] macOS 12+ support

### Quality Metrics

- [ ] 60fps pane resize
- [ ] <16ms input latency
- [ ] No dropped terminal output
- [ ] Graceful crash recovery
- [ ] Auto-update mechanism

---

## Conclusion

This architecture provides a clear path from clickterm's proof-of-concept to a production-ready native application. The Tauri + SolidJS + xterm.js stack delivers:

1. **Modern visuals** - Full CSS control
2. **Native performance** - Rust backend
3. **Small footprint** - ~5MB bundle
4. **Single theme system** - One source of truth
5. **Extensibility** - Plugin potential

The phased approach allows for incremental delivery while maintaining a working application at each stage.
