# Unit 0: Retest Checklist

These items need retesting after the fixes applied today. Mark with **t** (working), **f** (still broken), or add notes.

---

## Fixes Applied This Session

### Storm/Helix (was: target included in spell name)
- [ ] `//box storm` — casts appropriate storm spell on self
- [ ] `//box helix` — casts appropriate helix spell on current target

### Pact Astralflow (was: error in images.lua)
- [ ] `//box pact astralflow` — executes Astral Flow pact for active avatar
- [ ] No images.lua error after executing astralflow pact

### Avatar Release (was: repeating error in images.lua)
- [ ] Release avatar (dismiss pet) — no repeating errors in chat
- [ ] Timer bars continue functioning normally after avatar release

### Macro Switching (was: error accessing party data)
- [ ] `//box macro default` — switches to macro book 1, set 1 without error

### Macro Switching — Job-Based (DEFERRED to Unit 2)
Note: `//box macro 1 main` requires job-aware settings file to work properly. Testing deferred.

### Timer System (confirm previous fixes still hold)
- [ ] Timers appear for spells after casting
- [ ] Timers appear for pacts after using blood pacts
- [ ] Timers appear for job abilities
- [ ] Multiple timers stack and expire cleanly (no errors)
- [ ] Background bars are correctly scaled (not comically large)

---

## Previously Passing Items (Spot Check)
Quick spot check to make sure we didn't regress anything:

- [ ] `//box cast cure` — still works
- [ ] `//box setcaster <name>` — still works
- [ ] `//box pact bp70` — still works
- [ ] Ctrl+F1 script — still works
- [ ] Alt+F1 target — still works

---

## Known Deferred Items (NOT testing now)
These are acknowledged issues that will be fixed in later units:

| Issue | Deferred To |
|-------|-------------|
| Caster can be set to non-party member | Unit 2 (Settings validation) |
| Light Arts doesn't default to self target | Unit 4 (Intelligent Targeting) |
| Self-only spells don't force `<me>` | Unit 4 (Intelligent Targeting) |
| Duplicate "cannot cast" warning | Likely GearSwap interaction, not BoxCommands |
| `//box macro N main` job-based switching | Unit 2 (Settings with job config) |

---

## Notes

```text

```
