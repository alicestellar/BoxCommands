# Component Dependencies

## Dependency Diagram

```mermaid
flowchart TD
    subgraph EntryPoint["Entry Point"]
        BC["boxcommands.lua"]
    end

    subgraph Core["core/"]
        SM["settings_manager"]
        ST["state"]
        IPC["ipc"]
        TM["timer_manager"]
        EH["event_hooks"]
    end

    subgraph Commands["commands/"]
        RT["router"]
        CA["casting"]
        TG["targeting"]
    end

    subgraph Algorithms["algorithms/"]
        HL["healing"]
        NK["nuking"]
        SS["spell_selection"]
    end

    subgraph UI["ui/"]
        UM["ui_manager"]
        UE["ui_element"]
        UT["ui_text"]
        UI_IMG["ui_image"]
        UB["ui_bar"]
        UH["ui_header"]
        UA["ui_arrow"]
    end

    subgraph Data["data/"]
        EL["elements"]
        PA["pacts"]
        HD["healing_data"]
        ND["nuking_data"]
        TL["tools"]
        GN["generics"]
        UF["undead_families"]
    end

    BC --> RT
    BC --> EH
    BC --> SM

    RT --> CA
    RT --> ST
    RT --> UM

    CA --> SS
    CA --> TG
    CA --> IPC
    CA --> ST
    CA --> TM

    TG --> ST
    TG --> UF
    TG --> GN

    HL --> HD
    HL --> ST
    HL --> SM
    NK --> ND
    NK --> ST
    SS --> HL
    SS --> NK
    SS --> GN
    SS --> ST

    EH --> TM
    EH --> UM
    EH --> SM
    EH --> ST

    TM --> UM

    UM --> UH
    UM --> UB
    UM --> UA
    UM --> ST
    UM --> SM
    UH --> UE
    UH --> UT
    UH --> UI_IMG
    UB --> UE
    UB --> UT
    UB --> UI_IMG
    UA --> UE
    UA --> UI_IMG
    UT --> UE
    UI_IMG --> UE

    CA --> EL
    CA --> PA
    CA --> TL

    style BC fill:#CE93D8,stroke:#6A1B9A,stroke-width:2px,color:#000
    style Core fill:#BBDEFB,stroke:#1565C0,stroke-width:2px,color:#000
    style Commands fill:#C8E6C9,stroke:#2E7D32,stroke-width:2px,color:#000
    style Algorithms fill:#FFF9C4,stroke:#F57F17,stroke-width:2px,color:#000
    style UI fill:#F8BBD0,stroke:#AD1457,stroke-width:2px,color:#000
    style Data fill:#E0E0E0,stroke:#424242,stroke-width:2px,color:#000
```

## Dependency Rules

### No Circular Dependencies
- `core/` depends on nothing else (except `data/` for generics)
- `data/` depends on nothing (pure static tables)
- `commands/` depends on `core/`, `algorithms/`, `data/`
- `algorithms/` depends on `core/`, `data/`
- `ui/` depends on `core/` (for state and settings)
- Entry point depends on `core/` and `commands/`

### Communication Patterns

| From | To | Pattern |
|------|-----|---------|
| boxcommands.lua → router | Direct function call | Synchronous |
| router → casting | Direct function call | Synchronous |
| casting → ipc | Direct function call | Fire-and-forget (send command) |
| casting → spell_selection | Direct function call, returns result | Synchronous |
| event_hooks → timer_manager | Direct function call | Per-frame tick |
| event_hooks → ui_manager | Direct function call | Per-frame update |
| event_hooks → settings_manager | Direct function call | On job_change event |
| timer_manager → ui_manager | Callback/notify | Timer expire triggers UI reposition |
| Any module → settings_manager | Direct function call | Read/write settings |
| Any module → state | Direct function call | Read/write global state |

### Data Flow Summary

```text
User Input
  → router (parse command)
    → casting (select spell, resolve target)
      → spell_selection (choose tier)
        → healing/nuking algorithms (calculate optimal)
          → data tables (lookup formulas)
          → state (read cached stats)
      → targeting (resolve final target)
        → data/undead_families (check enemy type)
      → ipc (relay or execute locally)
    → timer_manager (schedule recast timer)
      → ipc (broadcast timerui to all boxes)
  → ui_manager (create visual timer bar)

Game Events (per frame)
  → event_hooks.on_prerender()
    → timer_manager.tick() (decrement timers)
    → ui_manager.update() (animate arrows, update bars, check menu)

Job Change Event
  → event_hooks.on_job_change()
    → settings_manager.update_job()
    → (delay) settings_manager.update_max_hp()
```

## External Dependencies

| External | Used By | Purpose |
|----------|---------|---------|
| Windower `resources` | spell_selection, casting, data modules | Game data lookups |
| Windower `texts` | ui_text | Text primitive creation |
| Windower `images` | ui_image, ui_bar, ui_header, ui_arrow | Image primitive creation |
| Windower `settings` | settings_manager | XML settings persistence |
| Windower `tables` | Multiple (inherited from current code) | Table utilities |
| Windower `sets` | data modules | Set data structure |
| Windower events API | event_hooks | Event registration |
| Windower `send` command | ipc | Cross-client communication |
