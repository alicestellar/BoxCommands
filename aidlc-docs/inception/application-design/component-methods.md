# Component Methods

## core/settings_manager.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `load()` | none | settings table | Load settings from XML via Windower settings lib |
| `save()` | none | void | Persist current settings to XML |
| `get_characters()` | none | ordered list of character names | Character list from settings |
| `get_character_data(name)` | character name | character config table | Per-character data (job, max_hp, macro_book, potency) |
| `update_job(name, job)` | name, job string | void | Update character's current job + save |
| `update_max_hp(name, job, hp)` | name, job, hp number | void | Update character's max HP for specific job + save |
| `get_max_hp(name, job)` | name, job | number or nil | Retrieve stored max HP for character on specific job |
| `get_potency_config(name)` | name | table or nil | Healing potency/received overrides |

## core/state.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `get_caster()` | none | string | Current active caster name |
| `set_caster(name)` | character name | void | Set active caster |
| `get_target()` | none | string | Current target |
| `set_target(t)` | target string | void | Set current target |
| `get_party_members()` | none | table | Characters from settings currently in party/alliance |
| `get_cached_stats(job, category)` | job, spell category | table or nil | Retrieve cached midcast stats |
| `update_cached_stats(job, category, stats)` | job, category, stats table | void | Store midcast stat snapshot |
| `is_in_alliance()` | none | boolean | Whether current character is in an alliance |

## core/ipc.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `relay_to_caster(command_string)` | full box command | void | Send command to caster if not local, else execute locally |
| `send_to_all(command_string)` | command string | void | Broadcast to all boxes via `send @all` |
| `send_to(name, command_string)` | target name, command | void | Send to specific character |

## core/timer_manager.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `create_timer(ability_name, duration, caster_name, ability_type)` | timer params | void | Create new timer entry + UI |
| `tick(dt)` | delta time | void | Decrement all timers, expire finished ones |
| `get_active_timers_for_column(col_index)` | column number | table | Timers in a specific column |
| `clear_all()` | none | void | Destroy all timers |

## core/event_hooks.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `register_all()` | none | void | Register all Windower events (prerender, job_change, etc.) |
| `on_job_change(main_job, main_level, sub_job, sub_level)` | job change data | void | Handle job change: update settings, refresh HP after delay |
| `on_prerender()` | none | void | Frame tick: update timers, update UI arrows, check menu state |

## commands/router.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `handle_command(command, args)` | command string, arg table | void | Route command to appropriate handler |

## commands/casting.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `cast_spell(spell_name)` | spell name string | void | Select optimal spell tier, resolve target, execute, trigger timer |
| `job_ability(ability_name)` | ability name | void | Execute JA with target resolution |
| `pet_command(ability_name)` | ability name | void | Execute pet command |
| `bstpet_command(ability_name)` | ability name | void | Execute BST pet command |
| `handle_pact(category)` | pact category | void | Resolve avatar pact and execute |
| `handle_storm()` | none | void | Cast optimal elemental storm |
| `handle_helix()` | none | void | Cast optimal elemental helix |

## commands/targeting.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `resolve_target(spell_data, current_target)` | spell resource, target string | resolved target string | Apply target resolution rules (self-only, enemy-only, party-only, undead check) |
| `is_self_only(spell_data)` | spell resource | boolean | Check if spell targets only self |
| `is_enemy_only(spell_data)` | spell resource | boolean | Check if spell targets only enemies |
| `is_party_only(spell_data)` | spell resource | boolean | Check if spell targets self/party only |
| `is_undead_target(target)` | target string | boolean | Check if current enemy is harmed by healing |

## algorithms/healing.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `select_cure(target_name, available_cures)` | target name, list of available cure spells | spell data or nil | Select optimal cure tier based on HP deficit and caster stats |
| `estimate_heal_amount(spell_data, stats)` | spell resource, stat table | number | Estimate heal output for given spell and stats |
| `get_hp_deficit(target_name)` | character name | number | Calculate HP deficit using party HP% and stored max HP |

## algorithms/nuking.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `select_nuke(spell_name, available_tiers)` | base spell name, tier list | spell data or nil | Select optimal nuke tier based on damage/MP efficiency |
| `estimate_max_damage(spell_data, skill_level)` | spell resource, skill | number | Max damage at current skill level |
| `compare_efficiency(lower_spell, higher_spell, skill)` | two spell resources, skill | string ("lower" or "higher") | Compare damage/MP ratio between tiers |

## algorithms/spell_selection.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `get_available_tiers(base_ability)` | ability name | ordered spell list | Find all castable tiers of a spell |
| `check_recast(spell_data)` | spell resource | boolean | Check if spell is off recast |
| `check_mp(spell_data)` | spell resource | boolean | Check if player has enough MP |
| `snapshot_midcast_stats(spell_category)` | category string | void | Capture and cache stats from get_player() during midcast |

## ui/ui_manager.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `initialize()` | none | void | Build all UI elements based on current party state |
| `rebuild()` | none | void | Destroy and recreate UI (e.g., party change) |
| `update()` | none | void | Per-frame update (arrow animation, timer bars, visibility) |
| `hide_all()` | none | void | Hide entire UI (menu detected) |
| `show_all()` | none | void | Restore UI visibility |
| `set_menu_hidden(state)` | boolean | void | Toggle menu-hide state with safety timer |

## ui/ui_element.lua (Base Class)

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `init(layout)` | layout config | void | Initialize position, size, visibility |
| `set_pos(x, y)` | pixel coords | void | Update position |
| `set_visible(v)` | boolean | void | Show/hide |
| `destroy()` | none | void | Clean up primitives |

## ui/ui_arrow.lua

| Method | Parameters | Returns | Purpose |
|--------|-----------|---------|---------|
| `init(layout, direction)` | config, "left" or "right" | void | Create arrow image (mirrored for target) |
| `animate(dt)` | delta time | void | Float left-to-right slowly |
| `set_active(state)` | boolean | void | Show/hide based on caster/target status |
