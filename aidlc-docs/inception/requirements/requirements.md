# BoxCommands Requirements Document

## Intent Analysis

- **User Request**: Update documentation, clean up codebase, overhaul UI, move script logic into addon, implement intelligent targeting, build healing/nuking spell selection algorithms, and add alliance support.
- **Request Type**: Enhancement (major overhaul of existing addon)
- **Scope Estimate**: System-wide (all modules affected, new modules added)
- **Complexity Estimate**: Complex (multiple algorithmic requirements, UI redesign, architecture changes)

---

## Functional Requirements

### FR-1: Windower API Reference
- **Priority**: Dropped
- **Description**: No on-disk Windower documentation required. APIs will be referenced on-demand during construction.

### FR-2: Code Cleanup
- **Priority**: High
- **Description**: Remove unused references and dead code. Improve efficiency of command routing.
- **Acceptance Criteria**:
  - Remove `spelllevel` variable and `set_spell_level()` function
  - Remove unused `packets` require from commands.lua
  - Remove `generate_progress_string()` (superseded by image-based timers)
  - Remove unused language tables from `validabils` (keep only English unless multi-language support is desired)
  - Remove `region_to_zone_map` if unused
  - Remove duplicate `convert_buff_list()` function (appears twice in helper_functions.lua)
  - Consolidate duplicated IPC relay pattern into a shared utility function
  - Remove `send_set_target()` and `convertSpellLevel()` if unused
  - Remove dead `timer_display_rows` variable

### FR-3: Documentation
- **Priority**: High
- **Description**: Add inline documentation and update README.
- **Acceptance Criteria**:
  - Add comment block before every function explaining purpose, parameters, and return values
  - Add inline comments to command router explaining each command
  - Update README with full command reference (before version history)
  - Maintain version history per the following scheme:
    - Minor version (+0.1.0): Each sub-requirement completed that changes code files
    - Major version (+1.0.0): Each full feature requirement completed (e.g., all of FR-4 or FR-5)
    - Micro version (+0.0.1): Each test-and-commit checkpoint
  - Keep documentation current as features are implemented

### FR-4: Timer UI Overhaul
- **Priority**: High
- **Description**: Redesign the cooldown timer UI with improved headers, animations, labels, and dynamic visibility.

#### FR-4a: Header Background
- Replace text-only headers with timer bar background image (scaled up) so character name text is contained within the bar border graphic.

#### FR-4b: Text Appearance
- Style character name text to match XivParty addon's name rendering (font, size, stroke/shadow). Reference XivParty source for implementation details.
- User will provide XivParty addon files for inspection during construction.

#### FR-4c: Animated Caster Indicator
- Replace static caster icon with an arrow pointing right, positioned left of the header.
- Arrow animates with a slow left-to-right "floating" motion to draw attention.
- User will provide arrow graphic asset during construction.
- Fallback: static arrow if animation proves infeasible.

#### FR-4d: Animated Target Indicator
- Same arrow as caster, but horizontally mirrored (pointing left), positioned right of the header.
- Same floating animation as caster arrow.

#### FR-4e: Timer Bar Labels
- Each timer bar must display a text label identifying what ability/spell is on cooldown.
- Adjust UI spacing if needed to accommodate labels alongside bars.

#### FR-4f: Menu Visibility Management
- Phase 1: Auto-hide entire BoxCommands UI when game menus are detected open. Restore when closed.
- Phase 2 (per-menu): For each specific menu, hide only the overlapping elements rather than the full UI.
- Default to Phase 1 behavior for any menu not yet individually handled.

#### FR-4g: Settings File (Character Configuration)
- Use Windower's built-in settings library (XML format) for primary configuration.
- Character names stored in settings file (not hardcoded).
- Settings file defines the display order of characters.
- Per-character data (job, max HP per job, potency overrides, macro books) stored in the main settings file, programmatically updated at runtime.
- Max HP and job data update automatically on job change (with delay for gear load). Manual refresh via `//box setup`.
- Separate per-character stat cache files for midcast snapshots (used by healing/nuking algorithms).

#### FR-4h: Dynamic Party-Based Display
- Only show headers for characters listed in the settings file AND currently present in the party.
- Headers always positioned left-to-right in settings-file order (not party-slot order).
- Non-box party members (not in config) never shown.
- If only 3 characters are in party, only 3 columns appear.

### FR-5: Internalize Script Logic
- **Priority**: High
- **Description**: Move all keybind script functionality into the addon itself. Eliminate dependency on external .txt script files.
- **Acceptance Criteria**:
  - Single keystroke combination (Ctrl+F1-F6) sets caster AND switches macro book/set for ALL boxes simultaneously via send commands.
  - No external script files required.
  - Character-to-keybind mapping driven by settings file.
  - All current script functionality preserved.

