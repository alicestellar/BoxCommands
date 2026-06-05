# Code Quality Assessment

## Test Coverage
- **Overall**: None
- **Unit Tests**: Not present
- **Integration Tests**: Not present
- **Notes**: No test framework exists. Validation is done manually by running the addon in-game.

## Code Quality Indicators
- **Linting**: Not configured (no `.luacheckrc` or equivalent)
- **Code Style**: Mostly consistent within files but varies across files (mix of camelCase and snake_case, inconsistent spacing)
- **Documentation**: Poor - minimal inline comments, no function docstrings, README is a single line

## Technical Debt

### High Priority
- **Shared texture state bug**: `create_timer_ui()` references `master_textures.bg` and `master_textures.fg` directly instead of creating new instances. All timer bars share the same two image objects, meaning position/size changes affect all timers. This is partially masked by the prerender loop resizing foregrounds each frame.
- **Hardcoded character names**: Character names (`Makaria`, `Amaranti`, `Aenura`, `Midnaria`, `Entrapta`, `Luccaria`) are hardcoded in multiple locations (`char_columns`, `initialize_column_headers()`, `setupCommands()`). No configuration file support.
- **Global state pollution**: Heavy use of global variables (`player`, `party`, `caster`, `target`, `spelllevel`, `active_network_timers`, `buffactive`, etc.) with no namespace isolation.

### Medium Priority
- **Dead code**: `generate_progress_string()` function appears unused (text-based bar generation superseded by image-based approach). Several variables in `validabils` for non-english languages are populated but never queried.
- **Inconsistent IPC pattern**: The relay check (is current player the caster?) is duplicated across `cast`, `ja`, `pet`, `bstpet`, and `pact` command handlers with slight variations. Should be a shared utility.
- **Unused `packets` require**: `commands.lua` requires the packets library but never uses it directly.
- **Magic numbers**: UI positions (e.g., `header_x + 18`, `UI_Layout.base_y - 22`, `header_x - 3`) scattered without named constants explaining their purpose.
- **`spelllevel` variable unused**: The `spelllevel` global is set by a command but never referenced in spell selection logic.

### Low Priority
- **Mixed naming conventions**: Functions use both camelCase (`setupCommands`, `getNinjaTool`) and snake_case (`set_macro_page`, `get_elements`, `create_timer_ui`).
- **Large monolithic functions**: `select_highest_spell()` is ~80 lines handling multiple concerns (tier enumeration, ninjutsu tool management, validation, MP checking, recast checking, elemental fallback).
- **No error handling for IPC**: If `send` command fails (target character offline), no feedback is provided to the user.

## Patterns and Anti-patterns

### Good Patterns
- **Command routing**: Clean separation of command dispatch from execution logic
- **Tier selection**: Intelligent spell tier selection algorithm handles edge cases well (ninjutsu, helix fallback)
- **IPC abstraction**: Transparent local-vs-remote execution decision
- **Elemental logic**: Weather/day interaction properly handles intensity and weak element conflicts
- **Pact categorization**: Clean lookup table design for avatar-specific pact resolution

### Anti-patterns
- **God Object (data_tables.lua)**: Single file holds all configuration for completely unrelated systems (UI layout, game mechanics, tool mappings, pact data)
- **Shared Mutable State**: All modules communicate through globals, making state changes hard to trace
- **Copy-Paste IPC**: The "check if local, else relay" pattern is duplicated 5 times with minor variations
- **Texture Reference Sharing**: Timer UI creation returns references to shared master textures rather than independent instances
- **Implicit Dependencies**: Functions depend on globals being initialized by other modules loading first (load order matters)
- **Stringly-Typed Interface**: All inter-character communication passes through string command reconstruction/parsing
