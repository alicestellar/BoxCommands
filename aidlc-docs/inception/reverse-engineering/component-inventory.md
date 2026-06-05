# Component Inventory

## Application Packages

- **boxcommands.lua** - Addon entry point, command router, event registration
- **commands.lua** - Core business logic (spell casting, abilities, pacts, timer management, UI initialization)
- **helper_functions.lua** - Utility functions (spell selection, validation, state management, inventory operations)
- **data_tables.lua** - Static configuration (UI layout, game data tables, elemental relationships, pact definitions)

## Infrastructure Packages

- **Start_FFXI_Team.bat** - Batch script - Sequential 6-character team launcher with PlayOnline profile management
- **Start_FFXI_Alliance.bat** - Batch script - Sequential 18-character alliance launcher with party scope selection

## Shared Packages

- **Graphics/** - Shared image assets (timer bar background and foreground PNGs)

## Test Packages

- None (no test infrastructure exists)

## Total Count

- **Total Packages**: 7
- **Application (Lua)**: 4
- **Infrastructure (Batch)**: 2
- **Shared (Assets)**: 1
- **Test**: 0
