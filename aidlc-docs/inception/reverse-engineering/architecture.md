# System Architecture

## System Overview

BoxCommands is a Windower addon for FFXI that provides a unified multi-boxing command interface. It consists of a Lua addon loaded by the Windower framework and batch scripts for client launching. The addon operates within the Windower runtime, leveraging its APIs for game state access, inter-process communication (IPC), UI rendering, and input injection.

## Architecture Diagram

```mermaid
flowchart TD
    subgraph UserInterface["User Interface Layer"]
        KB["Keybinds (Ctrl+F1-F6, Alt+F1-F6)"]
        CMD["Chat Commands (//box ...)"]
        TimerUI["Timer Bar UI (images primitives)"]
        ColHeaders["Column Headers (text primitives)"]
    end

    subgraph AddonCore["Addon Core (boxcommands.lua)"]
        Router["Command Router"]
    end

    subgraph BusinessLogic["Business Logic (commands.lua)"]
        SpellCast["cast_spell()"]
        JobAbil["job_ability()"]
        PetCmd["pet_command() / bstpet_command()"]
        Pacts["handle_dynamic_pact()"]
        Storm["handle_storm() / handle_helix()"]
        TimerMgr["Timer Management"]
        UIInit["initialize_column_headers()"]
    end

    subgraph Utilities["Utilities (helper_functions.lua)"]
        SpellSelect["select_highest_spell()"]
        SpellCheck["check_spell() / filter_pretarget()"]
        PlayerInit["initialize_globals()"]
        ItemFind["find_items() / getNinjaTool()"]
        PartyRefresh["refresh_group_info()"]
        TimerPos["reposition_column_elements()"]
    end

    subgraph DataLayer["Data Layer (data_tables.lua)"]
        UILayout["UI_Layout / UI_Style"]
        Elements["elements table"]
        PactData["pacts / pact_wards"]
        ToolMap["tool_map / universal_tool_map"]
        CharCols["char_columns"]
    end

    subgraph External["External (Windower Framework)"]
        WAPI["windower.ffxi API"]
        Resources["resources library"]
        Packets["packets library"]
        SendCmd["send command (IPC)"]
        Images["images / texts primitives"]
    end

    CMD --> Router
    KB --> Router
    Router --> SpellCast
    Router --> JobAbil
    Router --> PetCmd
    Router --> Pacts
    Router --> Storm
    Router --> TimerMgr

    SpellCast --> SpellSelect
    SpellSelect --> SpellCheck
    SpellCheck --> PlayerInit
    SpellCheck --> ItemFind

    Pacts --> PactData
    Storm --> Elements
    SpellCast --> SendCmd
    JobAbil --> SendCmd
    PetCmd --> SendCmd

    TimerMgr --> TimerUI
    UIInit --> ColHeaders
    UIInit --> Images

    SpellCheck --> WAPI
    SpellCheck --> Resources
    PlayerInit --> WAPI
    ItemFind --> WAPI
    PartyRefresh --> WAPI
