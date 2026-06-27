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
- Toggle command: `//box undead` — switches undead mode on/off.
- When undead mode is OFF (default): healing spells targeting an enemy fall back to `<me>`.
- When undead mode is ON: healing spells pass through to the enemy target (for skilling up healing magic or damaging undead).
- **Implementation note**: Mob family cannot be detected via Windower API (server-side only). A manual toggle is used instead of automatic detection. Toggle undead mode when entering an undead area or skilling up.

#### FR-6e: BST Pet Abilities Always Target Self
- All `/bstpet` commands (Ready abilities, both named and numeric) always use `<me>` as the target regardless of current target setting. The pet resolves its own target from the master's engagement.

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
- **Description**: Abilities with multiple charges display charge indicators next to timer bars to show queued charges still on cooldown.
- **Acceptance Criteria**:
  - The timer bar itself represents the first charge currently counting down.
  - Dots represent additional charges queued behind it (still on cooldown after the current bar expires).
  - Number of dots = (max charges for ability - 1). The bar is the "last" dot visually.
    - BST Ready (3 max charges): 2 dots + 1 bar
    - SCH Stratagems: (max charges based on SCH level/JP - 1) dots + 1 bar
  - Dots use the same graphic pattern as TP dots: `bar_bg.png` background + `bar_fg.png` fill squares, same size as TP dots.
  - A filled dot = that charge is still on cooldown. An empty (background-only) dot = that charge is already available.
  - When a charge is used, its dot fills (another charge now on cooldown).
  - When the bar finishes, one dot unfills (a charge became available) and the bar resets to the next charge's cooldown if any remain.
  - Dots positioned to the right of the timer bar (same layout as TP dots).
  - Timer bar is shortened to accommodate the dots (same as TP bar).
  - Applies to: BST Ready (recast ID 102), SCH Stratagems (recast ID 231), and any other charge-based abilities identified.

### FR-12: Timer Sync via Shared File
- **Priority**: Medium (implement alongside Unit 3 or as part of timer system refactor)
- **Description**: Replace send-command-based timer broadcasting with a shared temp file approach. Also poll `characters.lua` for online status changes to detect logouts without IPC.
- **Acceptance Criteria**:
  - Timer data written to a shared temp file by each box for its own timers only.
  - Each timer entry contains: source character, timer name, ability type, column, **start time** (`os.clock()` epoch at cast), and **total duration**. Charges field included if applicable.
  - All boxes poll the timer file every 5 seconds.
  - On read, each box calculates `time_left = total_duration - (os.clock() - start_time)` to determine current remaining time — late-joining boxes pick up mid-flight timers at the correct position.
  - Timers where `time_left <= 0` are not displayed (natural expiry).
  - Timers where source character has `online = false` in `characters.lua` are not displayed.
  - Each box only ever writes/modifies its own timer entries. Never touches another box's entries.
  - Expired entries from other boxes are left in the file (harmless, ignored by readers). Source box cleans its own stale entries on next write.
  - No duplicate timers on refresh; no timer resets on re-read.
  - Same 5-second poll also re-reads `characters.lua` online status. If a character went offline, rebuild UI (replaces the need for `send @others box refreshui` on logout).
  - **Known limitation**: If a box crashes without writing `online = false`, that character remains "online" in the UI until they log back in or the file is manually corrected. No heartbeat system — accepted tradeoff for simplicity and reduced disk writes.

### FR-13: Automated Skillchain Planner with Magic Burst Coordination
- **Priority**: Low (complex feature, implement after core systems are stable)
- **Description**: Analyze the current party composition and determine the optimal weapon skill chain including magic bursts, then coordinate execution across all characters.
- **Scope (first implementation)**: Party only. Alliance support (FR-13a alliance path), PUP automatons (FR-13g), and SMN dual-burst (FR-13i) are deferred.
- **Acceptance Criteria**:

#### FR-13-Data: Skillchain Data Source (RESOLVED)
- Import skillchain data from the SkillChains addon (Ivaar) included in `scripts/Skillchains/`:
  - `skills.lua` → `weapon_skills` (WS ID → name + skillchain properties), `spells`, `job_abilities` (pet skills), `elements` (SCH Immanence).
  - `Skillchains.lua` → `sc_info` table (skillchain combination rules, rank 3→4 extensions Light→Radiance / Darkness→Umbra, and magic-element mapping per skillchain).
- WS data is stable (no updates since Voracious Resurgence Prime Weapons). Ship as a static table; supplement with WS damage-formula values (modifier %, TP bonus) where needed for damage estimation.

#### FR-13-Commands: Dual Command Interface (RESOLVED)
- `//box skillchain plan <element>` — Calculates the optimal chain and outputs to chat via `windower.add_to_chat`, using the shorthand for each character + WS (shorthand sourced from macro book 23/24 titles in the Macro Editor data folder). Does NOT execute.
- `//box skillchain execute <element>` — Builds a queue of `send <character> <weaponskill>` + `wait` commands and runs them. Aborts if target dies or claim is lost.
- Any box can issue either command. The issuing player participates if able; no one is excluded.
- `<element>` accepts only the goal (closing) elements, based on the element to be magic burst.
- `plan <element>` / `execute <element>` means the chain must CLOSE on that element (may produce it earlier too). Priority: close on the element with the highest-damage WS landing last. Note: some WS are terminal (all level-4 chains are terminal) — account for this.
- If the requested element is not achievable with current party WS + TP: **report failure** (Q2c = option A).

