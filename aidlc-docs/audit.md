# AI-DLC Audit Log

## Workspace Detection
**Timestamp**: 2026-06-03T12:00:00Z
**User Input**: "Using AIDLC, I'd like to update documentation for BoxCommands, as well as create a roadmap for changes I would like to make."
**AI Response**: Workspace scanned. Brownfield Lua project identified (Windower addon for FFXI multi-boxing). Proceeding to Reverse Engineering.
**Context**: Initial user request logged. Project classified as brownfield with existing code in Lua. No prior aidlc-docs artifacts found.

---

## Reverse Engineering
**Timestamp**: 2026-06-03T12:05:00Z
**User Input**: N/A (automatic stage after workspace detection)
**AI Response**: Generated 8 reverse engineering artifacts analyzing all source files. Key findings: Lua Windower addon for FFXI multi-boxing, 4 source modules with clear responsibilities, hardcoded character names, shared texture state bug, no tests or docs.
**Context**: Reverse Engineering completed. All artifacts generated in aidlc-docs/inception/reverse-engineering/. Awaiting user approval to proceed.

---

## Reverse Engineering Approval + Requirements Input
**Timestamp**: 2026-06-03T12:10:00Z
**User Input**: "Okay. Here is my list of what I want to work on.1) I want you to import the windower documentation to our aidlc-docs for reference. This lua code is for use as an addon in Windower, which is an addon platform for the video game FFXI, and we will be using windower functions in our code. If you think this is unnecessary, explain why. I am open to not having the reference on disk.2) I want to clean up the application. I want to remove unused references, and I want to clean up the box commands to make them more efficient. For instance: spelllevel is probably not going to be used anymore.3) I would like you to add inline comment documentation to the commands to explain what they do. I also want you to add comments prior to all functions to explain what each function does. I would also like you to update the readme with a list of commands and how they work. (Put this before the version history.) Please update the version history as we work. Whenever we finish a requirement that changes anything in the code files, we update the minor version by 1. Example: We finish section 4a below, we update from 1.2.0 to 1.3.0. When we finish a full feature, we update the major version, i.e. we finish all of requirement 4 or requirement 5, then we update from 1.2.0 to 2.0.0. Any time we stop to test and commit, we update the micro version, i.e. we update from 1.2.0 to 1.2.1.4) I want to update the UI for the cooldown timers.a) The timer bars themselves are sufficient, but I want to replace the headers with the background of the timer bars (but larger, big enough for the text to be 'contained' within the border of the timer bar background)b) I would like the text to have a better appearance. I can give an example addon that you can reference for how I want the text to appear.c) I would like the 'Caster' icon to be an animated ui arrow that points towards the header. It should appear on the left side of the header and the 'point' of the arrow should face to the right. The current caster icon is non-animated, but it does appear in the correct location. If you can steal this from the FFXI Pointer UI that would be great, but if you can't I will need help with finding one. The animation is to call attention to the pointer so it's easy to see who the current caster is.d) I would like the same icon from the 'Caster' icon to be used for target, just reversed horizontally and on the right side of the header instead of the left. The current UI target icon is also in the correct location, but not animated.e) I would like the timer bars to have labels so that I know what they are counting down. If we need to change the spacing of the UI, then we can do that. Without labels, the timer doesn't tell me much. They may have labels currently, but if they do, they are invisible or blocked somehow.f) If we can, I would like the UI to not hide menus 'behind' them. For instance, when the status menu opens, the header of the leftmost member of the party blocks the status menu. It does the same for shops. I would like for the standard menus of the game to 'appear' in front of the UI for box commands, and for the ui to return to visibility when the menus are dismissed.g) I would like for the names of the characters to be in a settings file. I don't want my personal party hard coded into the addon. We can use the settings file both for the UI and for the caster and target variables.h) In addition, I don't want any of the characters to appear unless they are currently in the party. If there are three boxes in the party, only three headers should appear. The UI should always start on the left and show the next header to the right of the previous one, and the characters should appear in the same order as they do in the config file regardless of their position in the party. Non-box party members should not show up.5) I would like to have all of the logic for BoxCommands inside of the actually addon. Currently I rely on scripts to change the caster and the macro. I want to move that functionality into the addon, so I don't want to use scripts. I still want all of the function in each script to be accomplished with one keystroke combination, however.6) I want to improve the targeting function.a) Currently if a spell or ability is self only, the target is supposed to default to self regardless of whether the spell is targeted to someone else. I'm not 100% sure that this is working, so we will need to test that first. I want this to be generified to work with spells, job abilities, and (if possible) pet abilities. Beastmaster has a custom set up that is a little clunky because I don't use every beastmaster pet ability possible. That would be a horrific amount of macros. Instead, you can use /bstpet 1 <me> for the first ability in their list. You can use 2 or 3 or 4 for the others. I would like to programmatically retrieve the ability and check the valid targets for this like any other if possible, but if not we can continue using the workaround I already set up for it.b) The same is set up for only a battle target. If the spell/ability can only target battle targets, then it should target the battle target even if the current target is a party member. This also needs to be tested.c) If the target can only be self or party members, and the target is currently the battle target, I want the target to default to self.d) If we are using a healing spell (such as the 'Cure' line of spells) and we are currently targeting an enemy, I want to check if the enemy can be harmed by healing spells (we should have a table of enemy family groups that meet this description, and we should check the target enemy's family group against this table). If the enemy is not in our table, then I want the character to cast the healing spell on themself.7) I would like to improve the cast spell level selection functionality for healing:a) I want to perform as complex an algorithm as needed when we are casting a healing spell to make sure that we satisfy the following requirements, IN ORDER:1) If we cannot heal the target fully with any spell, we cast the spell that will heal the most that we have available.2) If we CAN heal the target fully with a spell, we cast the lowest level spell that will do the job.b) I want the algorithm to take into account equipment that we use. Because of this, I will need the addon to be aware of certain casting sets. If the user is using gearswap, then we will want to have a file with the latest midcast healing set for their character. We will need to allow for multiple midcast sets, and select the appropriate one from the character's current job.c) I want the algorithm to take into account what level the character is, and what their current skill level is for the appropriate casting skill.d) I want the algorithm to check for status effects that may effect the output of the spell.e) I want the algorithm to account for stat totals, not just what's on equipment.8) I want to improve the spell level selection for nuking:I want the algorithm to be much simpler than for healing. I simply want to select the spell that the current skill level of the caster for the type of magic is best for. If there is a level of the spell that we are at the current skill level cap for, and we are nowhere near the cap of the next level spell, then casting the next level spell won't get us a lot of reward for the extra mp. I want the algorithm to run through the following steps:a) Determine the maximum damage that the spell can do at the current spell level.b) Determine the ratio of the two spells maximum damage and mp cost. If the ratio of the maximum damage for the higher spell exceeds the ratio of its MP cost, then this indicates we should use the higher spell. If we select the higher spell, the next check is not needed.c) We determine the likelihood to be resisted. If the lower spell is significantly more likely to be resisted than the higher spell, we cast the higher spell. Note: This is a nice to have. It may not be possible to get the information necessary to make this check, but we can try.d) For this requirement, we only need to review the midcast set for skill level bonuses, unless you discover that there is something else relevant that we need to include.9) If we can determine likelihood of resistance in step C of improvement 8, we do the same for status debuffs for enemies.10) I would like for box commands to be overhauled to support a full alliance, with the other two parties appearing below the first, but only when the character actually is in an alliance."
**AI Response**: User approved reverse engineering and provided comprehensive 10-point requirements list. Proceeding to Requirements Analysis.
**Context**: Reverse Engineering approved implicitly via user providing next-phase input. Moving to Requirements Analysis.