### FR-5b: Job State Broadcasting
- **Priority**: High
- **Description**: Each character's BoxCommands instance tracks its own current job and shares that information via the shared settings file.
- **Acceptance Criteria**:
  - On addon load, each character detects its current main job via `get_player()` (NOT `get_party()` which is unreliable for job data) and writes it to the main settings file.
  - On job change detection, update the settings file with new job AND update max HP (with a short delay to allow gear to load properly).
  - All boxes read other characters' job data from the shared settings file — no IPC send commands needed for job sharing.
  - Running `//box setup` forces a manual refresh of job and max HP data to the settings file.
  - Job data is used by: HP estimation (FR-7f max HP per job), healing algorithm, macro switching, and any other job-dependent logic.

### FR-6: Intelligent Target Resolution
- **Priority**: Medium
- **Description**: Automatically resolve the correct target based on spell/ability valid targets.

#### FR-6a: Self-Only Abilities
- If a spell/ability can only target self, force target to `<me>` regardless of current target setting.
- Works for spells, job abilities, and pet abilities where possible.
- For BST pet abilities: attempt to programmatically resolve valid targets. If not possible, maintain current `/bstpet N` workaround.

#### FR-6b: Enemy-Only Abilities
- If a spell/ability can only target enemies, force target to `<bt>` (battle target) even if current target is a party member.

#### FR-6c: Party-Only Abilities with Enemy Target
- If a spell/ability targets only self or party members, and current target is an enemy, default to `<me>`.

#### FR-6d: Healing on Undead-Type Enemies
- When casting a healing spell while targeting an enemy, check if enemy's family group is in the "harmed by healing" table (undead/skeleton/ghost families).
- If enemy IS in the table: cast on the enemy (healing damages them).
- If enemy is NOT in the table: cast on self instead.

### FR-7: Intelligent Healing Spell Selection
- **Priority**: Medium
- **Description**: Select optimal cure spell tier based on target HP deficit and caster capabilities.

#### FR-7a: Core Algorithm
- Priority order for selection:
  1. If no spell can fully heal the target, cast the highest available heal.
  2. If a spell CAN fully heal the target, cast the lowest tier that will do the job (MP efficiency).

#### FR-7b: Stat-Aware Calculation
- Capture caster stats (MND, Healing Magic skill, buffs) during midcast via `get_player()`.
- Cache per job + spell category. Always "one cast behind" (acceptable).
- Settings file provides optional fields for:
  - Caster-side healing potency bonuses (Cure Potency %, Healing Magic skill+ from gear, etc.)
  - Receiver-side healing received bonuses (per-character overrides)
- Algorithm works on MND + skill alone by default; potency values are opt-in tuning.

#### FR-7c: Level and Skill Awareness
- Account for character level and current healing magic skill level when estimating heal output.

#### FR-7d: Status Effect Awareness
- Check for active buffs/debuffs that modify healing output (e.g., Light Arts, Afflatus Solace, Composure, weakness).

#### FR-7e: Stat Totals
- Use total stats (base + gear + buffs + food), not just gear stats. Captured via `get_player()` during midcast.

#### FR-7f: HP Estimation
- Use party HP% from `get_party()` API.
- Estimate max HP from job, race, and level/ilvl (fallback formula).
- Max HP is programmatically captured via `get_player()` on each character's local instance and written to the shared settings file (keyed per character per job).
- Max HP updates automatically on job change (with short delay for gear to load). Can be manually refreshed via `//box setup`.
- Calculate HP deficit: max_hp * (1 - hp_percent/100).

### FR-8: Intelligent Nuking Spell Selection
- **Priority**: Low
- **Description**: Select optimal nuke spell tier based on damage/MP efficiency at current skill level.

#### FR-8a: Maximum Damage Assessment
- Determine max damage potential of each spell tier at current magic skill level.

#### FR-8b: Damage/MP Ratio Comparison
- Compare ratio of (max damage / MP cost) between adjacent tiers.
- If higher tier's damage ratio exceeds its MP cost ratio, select higher tier.

#### FR-8c: Resistance Likelihood (Nice-to-Have)
- If resistance data is determinable, compare resist rates between tiers.
- If lower tier is significantly more likely to be resisted, prefer higher tier.
- Skip if data is not reliably available.

#### FR-8d: Stat Integration
- Use midcast skill bonuses from cached stats (same capture mechanism as FR-7b).
- Include any other relevant modifiers discovered during construction.

