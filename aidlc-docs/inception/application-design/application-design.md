# Application Design — Consolidated

## Architecture Overview

BoxCommands is restructured from 4 loosely-coupled files into a modular system organized by concern:

```text
BoxCommands/
├── boxcommands.lua          # Entry point (root — Windower requirement)
├── ui/                      # Visual rendering (class-based, minimal footprint)
├── commands/                # Command parsing and execution
├── algorithms/              # Spell selection logic (healing, nuking)
├── data/                    # Static game data tables
└── core/                    # Shared infrastructure (settings, state, IPC, timers, events)
```

### Design Principles
- **No hardcoded character data** — all configuration in settings.xml
- **No circular dependencies** — data/ and core/ at the bottom, commands/ and ui/ at the top
- **Minimal UI footprint** — compact, legible, class-based but simple
- **Settings as shared state** — job/HP data synchronized via filesystem (no IPC needed)
- **One entry point in root** — Windower loads `boxcommands.lua` from addon directory root

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| File organization | Feature subdirectories + root entry point | Windower requires root Lua; subdirectories keep concerns separated |
| Job/HP sharing | Settings file (no IPC) | All boxes read/write same settings.xml; simpler than broadcast protocol |
| Static game data | Separate files per system + generics | Keeps focused; generics.lua for shared cross-module tables |
| UI architecture | Class-based (ui_element base) | Needed for animation, visibility management, menu-hiding complexity |
| UI density | Compact — bars close together, minimal real estate | User needs to see the game screen |
| Menu detection | Windower events → packet reading fallback → 60s safety timer | Prioritize non-packet approach; safety net prevents UI disappearing |
| Stat capture | get_player() during midcast, cached per job+category | "One cast behind" is acceptable; captures total stats including gear |
| Potency overrides | Optional fields in settings | Opt-in tuning for users who want precision |

## Component Summary

| Component | Files | Purpose |
|-----------|-------|---------|
| Entry Point | boxcommands.lua | Addon registration, event wiring, setup |
| Core | core/*.lua (5 files) | Settings, state, IPC, timers, events |
| Commands | commands/*.lua (3 files) | Routing, casting, targeting |
| Algorithms | algorithms/*.lua (3 files) | Healing selection, nuking selection, shared utilities |
| UI | ui/*.lua (7 files) | Headers, bars, arrows, text, images, manager, base class |
| Data | data/*.lua (7 files) | Elements, pacts, healing/nuking formulas, tools, generics, undead |

**Total new file count**: ~25 Lua files (up from 4)

## Cross-Cutting Concerns

### Settings Synchronization
- All boxes in the same Windower installation share one settings.xml
- Each box writes its own character section (job, max HP) on job change
- Short delay after job change for gear to stabilize before HP capture
- `//box setup` forces immediate refresh

### IPC (Inter-Process Communication)
- Used for: command relay (cast/ja/pet), timer broadcasting, caster/target setting
- NOT used for: job sharing, HP sharing (handled by settings file)
- Pattern: check if local player is caster → if yes, execute locally; if no, relay via `send`

### Timer System
- Timers created on caster's box after recast is retrieved
- Broadcast to all boxes via `send @all box timerui`
- Each box independently renders and ticks down its timers
- Column layout based on settings-file character order + party presence

### Alliance Support (FR-10)
- All systems (UI, commands, targeting, IPC) extend naturally to 18 characters
- UI adds rows for party 2 and party 3 below party 1
- Caster/target can be any alliance member
- Keybind system adapts for >6 characters

## See Also
- [components.md](components.md) — Detailed component definitions
- [component-methods.md](component-methods.md) — Method signatures per component
- [services.md](services.md) — Service orchestration and IPC protocol
- [component-dependency.md](component-dependency.md) — Dependency matrix and data flow