#### FR-13a: TP Status Tracking (party-only for now)
- Use `get_party()` TP data at query time to determine who has 1000+ TP.
- `execute` requires current TP — if a character can perform a WS in the chain at command time, do so. Plan/execute both require live TP.
- Alliance TP collection (IPC `reporttp`, fallback timeout) is deferred to the alliance upgrade.

#### FR-13b: Weapon Skill Availability (RESOLVED)
- Each box writes its available WS to the shared file on: login, job change, and weapon-type equipment change (including ranged). Do NOT rewrite on armor changes.
- Source: `windower.ffxi.get_abilities().weapon_skills` (local player).

#### FR-13c: Skillchain Optimization
- Use as many full-TP characters as possible.
- Magic burst as many WS as possible; prioritize bursting LATER WS in the chain.
- Place higher-damage WS later in the chain. Optimize for total damage output.
- Damage estimation uses the WS damage formula with per-WS values (modifier %, TP bonus — supplement the imported table as needed) plus easily obtainable Windower stats. Ignore values that can't be readily obtained.

#### FR-13d: Rank 4 Skillchain Priority
- If Light or Darkness (rank 3) can extend to Radiance or Umbra (rank 4), always prefer the rank 4 chain.

#### FR-13e: Magic Burst Constraints
- Each caster magic bursts once per chain.
- Assign burst casters to the highest-value burst windows.

#### FR-13f: Beastmaster Pet Integration
- Incorporate BST pet WS into the chain. **Unlike summoner avatars, BST pets ARE viable skillchain steps** — pet TP moves cannot magic burst, so there is no opportunity cost to using them in the chain. Use them as chain steps freely (subject to the 6-step cap).
- Do NOT check pet TP or pet TP modifiers. Check the BST character's Ready charge timer (already synced across boxes) to determine availability.

#### FR-13g: Puppetmaster Automaton (DEFERRED)
- Deferred to later research — no test PUP available yet.

#### FR-13h: Avatar Blood Pact Magic Bursting
- **Summoner avatars are ALWAYS reserved for magic bursts when possible** (not used as skillchain steps). Because chains are hard-capped at 6 steps, an avatar's burst value exceeds its marginal contribution to an already-full chain.
- Avatars prioritize their most powerful non-Astral Flow pact for magic bursts.
- Blood pact bursts placed LATER in the chain than standard nukes. SMN bursts prioritized for a later burst window when feasible.

#### FR-13i: Summoner Dual Burst (DESCOPED)
- Summoners do a single magic burst (no dual low-level + avatar burst). Always reserved for bursting (per FR-13h), prioritized for a later burst window if feasible.

#### FR-13-Timing: Execution Timing & Window (RESOLVED via SkillChains addon)
- Skillchain window: opens after the WS `delay` (default 3s per player WS) and the usable window is `delay + 8 - step` seconds wide — i.e., the window shrinks ~1s per chain step (step 1 → 7s, step 5 → 3s).
- **Hard chain-length cap: 6 weapon skills.** The game auto-closes a chain at `step > 5` (or any level-4 terminal close). The window never drops to ≤1s because step never exceeds 6 (minimum window encountered is 3s at step 5). The planner MUST stop at 6 steps regardless of how many full-TP participants are available.
- **Pet/summon reservation**: Because of the 6-step cap, a full party + pets could theoretically build a 7+ step chain — but we can't use it. Therefore summoner avatars should ALWAYS be reserved for magic bursts rather than skillchain steps whenever possible (their burst value exceeds their marginal contribution to an already-capped chain).
- Do not send the next WS command until the previous WS has landed; the planned chain is stored while wait commands run.
- WS-landed and skillchain detection via action packet listener (`ActionPacket.open_listener`, `weaponskill_finish` category + skillchain message IDs) — same mechanism the SkillChains addon uses.
- If a WS misses, attempt to recalculate an alternative continuation and pivot if possible.

#### FR-13-Burst: Magic Burst Coordination (RESOLVED)
- After a WS closes a skillchain, signal burst casters to nuke within the burst window.
- Burst spell selection reuses FR-8 nuking logic. Account for cast time — start casting early if needed so the spell lands inside the burst window.
- Skillchain element → magic element mapping comes from `sc_info` (each skillchain lists its valid burst elements).

#### FR-13-Abort: Abort & Pivot (RESOLVED)
- Abort (cancel remaining queued steps, no notification) if the target dies or claim is lost.
- For other disruptions (a character disconnects, gets stunned/silenced/interrupted, or a WS whiffs): attempt to pivot and finish the chain working around the problem rather than aborting.

#### FR-13-Position: Positioning (RESOLVED)
- Assume all participants are positioned within range. No range validation.

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

---

## Optional Improvements / Future Testing

- **BST Sic timer**: Add charge timer support for `/pet "Sic"` command (charmed pets). Shares recast ID 102 with Ready. Low priority — only relevant for certain burning circle fights where charming is still used.
- **PUP Maneuver timer testing**: Verify that charge timers display correctly for Puppetmaster maneuvers (recast ID 210, 3 charges, 10s base per charge). Not yet tested in-game.
- **Test Unit 4 changes**: Verify all FR-6 target resolution logic in-game, including bstpet `<me>` targeting, self-only abilities, enemy-only fallback to `<bt>`, friendly-only fallback to `<me>` when enemy targeted, and undead healing detection.
