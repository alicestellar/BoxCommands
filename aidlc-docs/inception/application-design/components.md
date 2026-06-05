# Component Definitions

## Module Structure

```text
BoxCommands/
├── boxcommands.lua              # Entry point (root, required by Windower)
├── settings.xml                 # Auto-generated settings (Windower settings lib)
├── Graphics/                    # Image assets
│   ├── bar_bg.png
│   ├── bar_fg.png
│   └── arrow.png (or .ani)
├── ui/
│   ├── ui_element.lua           # Base UI element class (position, visibility, scale)
│   ├── ui_text.lua              # Text primitive wrapper (font, stroke, color)
│   ├── ui_image.lua             # Image primitive wrapper (size, path, animation)
│   ├── ui_bar.lua               # Timer bar (bg + fg + label)
│   ├── ui_header.lua            # Character header (background bar + name text + arrows)
│   ├── ui_manager.lua           # Top-level UI orchestrator (column layout, visibility, menu hiding)
│   └── ui_arrow.lua             # Animated arrow indicator (floating motion)
├── commands/
│   ├── router.lua               # Command dispatch (replaces if/elseif chain in boxcommands.lua)
│   ├── casting.lua              # Cast spell, job ability, pet commands, pact handling
│   └── targeting.lua            # Intelligent target resolution (FR-6)
├── algorithms/
│   ├── healing.lua              # Healing spell tier selection algorithm (FR-7)
│   ├── nuking.lua               # Nuking spell tier selection algorithm (FR-8)
│   └── spell_selection.lua      # Shared spell selection utilities (highest available, recast checks)
├── data/
│   ├── elements.lua             # Elemental relationships, storm/helix tables
│   ├── pacts.lua                # Summoner blood pact tables and durations
│   ├── healing_data.lua         # Cure base potencies, formulas, level caps
│   ├── nuking_data.lua          # Nuke damage formulas, skill caps, MP costs
│   ├── tools.lua                # Ninjutsu tool maps
│   ├── generics.lua             # Shared tables used by multiple modules (unify_prefix, addendum lists, etc.)
│   └── undead_families.lua      # Enemy family groups harmed by healing (FR-6d)
└── core/
    ├── settings_manager.lua     # Settings load/save/update, per-character data management
    ├── state.lua                # Global state (caster, target, player, party, cached stats)
    ├── ipc.lua                  # IPC utilities (relay pattern, send helpers)
    ├── timer_manager.lua        # Timer lifecycle (create, tick, expire, reposition)
    └── event_hooks.lua          # Windower event registrations (prerender, job_change, action, etc.)
```

## Component Descriptions

### 1. boxcommands.lua (Entry Point)
- **Purpose**: Addon registration, initial setup, event wiring
- **Responsibilities**: Register `_addon` metadata, require core modules, call `setupCommands()`, register `addon command` event pointing to router
- **Boundary**: Thin — delegates everything to router and event_hooks

### 2. ui/ (UI Components)
- **Purpose**: All visual rendering — headers, timers, arrows, menu hiding
- **Responsibilities**: Create/destroy UI primitives, position calculations, animation ticking, visibility management
- **Boundary**: Receives state from timer_manager and state.lua; never touches game APIs directly for data

### 3. commands/ (Command Layer)
- **Purpose**: Parse and execute user commands
- **Responsibilities**: Route commands to handlers, construct IPC relay messages, orchestrate casting/ability flows
- **Boundary**: Calls into algorithms/ for spell selection, core/state for target/caster, core/ipc for relay

### 4. algorithms/ (Spell Selection)
- **Purpose**: Intelligent spell tier selection for healing and nuking
- **Responsibilities**: Evaluate available spell tiers, calculate estimated output, compare efficiency ratios, select optimal tier
- **Boundary**: Reads from data/ for formulas, core/state for cached stats; returns spell data to commands/casting

### 5. data/ (Static Game Data)
- **Purpose**: Lookup tables for game mechanics (spells, elements, pacts, formulas)
- **Responsibilities**: Provide data; never modified at runtime
- **Boundary**: Pure data, no side effects, no API calls

### 6. core/ (Core Services)
- **Purpose**: Shared infrastructure — settings, state, IPC, timers, event management
- **Responsibilities**: Settings persistence, global state management, IPC relay utilities, timer lifecycle, event registration
- **Boundary**: Used by all other components; has no dependencies on commands/, algorithms/, or ui/ (no circular deps)
