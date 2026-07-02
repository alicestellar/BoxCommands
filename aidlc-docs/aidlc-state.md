# AI-DLC State Tracking

## Project Information
- **Project Type**: Brownfield
- **Start Date**: 2026-06-03T12:00:00Z
- **Current Stage**: CONSTRUCTION - Unit 5: Healing Spell Selection (NEXT)

## Workspace State
- **Existing Code**: Yes
- **Programming Languages**: Lua, Batch (BAT)
- **Build System**: None (interpreted Windower addon)
- **Reverse Engineering Needed**: Yes
- **Workspace Root**: c:\Users\alyss\Documents\aidlc-workflows\BoxCommands

## Code Location Rules
- **Application Code**: Workspace root (NEVER in aidlc-docs/)
- **Documentation**: aidlc-docs/ only
- **Structure patterns**: See code-generation.md Critical Rules

## Extension Configuration
| Extension              | Enabled | Decided At            |
|------------------------|---------|-----------------------|
| Security Baseline      | No (custom packet constraint only) | Requirements Analysis |
| Property-Based Testing | No      | Requirements Analysis |

## Stage Progress
- [x] Workspace Detection - COMPLETED (2026-06-03)
- [x] Reverse Engineering - COMPLETED (2026-06-03)
- [x] Requirements Analysis - COMPLETED (2026-06-03)
- [x] User Stories - SKIP (single user, no multiple personas)
- [x] Workflow Planning - COMPLETED (2026-06-03)
- [x] Application Design - COMPLETED (2026-06-03)
- [x] Units Generation - COMPLETED (2026-06-03)

### CONSTRUCTION PHASE
- [x] Unit 0: Debug & Stabilize Baseline - COMPLETED (1.1.1)
- [x] Unit 1: Documentation & Cleanup - COMPLETED (1.2.0)
- [x] Unit 2: Settings & Configuration Foundation - COMPLETED (2.0.0)
- [x] Unit 3: UI Visual Overhaul - COMPLETED (3.0.0)
- [x] Unit 9: Party Status Bars + Buff/Debuff Icons - COMPLETED
- [x] FR-11/FR-12: Charge Timers + Timer Sync via Shared File - COMPLETED
- [~] Unit 4: Intelligent Targeting - IMPLEMENTED, pending in-game testing
- [ ] Unit 5: Healing Spell Selection Algorithm (FR-7) - NEXT
- [ ] Unit 6: Nuking Spell Selection Algorithm (FR-8)
- [ ] Unit 10: Cast Pathway Tier Refactor (FR-16)
- [ ] Unit 11: Elemental Selection Core (FR-15a-c)
- [ ] Unit 12: Elemental Family Commands (FR-15d-g)
- [ ] Unit 13: Bard Song Families (FR-18)
- [ ] Unit 14: Geomancy Command (FR-17)
- [ ] Unit 7: Debuff Resistance (FR-9, Conditional)
- [ ] Unit 8: Alliance Support (FR-10)
- [ ] FR-13: Automated Skillchain Planner (planning complete, not implemented)
- [ ] Unit 15: Configurable Bar Color Theming (FR-19) — independent UI retrofit, can be pulled forward anytime
- [x] FR-20: Status Removal Spell Reference (research) - COMPLETED (2026-07-02)
- [ ] Unit 16: Priority-Based Status Clear Command (FR-21) — depends on FR-20 research; largely independent, schedulable anytime
- [ ] Unit 17: Debuff Priority Name Highlighting (FR-22) — pairs with FR-21; needs debuff tier list confirmed before build

