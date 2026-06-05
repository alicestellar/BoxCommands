# Application Design Plan

## Plan Steps

- [x] Define module/component structure for the redesigned addon
- [x] Define component responsibilities and boundaries
- [x] Define component methods (interfaces)
- [x] Define service/orchestration layer (IPC protocol, command routing)
- [x] Define component dependencies and communication patterns
- [x] Validate design completeness

---

## Design Questions

Please answer the following questions to guide the application design.

## Question 1
The current addon is 4 files with loosely separated concerns. For the redesigned addon, how would you like the file/module structure organized?

A) Keep a similar flat structure but with clearer separation (e.g., settings.lua, ui.lua, targeting.lua, spells.lua, ipc.lua)

B) Group by feature with subdirectories (e.g., ui/headers.lua, ui/timers.lua, algorithms/healing.lua, algorithms/nuking.lua)

C) Minimal files — keep it simple, just split the current files more cleanly (main, commands, helpers, data, settings)

D) Other (please describe after [Answer]: tag below)

[Answer]: D
BoxCommands needs to be in the root folder of the directory, because that is where Windower will look for it. The rest of the files can be handled in the way described in option B.

## Question 2
For the IPC protocol expansion (job broadcasting, stat sharing), should the IPC commands be:

A) Prefixed with a namespace to avoid collision with other addons (e.g., `box ipc:jobupdate`, `box ipc:jobrequest`)

B) Flat commands like the current ones (e.g., `box jobupdate`, `box jobrequest`)

C) Other (please describe after [Answer]: tag below)

[Answer]: C
I just realized that the characters can set their jobs in the main settings file during runtime, and we can just retrieve their job from there. No need for send commands at all.

## Question 3
For the settings file structure, how should per-character data (max HP overrides, potency values, macro books) be organized?

A) One XML settings file with sections per character (all in one file)

B) Main settings XML for global config + separate per-character files (one file per character in a subfolder)

C) Other (please describe after [Answer]: tag below)

[Answer]: C
I just realized that we can update this programmatically. I do want the data saved to the settings file, so it will be in the main settings file. We will use the get_player() functionality to update the HP in the settings file during run time, but only when the character changes jobs. This will be updated in the same function that updates the character's job, though we may need to "post date" the update a bit to allow time for their gear to load properly. If they change max hp due to changing gear, we can force an update to this information by running the setup command. This update also applies to question 2.

## Question 4
The healing and nuking algorithms will need lookup tables for spell base potencies, damage formulas, and similar game data. Where should this static game data live?

A) In data_tables.lua alongside existing game data (keep all static data together)

B) In separate files per system (e.g., healing_data.lua, nuking_data.lua) to keep them focused

C) Other (please describe after [Answer]: tag below)

[Answer]: C
We use B, but if there are tables that more than one lua uses, we abstract them out into a "generics" file.

## Question 5
For the UI component (timers, headers, arrows), should we build a lightweight UI framework similar to XivParty's class-based approach (uiElement base class with subclasses), or keep it simpler with direct image/text manipulation like the current code?

A) Build a simple class-based UI system (base element with position/visibility, subclasses for bars, text, images) — more maintainable for the UI complexity we're adding

B) Keep direct manipulation but organize into well-named utility functions — simpler, less abstraction

C) Other (please describe after [Answer]: tag below)

[Answer]: A
Please note that I still need to see the screen, so I don't want a background to just stretch across everything. We're already taking up a lot of real estate in game. Make sure we keep the UI fairly minimal. If we can push the bars closer together, or make things smaller, while still being legible, that would be amazing.

## Question 6
For the menu-hide feature (FR-4f), the detection typically uses either incoming packets (to detect menu open/close events) or polling game state. Given your packet safety preference, which approach:

A) Use packet reading to detect menu state changes (more reliable, you said reading is acceptable with notification)

B) Poll game state periodically to detect menu visibility (less reliable but no packet involvement)

C) Use Windower's event system if there are relevant events for menu state

D) Other (please describe after [Answer]: tag below)

[Answer]: D
Use C when we can. You can use A if we don't have access to C. If the UI has been "hidden behind the UI" for longer than a minute, check to make sure you didn't miss a packet or event. You can use whatever you need to make sure the UI doesn't just disappear and fail to come back, but make sure that you only make these checks when the UI is hidden. Don't just check every minute, even if the UI is currently showing.