# Technology Stack

## Programming Languages

- **Lua** - 5.1 (Windower-embedded) - Core addon logic (all 4 application files)
- **Batch (CMD)** - Windows CMD scripting - Client launcher scripts

## Frameworks

- **Windower** - 4.x - FFXI addon framework providing: addon lifecycle, event system, game state APIs, IPC (`send` command), UI primitives (images, texts), resource data access
- **Windower Addon Libraries** - Bundled with Windower:
  - `resources` - Game data lookups (spells, abilities, items, buffs, weather, days)
  - `packets` - Network packet construction/parsing
  - `images` - Image primitive creation and manipulation
  - `texts` - Text primitive creation and manipulation
  - `tables` - Table utility extensions
  - `sets` - Set data structure
  - `extdata` - Extended item data parsing
  - `socket` - LuaSocket for timing operations

## Infrastructure

- **PlayOnline Viewer** - Square Enix game launcher (managed by batch scripts for multi-account login)
- **autoPOL.exe** - Third-party auto-login utility invoked by launcher scripts
- **Windows File System** - Profile binary swapping (`login_w.*.bin` files) for multi-account management

## Build Tools

- None (interpreted language, no build step required)

## Testing Tools

- None (no test framework or test files present)

## UI Technology

- **Windower Images API** - PNG-based image primitives for timer bars
- **Windower Texts API** - Text rendering for column headers
- **Custom Timer Grid** - Column-based layout system with dynamic row stacking

## Version Control

- **Git** - Source control (separate repository from parent workspace)