---

## Requirements Analysis - Questions Answered
**Timestamp**: 2026-06-03T12:30:00Z
**User Input**: "I've answered the questions to the best of my ability. If any of my answers brought up additional questions, please let me know."
**AI Response**: All 12 questions answered. No contradictions detected. Analysis complete, proceeding to generate requirements document.
**Context**: Requirements Analysis Step 6 gate passed. Answers validated. Moving to Step 7 (requirements generation).

---

## Requirements Analysis - Approval
**Timestamp**: 2026-06-03T12:45:00Z
**User Input**: "Nothing else. We can move to requirements."
**AI Response**: Requirements approved. Proceeding to Workflow Planning.
**Context**: User approved requirements document after adding FR-5b (job broadcasting) and clarifications (per-job max HP, get_player() for job data). Moving to Workflow Planning stage.

---

## Workflow Planning - Approval
**Timestamp**: 2026-06-03T12:55:00Z
**User Input**: "Yes"
**AI Response**: Workflow plan approved. Proceeding to Application Design.
**Context**: User approved execution plan. Testing strategy clarified: verify after every independently testable change, group dependent sub-features. No formal unit tests. Moving to Application Design.

---

## Application Design - Questions Answered
**Timestamp**: 2026-06-03T13:10:00Z
**User Input**: "I've answered the questions. Some design decisions were made in the questions. Please update planning documentation where necessary."
**AI Response**: Questions analyzed. Key design decisions: (1) Root entry point + feature subdirectories, (2) Job/HP tracking via shared settings file instead of IPC, (3) Separate data files per system + generics file, (4) Class-based minimal UI, (5) Windower events for menu detection with packet reading fallback + 1-min safety timer. Updated FR-5b, FR-4g, FR-7f in requirements.md.
**Context**: Application Design questions answered. No contradictions or ambiguities detected. Proceeding to generate design artifacts.

---

## Application Design - Approval
**Timestamp**: 2026-06-03T13:20:00Z
**User Input**: "Yes. You can continue until you get to a point that you will need my input, or that you will start unit 0. At that point, pause. I am going to go do some things afk, so I will not be available for a bit."
**AI Response**: Application Design approved. Proceeding to Units Generation autonomously. Will pause before Unit 0 execution (requires user's in-game testing).
**Context**: Application Design complete with 4 artifact files. Moving to Units Generation. User added Step 0 (debug/stabilize baseline) with T/F/X checklist approach.

---

## Units Generation - Completed
**Timestamp**: 2026-06-03T13:30:00Z
**User Input**: (Approved as part of "continue until you need my input" directive)
**AI Response**: Units Generation completed. 9 units defined (Unit 0-8) with dependency matrix and requirements mapping. All INCEPTION stages complete. Pausing at Construction Phase boundary — Unit 0 requires user's in-game testing with T/F/X checklist.
**Context**: INCEPTION PHASE complete. All artifacts generated. Ready to begin CONSTRUCTION PHASE with Unit 0 when user returns.

---

## Unit 0 - Baseline Testing Results
**Timestamp**: 2026-06-03T22:00:00Z
**User Input**: "Alright, I have things working well enough to start. I've answered the questions. I'm going to bed. We can pick up where we left off tomorrow after work."
**AI Response**: Test results processed. 38 passing, 5 failing items + 8 noted issues. Timer bar bug fixed during session (shared texture issue + Lua iteration mutation + tonumber conversion + fit(false) for scaling). Pact table updated from SMN.lua. User going AFK, will resume tomorrow.
**Context**: Unit 0 testing in progress. Pre-existing bugs identified. Fixes needed for: storm/helix target order, timer creation for spells, astralflow pact key, avatar release error, duplicate cast, caster validation, self-only targeting, macro switching.

---
