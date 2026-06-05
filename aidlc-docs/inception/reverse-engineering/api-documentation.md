# API Documentation

## Chat Command API

All commands are invoked via `//box <command> [arguments]` in the FFXI chat window.

### //box setup
- **Purpose**: Initialize all keybinds and preload textures
- **Arguments**: None
- **Behavior**: Binds Ctrl+F1-F6 (execute character scripts) and Alt+F1-F6 (set all-character target), preloads bar textures
- **Auto-called**: Yes, on addon load

### //box cast <spell_name>
- **Purpose**: Cast the highest available tier of a spell on the current target
- **Arguments**: `spell_name` (string, may contain spaces)
- **Behavior**:
  1. Reconstructs multi-word spell name from arguments
  2. If current player is not the designated caster, relays via IPC
  3. Calls `select_highest_spell()` to find best castable tier
  4. Executes `/ma "SpellName" <target>`
  5. Triggers pretimer for recast tracking
- **Examples**: `//box cast cure`, `//box cast protect`, `//box cast utsusemi`

### //box ja <ability_name>
- **Purpose**: Execute a job ability on the current target
- **Arguments**: `ability_name` (string, may contain spaces)
- **Behavior**: Relays via IPC if not on caster, otherwise executes `/ja "AbilityName" <target>`, triggers pretimer
- **Examples**: `//box ja provoke`, `//box ja divine seal`

### //box pet <ability_name>
- **Purpose**: Execute a pet command on the current target
- **Arguments**: `ability_name` (string, may contain spaces)
- **Behavior**: Same IPC relay pattern, executes `/pet "AbilityName" <target>`
- **Examples**: `//box pet assault`, `//box pet retreat`

### //box bstpet <ability_name>
- **Purpose**: Execute a Beastmaster pet ability on the current target
- **Arguments**: `ability_name` (string, may contain spaces)
- **Behavior**: Same IPC relay pattern, executes `/bstpet "AbilityName" <target>`

### //box pact <category>
- **Purpose**: Execute a summoner blood pact based on category and active avatar
- **Arguments**: `category` (string - one of: cure, curaga, buffoffense, buffdefense, buffspecial, debuff1, debuff2, sleep, nuke2, nuke4, bp70, bp75, bpray70, astral)
- **Behavior**:
  1. Detects active avatar from pet mob data
  2. Looks up specific pact name from `pacts[category][avatar]`
  3. Determines target type (enemy, self, or subtarget) based on category
  4. Executes the pact and triggers recast timer
- **Examples**: `//box pact cure`, `//box pact bp70`, `//box pact astral`

### //box storm
- **Purpose**: Cast the optimal elemental storm based on current day/weather
- **Arguments**: None
- **Behavior**: Checks weather element/intensity and day element, picks the stronger match, casts corresponding storm spell

### //box helix
- **Purpose**: Cast the optimal elemental helix based on current day/weather
- **Arguments**: None
- **Behavior**: Same elemental logic as storm but casts helix on `<t>`

### //box setcaster <name>
- **Purpose**: Designate which character should receive cast/ability commands
- **Arguments**: `name` (character name string)
- **Behavior**: Sets global `caster` variable
- **Examples**: `//box setcaster Amaranti`

### //box target <target>
- **Purpose**: Set the current target for ability execution
- **Arguments**: `target` (target string - character name or placeholder like `<t>`, `<me>`, `<bt>`)
- **Behavior**: Sets global `target` variable
- **Examples**: `//box target <t>`, `//box target Makaria`

### //box spelllevel <level>
- **Purpose**: Set the spell level selection mode
- **Arguments**: `level` (currently only 'max' is used)
- **Behavior**: Sets global `spelllevel` variable (unused in current selection logic)

### //box macro <slot> [jobType] | //box macro default
- **Purpose**: Switch macro book/set for a party member
- **Arguments**: `slot` (party position 0-5), `jobType` ('main' or 'sub'), or 'default'
- **Behavior**: Changes macro page based on party position lookup in `macro_sets`

### //box pretimer <caster> <abilityType> <castTime> <abilityName>
- **Purpose**: Internal command - schedules a timer after cast time elapses
- **Arguments**: caster name, ability type prefix, cast time in seconds, ability name
- **Behavior**: Waits `castTime` seconds then triggers `//box timer`

### //box timer <caster> <abilityType> <abilityName>
- **Purpose**: Internal command - retrieves actual recast duration and creates timer
- **Arguments**: caster name, ability type prefix, ability name
- **Behavior**: Queries game API for recast time, broadcasts `//box timerui` to all clients

### //box timerui <duration> <charge_duration> <caster> <abilityType> <col_index> <abilityName>
- **Purpose**: Internal command - creates the visual timer bar on all clients
- **Arguments**: duration, charge duration, caster name, ability type, column index, ability name
- **Behavior**: Creates foreground/background image pair at computed grid position

## Internal Function API

### Spell System
| Function | Parameters | Returns | Purpose |
|----------|-----------|---------|---------|
| `select_highest_spell(ability)` | ability name string | spell resource table or nil | Find highest castable tier |
| `check_spell(available_spells, spell)` | spell list, spell data | bool, error string | Validate spell accessibility |
| `filter_pretarget(action)` | action table with prefix/id | bool | Pre-execution validation |

### Timer System
| Function | Parameters | Returns | Purpose |
|----------|-----------|---------|---------|
| `get_duration(abilityType, abilityName, caster)` | prefix, name, caster | void (sends command) | Retrieve recast and broadcast timer |
| `create_network_timer(duration, charge_duration, abilityType, abilityName, casterName, col_index)` | timer params | void | Create timer entry and UI |
| `create_timer_ui(x, y)` | pixel coordinates | table {bg, fg} | Create image primitive pair |
| `reposition_column_elements(col_index)` | column number | void | Restack timers after expiry |
| `trigger_pact_timer(avatar, pact_name)` | avatar name, pact name | void | Create rage/ward recast timers |

### State Management
| Function | Parameters | Returns | Purpose |
|----------|-----------|---------|---------|
| `initialize_globals(player)` | player table | player table | Set up all global state |
| `refresh_player()` | none | void | Refresh player + buff data |
| `refresh_group_info(party, partyinfo)` | party, info | party, info | Rebuild alliance structure |
| `get_character_column(char_name)` | character name | number | Map name to UI column |

### Utility Functions
| Function | Parameters | Returns | Purpose |
|----------|-----------|---------|---------|
| `get_elements()` | none | table {day_element, weather_element, weather_intensity} | Get current elemental state |
| `getNinjaTool(ability)` | ninjutsu name | void (manages inventory) | Ensure tools available |
| `find_items(ids)` | set of item IDs | set, count | Search all bags for items |
| `set_macro_page(set, book)` | set number, book number | void | Change macro page |

## Data Models

### Timer Entry (active_network_timers[label])
- **time_left**: number - Remaining seconds
- **total_time**: number - Original duration
- **column**: number - Column index (1-6)
- **ui**: table - Contains `bg` (background image) and `fg` (foreground image)

### UI Layout Constants
- **base_x**: 20 (left margin)
- **base_y**: 200 (top margin for timer area)
- **column_width**: 160 (pixels per character column)
- **row_height**: 18 (pixels per timer row)
- **bar_width**: 15 (text-mode bar segments, unused in image mode)

### Spell Data (from resources)
- **id**: number - Spell ID
- **en**: string - English name
- **cast_time**: number - Cast time in seconds
- **mp_cost**: number - MP cost
- **recast_id**: number - Recast timer ID
- **levels**: table - Job ID to required level mapping