**Sequencing note (user-approved 2026-07-01)**: Elemental units (10-14) come AFTER
Unit 6 so `box nuke` can use real FR-8 nuking logic for tier selection instead of a
placeholder. Order: 5 → 6 → 10 → 11 → 12 → 13 → 14 → 7 → 8 → FR-13.
FR-15h (forced-element macro titles) is a MacroEditor concern, NOT a BoxCommands unit.
Unit 15 (FR-19 bar theming) is independent of the spell chain and can be scheduled
whenever desired (it's a QoL/safety retrofit to the existing status bars).

## Backlog / Requested Enhancements (from JobMacros project, 2026-06-30)

> **FORMALIZED 2026-07-01**: The three backlog items below have been organized into
> proper requirements in `requirements.md`:
> - **FR-15: Unified Elemental Selection Framework** — element resolution layer + per-family commands (helix/storm/nuke/bar/en/spikes/threnody/carol/shot/rune), orientation classification, status-resistance membership, forced-element title convention.
> - **FR-16: Generalized Spell Tier Selection (Cast Pathway)** — separates "strongest-available" (bard songs) from efficiency-based (Units 5/6/7). Element selected first, then tier applied in the cast pathway like WHM/BLM/NIN.
> - **FR-17: Geomancy Command (`geo <effect>`)** — context-aware Indi-/Geo- selection with buff/debuff classification.
> - **FR-18: Bard Song Variant Families** — Threnody/Carol (elemental, via FR-15+FR-16) and Etude (stat-based, via FR-16).
>
> Architecture decision (user 2026-07-01): element selection (FR-15) is a distinct
> first step; the resolved spell/song name flows into the cast pathway (FR-16) which
> applies II/III tiers. Bard songs ALWAYS use the strongest available version, unlike
> the efficiency-optimized cure/nuke/debuff families in Units 5/6/7.
>
> Original raw notes preserved below for reference.

- [ ] **Variant-family ability auto-selection (BRD songs).** Add support to auto-select the
  correct variant of "family" abilities that are NOT numerically tiered but instead split into
  per-element or per-stat distinct spells, analogous to how `storm`/`helix` auto-pick an element:
  - **Threnody** — 8 elemental variants (Fire/Ice/Wind/Earth/Lightning/Water/Light/Dark Threnody).
  - **Carol** — 8 elemental variants (+ Carol II).
  - **Etude** — 7 stat variants (STR/DEX/VIT/AGI/INT/MND/CHR) + enhanced versions.
  Goal: a single command (e.g. `box threnody <element>` / `box carol <element>` / `box etude <stat>`,
  or auto-pick where it makes sense) so one macro pattern covers each family instead of a macro per
  variant. Selection logic (auto vs. argument-driven) to be designed. Source: JobMacros brd.md.

- [ ] **Geomancy command (`geo <effect>`) — context-aware Indi-/Geo- selection.** A single
  command takes a shared effect keyword (e.g. `fury`, `frailty`, `refresh`, `haste`) and decides
  prefix + target from the CURRENT target context:
  - **Target = enemy:** use **Indicolure** (`Indi-<Effect>`).
    - debuff effect → cast on the **enemy** (`<t>`/`<bt>`).
    - buff effect → cast on the **Geomancer** (`<me>`).
  - **Target = a party member (directly targeted, not self):** **Indicolure** (`Indi-<Effect>`) on
    that party member. (Indicolure only goes on a party member when directly targeted.)
  - **Target = self (`<me>`):** **Geocolure** (`Geo-<Effect>`) — place the Luopan — regardless of
    buff or debuff.
  - Requires a geomancy **buff/debuff classification** of the ~30 effect words. From JobMacros geo.md:
    - **Buffs:** Voidance, Precision, Regen, Attunement, Focus, Barrier, Refresh, Fury, Fend, Acumen,
      Haste, STR, DEX, VIT, AGI, INT, MND, CHR.
    - **Debuffs:** Poison, Slow, Torpor, Slip, Languor, Paralysis, Vex, Frailty, Wilt, Malaise,
      Gravity, Fade.
  - Builds the full spell name (`Indi-Fury` / `Geo-Fury`) and routes through the existing cast
    pipeline. Note: Geocolure is GEO main-job only; Indicolure works on a GEO subjob (reduced potency).
  - Source: JobMacros geo.md + user spec 2026-06-30.

- [ ] **Unified Elemental Selection Framework** (supersedes/extends the BRD variant-song and
  storm/helix item — one element model for ALL elemental ability commands). Source: JobMacros
  elemental-spell-families.md + user spec 2026-07-01.

  **Element resolution — every elemental command resolves an element as either:**
  - **Specified:** an explicit element (`fire|ice|wind|earth|lightning|water|light|dark`), given
    inline (e.g. `box helix fire`) or via a persistent selector (e.g. `box element fire`). When
    specified, it is ALWAYS that element.
  - **Default:** derived from the current **day/weather** (reuse the existing `get_elements`
    day-vs-weather logic already used by `handle_storm`/`handle_helix`), applied per the ability's
    **orientation**:
    - **Offensive ability → attack WITH the day/weather element** (use that element).
    - **Defensive ability → defend FROM the day/weather element** (use the member that protects
      against that element).
  - A `box element <element|default>` setter (persistent, default = `default`) that all elemental
    commands honor when no inline element is passed. Inline arg overrides the persistent setter.

  **Orientation classification (drives the default attack-with/defend-from):**
  - **Offensive (use day/weather element):** Helix, Storm, elemental nukes (single / -ga / -ra /
    -ja / Ancient), En-spells, Elemental Spikes, BRD Threnody, COR Quick Draw shots, elemental
    Ninjutsu, **offensive Rune**.
  - **Defensive (protect against day/weather element):** Bar-element spells, BRD Carol,
    **defensive Rune**.

  **Commands (no element arg = default mode; with arg = specified):**
  `box helix [el]`, `box storm [el]`, `box nuke [el]`, `box bar [el]`, `box en [el]`,
  `box spikes [el]`, `box threnody [el]`, `box carol [el]`, `box shot [el]` (Quick Draw),
  plus the geomancy/ninjutsu commands as applicable. Each maps element→member via the lookup
  tables in elemental-spell-families.md.

  **Runes — two dedicated selectors that follow the current element (default day/weather or
  specified):**
  - `box rune off [el]` — **offensive**: the rune that DEALS the element (attack-with):
    Fire→Ignis, Ice→Gelus, Wind→Flabra, Earth→Tellus, Lightning→Sulpor, Water→Unda,
    Light→Lux, Dark→Tenebrae.
  - `box rune def [el]` — **defensive**: the rune that RESISTS the element (defend-from):
    Fire→Unda, Ice→Ignis, Wind→Gelus, Earth→Flabra, Lightning→Tellus, Water→Sulpor,
    Light→Tenebrae, Dark→Lux.

  **Caveats:**
  - **Spikes** only exist for Fire/Ice/Lightning — if the resolved element has no spike, fall back
    or message (don't error silently).
  - **Light/Dark** only exist for some families (Quick Draw, runes, Threnody, Carol, PLD/DRK
    En-light/dark); nukes/bar/elemental-spikes/ninjutsu/elemental-En have no Light/Dark member.
    Light/Dark days are rare but possible — handle gracefully.
  - **GEO Indi-/Geo- are NOT elemental** (they are effect-keyed: Fury/Frailty/Refresh/…), so this
    element framework does NOT apply to them; the separate `geo <effect>` command (already
    roadmapped) governs them. [CONFIRMED 2026-07-01: user agrees the element framework does NOT
    apply to indi/geo — they remain effect-keyed and are handled solely by the separate
    `geo <effect>` command.]

  **Status-resistance membership (user requirement 2026-07-01):** the framework's **defensive**
  side additionally governs **status-resistance** abilities, keyed by element via the FFXI
  element→status map (Fire→Amnesia/Plague, Ice→Paralysis, Wind→Silence, Earth→Petrification,
  Water→Poison, Dark→Blind, Light/Dark→Sleep; **Thunder has no status-resistance member**):
  - **IN:** **bar-status spells** (Barpoison, Barparalyze, Barsilence, Barpetrify, Baramnesia/
    Barvirus, Barblind, Barsleep + their `-ra` AoE forms), the existing bar-element spells, and
    any other ability that *raises resistance to / reduces the chance of* an element-keyed
    status. Defending a resolved element also fires that element's matching bar-status spell.
  - **OUT:** status-**inflicting** abilities (enfeebles/debuffs that apply Poison, Paralyze,
    Slow, Silence, Break, Blind, Sleep, Bind, Dia/Bio, NIN status ninjutsu like Kurayami/Hojo/
    Dokumori, BLU status spells, etc.) are NEVER auto-selected by the framework — they are
    deliberate offensive tools, not part of day/weather or defensive element selection.
  - **RUN ward abilities (rune-keyed, NOT forced-element):** **Pflug** (`ja pflug`) grants
    status-ailment resistance keyed to active runes — the JA analogue of bar-status spells, but
    it takes no element argument and rides whatever rune `box rune def/off` already selected.
    **Vallation** (`ja vallation`) / **Valiance** (`ja valiance`) reduce elemental DAMAGE (not
    status) per active rune. These are plain `ja` macros with NO element-status title — selecting
    the rune IS the element selection. (Confirmed Pflug also covers ailments with no bar-status:
    Bind/Ice, Gravity/Wind, Slow/Earth, **Stun/Thunder**, Curse/Dark, Charm/Light.)
  - **Out of scope (not commands):** passive "Resist X" job traits; GEO Attunement (magic
    evasion, effect-keyed → geo command); Aquaveil (interruption, not status); food/gear/magic
    shields. Detail → JobMacros `elemental-spell-families.md` §11.

  **Forced-element title convention (user requirement 2026-07-01):** any command that selects a
  **forced/specified** element must title the produced macro as **element-abbrev + status-abbrev**
  (≤4 + ≤4, within MacroEditor's ≤8-char title limit), so the title shows the element AND its
  keyed status at a glance. Example: Water → `WatePois`. Full mapping + abbreviations live in
  JobMacros `elemental-spell-families.md` §10. **Title set FULLY LOCKED (user 2026-07-01), one
  status per element:** `FirePlag`, `IcePara`, `WindSile`,
  `EartPetr`, `ThunAmne`, `WatePois`, `LighSlee`, `DarkBlin`. Two deliberate convention
  exceptions: **Fire→Plague** (resource drain fits fire theme) and **Thunder→Amnesia**. The
  Fire/Thunder swap exists so all **eight** bar-status spells fit the eight element slots: Fire
  owns two (Barvirus=Plague, Baramnesia=Amnesia) and Thunder owns none, so Amnesia is rehomed on
  the Thunder slot to keep **Baramnesia castable**. Bar-**element** spells follow the TRUE element
  (Thunder slot → Barthunder); bar-**status** spells follow the TITLE status (Thunder slot →
  Baramnesia). Each bar-status spell gets one home: Fire→Barvirus, Thunder→Baramnesia,
  Ice→Barparalyze, Wind→Barsilence, Earth→Barpetrify, Water→Barpoison, Light→Barsleep,
  Dark→Barblind. Thunder/Stun *resistance* is not a barspell — RUN Pflug (Tellus rune via
  `box rune def`) covers it, no title needed. `ThunAmne` is FINAL (user 2026-07-01).
  The status half of a title is a label derived from the element; it does not imply the macro
  inflicts that status.
