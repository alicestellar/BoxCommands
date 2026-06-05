# Unit 0: Baseline Test Checklist

Mark each item with:
- **t** = Working correctly
- **f** = Broken / not working as expected
- **x** = Cannot test right now (will be deferred)

If marking **f**, please add a brief note about what happened (e.g., "error in chat", "nothing happened", "wrong target").

---

## Addon Loading & Setup

- [t] Addon loads without errors when Windower starts (`//lua load boxcommands`)
- [t] `//box setup` executes without errors
- [t] Keybinds are registered after setup (Ctrl+F1-F6 and Alt+F1-F6 respond)
- [t] Column headers appear on screen after loading

## Caster & Target Management

- [t] `//box setcaster <name>` changes the active caster (verify with caster icon moving)
- [t] `//box target <name>` changes the target for abilities
- [t] `//box target <t>` sets target to current game target
- [t] Alt+F1 through Alt+F6 set target for all boxes to the corresponding character
- [t] Alt+` sets target to `<t>` for all boxes
- [t] Caster icon appears next to the correct character header
- [t] Target icon appears next to the correct character header

## Script Execution (Ctrl+F keybinds)

- [t] Ctrl+F1 executes Makaria.txt (sets caster + macro book)
- [t] Ctrl+F2 executes Amaranti.txt
- [t] Ctrl+F3 executes Aenura.txt
- [t] Ctrl+F4 executes Midnaria.txt
- [t] Ctrl+F5 executes Entrapta.txt
- [t] Ctrl+F6 executes Luccaria.txt

## Spell Casting (//box cast)

- [t] `//box cast cure` — casts highest available Cure tier on caster's box
- [t] `//box cast cure` with caster set to a different character — command relays via IPC and executes on remote box
- [t] `//box cast protect` — casts highest Protect on target
- [t] `//box cast haste` — casts Haste on target
- [x] Multi-word spell: `//box cast cure IV` or `//box cast utsusemi` — handles correctly
- [t] Spell with insufficient MP — does NOT attempt to cast, shows error or skips gracefully
- [t] Spell on recast — does NOT attempt to cast

## Job Abilities (//box ja)

- [t] `//box ja provoke` — executes Provoke on target
- [t] `//box ja` with multi-word ability (e.g., `//box ja divine seal`) — works correctly
- [t] `//box ja` relays to remote caster via IPC when not local

## Pet Commands (//box pet)

- [t] `//box pet assault` — executes pet Assault command (if Summoner/Puppet available)
- [t] `//box pet retreat` — executes pet Retreat
- [t] `//box pet` relays to remote caster when not local

## BST Pet Commands (//box bstpet)

- [x] `//box bstpet <ability>` — executes BST pet ability (if Beastmaster available)
- [x] Relays correctly to remote caster

## Summoner Pacts (//box pact)

- [t] `//box pact cure` — executes appropriate healing pact for active avatar
- [t] `//box pact bp70` — executes appropriate physical BP for active avatar
- [t] `//box pact bp75` — executes appropriate magical BP for active avatar
- [t] `//box pact buffoffense` — executes buff pact for active avatar
- [t] Error message appears if no avatar is active
- [t] Error message appears for unknown pact category
- [t] Pact targets correctly (enemy pacts hit `<t>`, self pacts hit `<me>`)
- [t] Pact relays to remote caster when not local

## Scholar Elemental Commands

- [f] `//box storm` — casts appropriate elemental storm based on day/weather
- [f] `//box helix` — casts appropriate elemental helix based on day/weather
- [x] Storm/helix picks weather element over day element when weather intensity is 2
- [x] Storm/helix picks day element when no weather or weak weather

## Timer System

- [f] After casting a spell, a timer bar appears in the correct column
- [t] Timer bar counts down visually (foreground shrinks)
- [t] Timer bar disappears when countdown reaches zero
- [t] Multiple timers stack vertically in the same column
- [t] Timer bars reposition correctly when one expires (no gaps)
- [t] `//box timerui` received from another box creates a timer locally
- [t] Timer bars appear on ALL boxes (not just caster) after a cast

## Macro Commands

- [t] `//box macro default` — switches to macro book 1, set 1
- [f] `//box macro 1 main` — switches to appropriate macro page for party slot 1

## UI Display

- [t] All 6 column headers visible and correctly positioned
- [t] Headers display character names in uppercase
- [t] Timer bars appear below their respective column headers
- [t] No visual overlapping between columns
- [t] UI elements don't cause Windower errors or crashes

## Edge Cases & Error Handling

- [t] Casting an invalid/unknown spell name — shows error message, doesn't crash
- [f] Setting caster to a name not in the party — behavior is graceful
- [t] Running commands before setup — no crash
- [t] Loading addon with no party (solo) — no crash

---

## Deferred Testing List

Items marked **x** above will be tracked here for re-testing in later units:

| Item | Reason Deferred | Re-test In |
|------|----------------|------------|
| | | |

---

## Notes

Add any observations, unexpected behaviors, or additional issues here:

```text
1. This is as intended, but when casting a spell that has a "lower level" (Cure IV vs Cure III)
when the higher level spell is on cooldown or you have insufficient mp for the higher level spell, the first available spell below the one selected by the "highest level spell" algorithm is cast instead.

2. When a spell is cast, regardless of whether you can cast spells at the time, a warning that
"You cannot cast spells at this time" is generated if you use a box command to cast the spell.
I believe that there is some kind of duplicate casting logic.

3. Box Pact Astral does not currently work. It causes an error.
The error is generated at libs/images.lua 253
The error text is "attempt to index local 'm' (a nil value)

4. Releasing an avatar an error in libs/images.lua that repeats indefinitely.
It is an attempt to index field '?' (a nil value)

5. Storms and Helixes use a previous version of box commands (they try to run with target before spell) so the target is included in the spell name and it fails.

6. Timers do not appear for spells. They do seem to appear for pacts. They do not seem to appear for other job ability based commands. I'm not sure what all they do and do not appear for.

7. You should not be able to set the caster to someone outside your party. You can currently do that.

8. Light arts did not default to casting on self, despite the fact I think it is self only. We should review targeting heavily.
```
