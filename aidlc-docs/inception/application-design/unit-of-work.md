# Units of Work

## Unit 0: Debug & Stabilize Baseline
- **Scope**: Test all existing functionality, fix broken features, establish known-good state
- **Version**: Remains 1.1.x (micro bumps for fixes only)
- **Deliverables**:
  - Generated T/F/X test checklist covering all current commands and UI features
  - All `f`-marked items fixed
  - `x`-marked items added to deferred testing list
  - Clean commit of working baseline
- **Components Touched**: Existing files only (boxcommands.lua, commands.lua, helper_functions.lua, data_tables.lua)
- **Exit Criteria**: All testable functionality passes; commit tagged as baseline

## Unit 1: Documentation & Cleanup
- **Scope**: FR-2 (remove dead code), FR-3 (inline docs, README, version history)
- **Version**: 1.1.0 → 1.2.0 (minor bump for cleanup changes)
- **Deliverables**:
  - Dead code removed (spelllevel, unused requires, duplicate functions, etc.)
  - IPC relay pattern consolidated into shared utility
  - Comment blocks on all functions
  - Inline comments on command router
  - README updated with full command reference and version history section
- **Components Touched**: All existing files (refactoring in place before module split)
- **Exit Criteria**: Code is clean, documented, and still functions identically to Unit 0 baseline

## Unit 2: Settings & Configuration Foundation
- **Scope**: FR-4g (settings file), FR-4h (dynamic party display), FR-5 (internalized keybinds), FR-5b (job/HP tracking)
- **Version**: 1.2.0 → 2.0.0 (major bump — full feature: configuration system)
- **Deliverables**:
  - `core/settings_manager.lua` created
  - `core/state.lua` created
  - Settings XML with character list, macro books, display order
  - Dynamic character display (only show chars in party, settings-order)
  - Keybinds moved from scripts into addon (Ctrl+F1-F6 sets caster + macro for all boxes)
  - Job detection on load + job_change event → writes to settings
  - Max HP capture with delay after job change
  - `//box setup` forces refresh
  - External script files no longer needed
- **Components Touched**: New core/ files, boxcommands.lua refactored, commands.lua refactored
- **Exit Criteria**: No hardcoded character names; scripts eliminated; settings file drives all config

## Unit 3: UI Visual Overhaul
- **Scope**: FR-4a (header backgrounds), FR-4b (XivParty text style), FR-4c (animated caster arrow), FR-4d (target arrow), FR-4e (timer labels), FR-4f (menu hiding)
- **Version**: 2.0.0 → 3.0.0 (major bump — full feature: UI overhaul)
- **Deliverables**:
  - `ui/` directory with class-based UI system (ui_element, ui_text, ui_image, ui_bar, ui_header, ui_arrow, ui_manager)
  - Headers use scaled bar_bg as background with name text inside
  - Text styled like XivParty (Arial, size 15, stroke #062D54C8, width 2)
  - Animated floating arrow for caster (left side, pointing right)
  - Mirrored animated arrow for target (right side, pointing left)
  - Timer bars have text labels showing ability name
  - Menu auto-hide (Phase 1: hide all on menu open)
  - Compact layout (bars close together, minimal screen real estate)
- **Components Touched**: New ui/ directory, event_hooks updated, timer_manager refactored
- **Exit Criteria**: UI is visually complete, labels visible, arrows animate, menus don't get blocked

## Unit 4: Intelligent Targeting
- **Scope**: FR-6a (self-only), FR-6b (enemy-only), FR-6c (party-only fallback), FR-6d (undead healing check)
- **Version**: 3.0.0 → 3.1.0 (minor bump per sub-feature)
- **Deliverables**:
  - `commands/targeting.lua` created
  - `data/undead_families.lua` created
  - Target resolution integrated into cast_spell, job_ability, pet_command, bstpet_command
  - Self-only spells force `<me>`
  - Enemy-only abilities force `<bt>`
  - Party-only abilities default to `<me>` when targeting enemy
  - Healing on non-undead enemy redirects to self
  - BST pet abilities: attempt programmatic target resolution; fallback to existing workaround
- **Components Touched**: commands/targeting.lua (new), commands/casting.lua, data/undead_families.lua (new)
- **Exit Criteria**: All targeting rules verified in-game across multiple spell/ability types

## Unit 5: Healing Spell Selection Algorithm
- **Scope**: FR-7a (core algorithm), FR-7b (stat capture), FR-7c (level/skill), FR-7d (status effects), FR-7e (stat totals), FR-7f (HP estimation)
- **Version**: 3.x.0 → 4.0.0 (major bump — full feature: intelligent healing)
- **Deliverables**:
  - `algorithms/healing.lua` created
  - `algorithms/spell_selection.lua` created (shared utilities)
  - `data/healing_data.lua` created (cure base potencies, formulas)
  - Stat snapshot during midcast, cached per job+category
  - HP deficit calculation (party HP% × estimated/configured max HP)
  - Optimal cure tier selection: lowest tier that fully heals OR highest available if none can
  - Status effect awareness (Light Arts, Afflatus Solace, etc.)
  - Optional potency/received overrides from settings
- **Components Touched**: algorithms/ (new), data/healing_data.lua (new), commands/casting.lua updated, core/state.lua updated
- **Exit Criteria**: Cure spell selection demonstrably picks appropriate tier based on HP deficit

## Unit 6: Nuking Spell Selection Algorithm
- **Scope**: FR-8a (max damage), FR-8b (damage/MP ratio), FR-8c (resistance - nice to have), FR-8d (stat integration)
- **Version**: 4.0.0 → 5.0.0 (major bump — full feature: intelligent nuking)
- **Deliverables**:
  - `algorithms/nuking.lua` created
  - `data/nuking_data.lua` created (damage formulas, skill caps, MP costs)
  - Skill-based tier selection (efficiency at current skill level)
  - Damage/MP ratio comparison between adjacent tiers
  - Resistance likelihood check (if feasible; documented as skipped if not)
  - Uses same midcast stat cache as healing
- **Components Touched**: algorithms/nuking.lua (new), data/nuking_data.lua (new), commands/casting.lua updated
- **Exit Criteria**: Nuke selection picks skill-appropriate tier; doesn't waste MP on spells beyond skill cap

## Unit 7: Debuff Resistance (Conditional)
- **Scope**: FR-9 (apply resistance analysis to status debuffs)
- **Version**: 5.0.0 → 5.1.0 (minor bump)
- **Deliverables**:
  - Extension of resistance logic from FR-8c to debuff spells
  - Only executes if FR-8c proved feasible
  - If not feasible: document why and skip
- **Components Touched**: algorithms/nuking.lua or new algorithms/debuff.lua
- **Exit Criteria**: Debuff spell selection accounts for resistance if data available; documented skip if not

## Unit 8: Alliance Support
- **Scope**: FR-10 (UI for 3 parties, commands/targeting for all 18 characters)
- **Version**: 5.x.0 → 6.0.0 (major bump — full feature: alliance support)
- **Deliverables**:
  - UI shows Party 2 and Party 3 rows below Party 1 (only when in alliance)
  - Settings file supports up to 18 characters across 3 parties
  - Any alliance character can be caster or target
  - All commands work cross-party via IPC
  - Keybind system adapts for >6 characters
  - Job broadcasting/settings extends to alliance members
  - Dynamic display: only show configured characters present in alliance
- **Components Touched**: ui/ui_manager.lua, core/settings_manager.lua, core/state.lua, commands/router.lua, core/ipc.lua
- **Exit Criteria**: Full alliance of configured characters visible and controllable