### FR-9: Debuff Resistance Analysis (Nice-to-Have)
- **Priority**: Low
- **Description**: If resistance likelihood calculation is feasible (from FR-8c), apply same logic to status debuff spells targeting enemies.
- Dependent on FR-8c being achievable.

### FR-10: Alliance Support
- **Priority**: Low
- **Description**: Expand UI and command system to support full alliance (up to 18 characters across 3 parties).
- **Acceptance Criteria**:
  - Party 2 and Party 3 headers appear below Party 1 row in the UI.
  - Alliance parties only shown when character is actually in an alliance.
  - Variable character count supported (7-18).
  - Same settings-file-driven display rules apply (only show configured characters that are present).
  - Any character in the alliance can be set as the active caster (not limited to party 1).
  - Any character in the alliance can be set as a target.
  - All commands (cast, ja, pet, bstpet, pact, etc.) work across alliance parties via IPC, not just within the primary party.
  - Job broadcasting (FR-5b) extends to alliance members.
  - Keybind system extends or adapts to support selecting casters beyond the original 6 (party 1).
  - Auto-assignment of position slots expands from 6 to 18 (position 0/unassigned after 18).

---

## Non-Functional Requirements

### NFR-1: Versioning Scheme
- Semver format: MAJOR.MINOR.MICRO
- Current version: 1.1.0
- Minor bump per completed code-changing sub-requirement
- Major bump per completed full feature requirement
- Micro bump per test-and-commit checkpoint

### NFR-2: Performance
- Timer UI prerender loop must remain lightweight (runs every frame at ~30fps).
- Stat caching avoids expensive API calls during spell selection.
- Settings files read at load time and cached in memory.

### NFR-3: Configurability
- No hardcoded character names in source code.
- All user-specific data in settings files.
- Addon usable by other multi-boxers without code modification.

### NFR-4: Packet Safety Constraint
- NEVER modify outgoing game packets without explicit user approval.
- Reading packets is permitted if strictly necessary, but user must be notified.
- Preference: avoid packet usage entirely if Windower APIs suffice.

### NFR-5: Documentation Maintenance
- All functions must have comment blocks (purpose, params, returns).
- README stays current with all commands and version history.
- Documentation updates happen alongside code changes, not deferred.

