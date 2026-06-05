# Requirements Verification Questions

Please answer the following questions to help clarify the requirements. Fill in the letter choice after each [Answer]: tag.

---

## Question 1
Regarding the Windower documentation (Requirement 1): Given that I can reference Windower APIs on-demand during implementation, would you prefer:

A) No on-disk reference — I will look up APIs as needed during construction

B) A lightweight reference document listing only the Windower APIs that BoxCommands uses (functions, events, libraries)

C) Full Windower documentation imported to aidlc-docs

D) Other (please describe after [Answer]: tag below)

[Answer]: A

## Question 2
For Requirement 4b (text appearance), you mentioned an example addon you can reference. Which addon should I look at for the text style you want?

A) I will provide the addon name or screenshot later when we get to that requirement

B) I want the Windower default text style but with a shadow/outline for readability

C) I want a specific font/size — I will describe it here

D) Other (please describe after [Answer]: tag below)

[Answer]: D
XivParty. It is pasted the entire addon into the Scripts folder.
The party names are displayed in a way I find aesthetically pleasing.

## Question 3
For Requirement 4c/4d (animated arrows), do you have access to the FFXI Pointer UI assets, or would you need me to help source/create an animated arrow graphic?

A) I have the FFXI Pointer UI assets and can provide them

B) I need help finding or creating an appropriate animated arrow

C) I am okay with a simple non-animated arrow if animated is too complex

D) Other (please describe after [Answer]: tag below)

[Answer]: D
I am okay with a simple non-animated arrow if we can't animate it.
I have provided the arrow file in the scripts folder.
What I want is for the arrow to "float" back and forth, from left to right, slowly.

## Question 4
For Requirement 4f (UI layering behind game menus), Windower image/text primitives have limited z-order control. The typical approach is to detect when certain game events occur (menu open/close) and hide the UI. Would you accept:

A) Auto-hide the entire BoxCommands UI when game menus are detected open, and restore when closed

B) Auto-hide only the overlapping elements (leftmost column headers) when menus open

C) Manually toggle UI visibility with a keybind when menus are in the way

D) Other (please describe after [Answer]: tag below)

[Answer]: D
A is the easiest. We will implement that immediately, and work on B menu by menu.
Each menu will only have the elements hiding that need hiding when we fix that one for B.
If the menu has not been worked for B, then we default to A.

## Question 5
For Requirement 4g (settings file), Windower addons typically use the built-in `settings` library which creates XML config files. Would this approach work for you?

A) Yes — use Windower's built-in settings library (XML format, auto-created on first load)

B) I prefer a Lua table config file (like GearSwap uses)

C) I prefer JSON or YAML format

D) Other (please describe after [Answer]: tag below)

[Answer]: D
The primary settings file can be XML. We will need another settings file for each character that contains their midcast sets once we do the improved spell selection.

## Question 6
For Requirement 5 (moving script logic into addon), the current scripts (Ctrl+F1-F6) execute text files that presumably set caster + macro. What exactly does each character script do? (I need to know what operations to replicate)

A) Each script sets the caster to that character AND switches to that character's macro book/set

B) Each script sets the caster to that character only (macro switching is separate)

C) Each script does caster + macro + other actions (please describe after [Answer]: tag below)

D) Other (please describe after [Answer]: tag below)

[Answer]: A
Please note that the file does this for EVERY box using send commands.

## Question 7
For Requirement 7 (healing algorithm), the algorithm needs to know the target's current HP deficit. In a multi-box setup, can you reliably get other characters' HP values via Windower APIs, or only for characters in your own party?

A) I can get HP% for all party members via the party data API (this is sufficient)

B) I need exact HP values, not just percentages

C) I am okay with the algorithm only working for the local character (self-heals)

D) Other (please describe after [Answer]: tag below)

[Answer]: A
We will fallback to an estimate of max hp based on job, race, and level/ilvl.
If there is a hard coded max hp in the settings file, we use that instead.
Percentage then allows us to calculate the hp we need.

## Question 8
For Requirement 7b (GearSwap midcast sets), how do you envision the integration? GearSwap lua files have complex conditional logic. Would you:

A) Maintain a separate simplified file per character listing their healing midcast stats (cure potency, MND, etc.) that BoxCommands reads

B) Have BoxCommands parse the actual GearSwap lua files to extract midcast sets

C) Have a shared data file that both GearSwap and BoxCommands reference

D) Other (please describe after [Answer]: tag below)

[Answer]: D — Resolved via discussion. Approach: Capture stats (MND, INT, skill levels, buffs) during midcast via get_player() on the local caster instance, cached per job+spell category. Always "one cast behind" which is acceptable. For Cure Potency and similar multipliers that cannot be captured via API: provide optional fields in the settings file for (1) caster-side healing potency bonuses (cure potency %, etc.) and (2) receiver-side healing received bonuses. These are opt-in — algorithm works on MND + skill alone by default, user can tune with potency values if desired.

## Question 9
For Requirement 10 (alliance support), how many characters do you typically run in an alliance scenario?

A) Full 18 characters (3 parties of 6)

B) 12 characters (2 parties of 6)

C) Variable — anywhere from 7 to 18

D) Other (please describe after [Answer]: tag below)

[Answer]: C

## Question 10
What priority order would you prefer for implementation? (This helps me plan units of work)

A) Documentation/cleanup first (2, 3), then UI (4), then features (5, 6, 7, 8, 9, 10)

B) Settings/config first (4g, 4h, 5), then UI visual improvements (4a-f), then algorithms (6, 7, 8, 9, 10)

C) Whatever order minimizes rework and builds on previous changes logically

D) Other (please describe after [Answer]: tag below)

[Answer]: A
Please keep up with the documentation as we proceed.
I want all functions and commands we generate to be labeled.
If you need to update the Readme, do so.

## Question 11: Security Extensions
Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)

C) Other (please describe after [Answer]: tag below)

[Answer]: C
If you ever feel that it is necessary to use packets, I want to know, and I want to approve it before you move forward with it. Modifying packets can get you banned, so I would like to avoid using that option if at all possible. Reading packets, however, is fine if strictly necessary. I still want to be notified for reading, though.

## Question 12: Property-Based Testing Extension
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

D) Other (please describe after [Answer]: tag below)

[Answer]: C
