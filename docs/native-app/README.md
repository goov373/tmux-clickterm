# Native App Planning

Documentation for clickterm v2 - rebuilding as a native application.

## Documents

1. **[Terminal Stack Limitations](./01-TERMINAL-STACK-LIMITATIONS.md)**  
   Analysis of why tmux + iTerm2 + shell scripts cannot deliver modern UI/UX expectations.

2. **[Advanced Features Limitations](./02-ADVANCED-FEATURES-LIMITATIONS.md)**  
   Deep dive into specific features (sidebars, AI agents, session management) and why they require a native app.

3. **[Architecture Recommendations](./03-ARCHITECTURE-RECOMMENDATIONS.md)**  
   Technical blueprint: Tauri + SolidJS + xterm.js stack, component architecture, data models, and development phases.

## Summary

clickterm v1 proves the "click, don't memorize" concept works. clickterm v2 will deliver on the full vision with:

- Rounded corners, shadows, and modern styling
- Persistent sidebars (files, git, sessions)
- Built-in AI coding agent
- Project/session management
- Live preview and dev server integration

**Recommended stack:** Tauri 2.0 + SolidJS + xterm.js