### FR-11: Charge-Based Timer Display
- **Priority**: Medium (implement alongside Unit 3 UI overhaul)
- **Description**: Abilities with multiple charges display charge indicators next to timer bars.
- **Acceptance Criteria**:
  - Dot indicators appear next to the timer bar for abilities with 2+ charges on cooldown.
  - Dots styled with blue outline matching XivParty text style (stroke #062D54C8).
  - One dot per additional charge beyond the one currently being tracked by the timer.
  - When a charge finishes, one dot disappears and the timer refreshes to the remaining charge's cooldown.
  - Applies to: BST Ready (recast ID 102), SCH Stratagems (recast ID 231), and any other charge-based abilities identified.

### FR-12: Timer Sync via Shared File
- **Priority**: Medium (implement alongside Unit 3 or as part of timer system refactor)
- **Description**: Replace send-command-based timer broadcasting with a shared temp file approach.
- **Acceptance Criteria**:
  - Timer data written to a shared temp file (source character, timer name, max duration, current remaining, charges if applicable).
  - Lightweight IPC command (`box updatetimers`) signals all boxes to refresh from the file.
  - Source character responsible for creating and destroying its timer entries.
  - No duplicate timers on refresh; no timer resets on update signal.
  - Stale entries cleaned up gracefully (e.g., if source character disconnects).

### FR-13: Automated Skillchain Planner with Magic Burst Coordination
- **Priority**: Low (complex feature, implement after core systems are stable)
- **Description**: Analyze the current party composition and determine the optimal weapon skill chain including magic bursts, then coordinate execution across all characters.
- **Acceptance Criteria**:

#### FR-13a: TP Status Tracking
- Use `get_party()` TP data directly at query time for same-party members (no disk writes).
- Skillchain planner polls `get_party()` when triggered to determine who has 1000+ TP.
- Slight delay acceptable (game updates party TP every few seconds).
- For alliance members outside the party: use counter-based IPC collection with fallback timeout.
  - Controller sends `reporttp` to all alliance members.
  - Each box responds with their TP status.
  - Planner executes when all expected responses are in OR the fallback timeout elapses (whichever first).
  - Missing responders are excluded from the plan (user notified).
  - Fallback timeout is configurable in settings file (default TBD via testing).

#### FR-13b: Weapon Skill Availability
- Must know which weapon skills each character has access to.
- List should be as accurate as possible (main hand weapon type, skill level, unlocked WS).

#### FR-13c: Skillchain Optimization
- Use as many full-TP characters as possible in the chain.
- Magic burst as many weapon skills as possible.
- Prioritize magic bursting LATER weapon skills in the chain (higher burst damage on stronger WS).
- Place higher-damage weapon skills later in the chain (e.g., Savage Blade toward the end).
- Skillchain damage itself is higher on later elements — optimize for total damage output.

#### FR-13d: Rank 4 Skillchain Priority
- If Light or Darkness (rank 3) can be extended to Radiance or Umbra (rank 4), always prefer the rank 4 chain.

#### FR-13e: Magic Burst Constraints
- Each caster can only magic burst once per chain (unless summoner — see FR-13i).
- Assign burst casters to the highest-value burst windows.

#### FR-13f: Beastmaster Pet Integration
- BST pet weapon skills should be incorporated into the skillchain sequence.
- Account for pet Ready ability availability and timing.

#### FR-13g: Puppetmaster Automaton Research
- Research how PUP automatons interact with skillchains (can they open/close? timing? WS list?).
- Implement if feasible; document limitations if not.

#### FR-13h: Avatar Blood Pact Magic Bursting
- Avatars should prioritize their most powerful non-Astral Flow pact for magic bursts.
- Blood pact bursts should be placed LATER in the chain than standard nukes (higher damage).
- SMN blood pact magic bursts take priority over other jobs' nukes.

#### FR-13i: Summoner Dual Burst Exception
- Summoners with a nuking sub-job (BLM, RDM, GEO, SCH) may be able to low-level nuke an early skillchain AND avatar-burst a later one.
- Requires testing to confirm timing is feasible.
- If feasible, implement; if not, document as limitation.

---

## TP Polling Options (FR-13a)

**Option A: Party API HP/TP from get_party()**
- **Pro**: Simple, already available, no packets.
- **Con**: `get_party()` returns TP% for party members but it may be unreliable or delayed (similar to job data issues).
- **Con**: Cannot get TP for alliance members outside your party.

**Option B: Each box reports its own TP via shared file**
- **Pro**: Uses the same shared-file pattern as job/HP data. Each box writes its current TP to the settings/temp file.
- **Pro**: Accurate (each box reads its own `get_player().vitals.tp`).
- **Con**: Slightly stale (depends on write frequency). Could update on TP change events or polling.
- **Con**: High write frequency could be a performance concern.

**Option C: Each box reports TP via lightweight IPC on reaching 1000+**
- **Pro**: Only fires when relevant (at 1000 TP, you're ready to WS).
- **Pro**: Minimal traffic — only sends when status changes.
- **Con**: Doesn't give you exact TP value, just "ready" status.
- **Con**: Needs IPC command (`box tpready <name>` / `box tpnotready <name>`).

**Option D: Hybrid — File for exact TP + IPC signal for "ready" state**
- **Pro**: Best of both — accurate data in file, real-time "ready" signal via IPC.
- **Con**: More complex, two systems to maintain.

Please let me know which TP polling approach you prefer (or a combination), and I'll finalize the requirement.

### FR-14: Party Status Bars + Buff/Debuff Icons
- **Priority**: Low (implement after all core systems are stable)
- **Description**: Replicate XivParty's party status display within BoxCommands, eliminating the need to run both addons simultaneously.
- **Acceptance Criteria**:
  - HP, MP, and TP bars displayed per character (XivParty-style visual appearance).
  - Bars use `get_party()` data for values (HP%, MP%, TP).
  - Buff/debuff icons displayed in a grid per character using status icon assets.
  - Buff data sourced from `get_party()` buff arrays.
  - Layout coexists with timer bars — positioned to avoid overlap while remaining compact.
  - Icon assets reused from XivParty's `assets/buffIcons/` directory (referenced for implementation).
  - Supports same display rules as the rest of the UI (fixed slots, collapse setting, menu hiding).
  - Goal: fully replaces XivParty addon for multi-boxing use cases.

---

## Extension Configuration

| Extension              | Enabled | Decided At            |
|------------------------|---------|-----------------------|
| Security Baseline      | No (custom packet constraint only) | Requirements Analysis |
| Property-Based Testing | No      | Requirements Analysis |

---

## Implementation Priority Order

0. Debug and stabilize existing addon (establish known-good baseline before any changes)
1. Documentation and cleanup (FR-2, FR-3)
2. UI overhaul (FR-4 sub-requirements in order)
3. Script internalization (FR-5)
4. Intelligent targeting (FR-6)
5. Healing spell selection (FR-7)
6. Nuking spell selection (FR-8)
7. Debuff resistance (FR-9)
8. Alliance support (FR-10)

Documentation maintained continuously throughout.
