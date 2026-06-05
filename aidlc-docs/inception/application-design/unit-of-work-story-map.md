# Unit of Work — Requirements Mapping

## Requirements to Unit Mapping

| Requirement | Unit | Notes |
|-------------|------|-------|
| (Baseline debug) | Unit 0 | Pre-existing bug fixes |
| FR-2: Code Cleanup | Unit 1 | Remove dead code, consolidate patterns |
| FR-3: Documentation | Unit 1 + Continuous | Initial docs in Unit 1; maintained throughout |
| FR-4g: Settings File | Unit 2 | Foundation for all subsequent units |
| FR-4h: Dynamic Party Display | Unit 2 | Depends on settings for character list |
| FR-5: Internalize Scripts | Unit 2 | Keybinds driven by settings |
| FR-5b: Job State Tracking | Unit 2 | Job/HP written to settings file |
| FR-4a: Header Background | Unit 3 | UI overhaul |
| FR-4b: Text Appearance | Unit 3 | XivParty-style text |
| FR-4c: Animated Caster Arrow | Unit 3 | Floating arrow animation |
| FR-4d: Animated Target Arrow | Unit 3 | Mirrored caster arrow |
| FR-4e: Timer Labels | Unit 3 | Text labels on timer bars |
| FR-4f: Menu Visibility | Unit 3 | Auto-hide on menu open |
| FR-6a: Self-Only Targeting | Unit 4 | Target resolution |
| FR-6b: Enemy-Only Targeting | Unit 4 | Target resolution |
| FR-6c: Party-Only Fallback | Unit 4 | Target resolution |
| FR-6d: Undead Healing Check | Unit 4 | Target resolution |
| FR-7a: Core Healing Algorithm | Unit 5 | Optimal cure selection |
| FR-7b: Stat Capture | Unit 5 | Midcast stat snapshot |
| FR-7c: Level/Skill Awareness | Unit 5 | Skill-based calculation |
| FR-7d: Status Effect Awareness | Unit 5 | Buff/debuff modifiers |
| FR-7e: Stat Totals | Unit 5 | Total stats from get_player() |
| FR-7f: HP Estimation | Unit 5 | HP% + max HP calculation |
| FR-8a: Max Damage Assessment | Unit 6 | Nuke tier evaluation |
| FR-8b: Damage/MP Ratio | Unit 6 | Efficiency comparison |
| FR-8c: Resistance Likelihood | Unit 6 | Nice-to-have |
| FR-8d: Stat Integration | Unit 6 | Midcast skill bonuses |
| FR-9: Debuff Resistance | Unit 7 | Conditional on FR-8c |
| FR-10: Alliance Support | Unit 8 | UI + commands for 18 chars |

## Cross-Cutting Concerns

| Concern | Spans Units | Strategy |
|---------|-------------|----------|
| Documentation (FR-3) | All units | Updated alongside code changes in every unit |
| Version History | All units | Bumped per scheme at each checkpoint |
| Settings File | Unit 2 onward | Expanded as new features need config |
| Testing | All units | T/F/X checklist in Unit 0; verify-after-change throughout |
| IPC Protocol | Units 2, 3, 5, 8 | Timer broadcast exists; expanded for alliance |

## Deferred Testing Items

Items marked `x` during Unit 0 testing will be re-tested when the relevant unit is reached:
- BST pet targeting → Re-test in Unit 4
- Summoner pact commands → Re-test if relevant character available
- Alliance-specific features → Test in Unit 8
