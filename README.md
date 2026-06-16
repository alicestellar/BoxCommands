# BoxCommands

A Windower addon for FFXI that enables multi-boxing by routing spell, ability, and pet commands to designated characters via IPC. Includes a visual recast timer UI with per-character columns.

## Installation

1. Copy the `BoxCommands` folder into your Windower `addons` directory:

   ```
   Windower/addons/BoxCommands/
   ```

2. Load the addon in-game:

   ```
   //lua load BoxCommands
   ```

## Command Reference

All commands use the prefix `//box`.

### Setup & Configuration

| Command | Usage | Description |
|---------|-------|-------------|
| `setup` | `//box setup` | Binds hotkeys: Ctrl+F1-F6 for character scripts, Alt+F1-F6 for targeting, Alt+\` for `<t>` |
| `setcaster` | `//box setcaster <name>` | Set the active caster character. Subsequent commands route to this character. |
| `target` | `//box target <target>` | Set the target for spells/abilities. Accepts character names, `<t>`, `<me>`, `<bt>`, etc. |
| `macro` | `//box macro <slot> <main\|sub>` | Switch macro book based on party slot and job type. |
| `macro` | `//box macro default` | Reset to default macro page (book 1, set 1). |

### Casting & Abilities

| Command | Usage | Description |
|---------|-------|-------------|
| `cast` | `//box cast <spell>` | Cast the highest available tier of a spell. Auto-selects tier based on MP, recast, and access. |
| `ja` | `//box ja <ability>` | Execute a job ability on the current target. |
| `pet` | `//box pet <ability>` | Execute a pet command (SMN ward, PUP maneuver, DRG breath). |
| `bstpet` | `//box bstpet <ability>` | Execute a BST pet command. |
| `pact` | `//box pact <category>` | Execute a Blood Pact by category for the active avatar. |
| `storm` | `//box storm` | Cast the optimal storm spell based on current weather/day element. |
| `helix` | `//box helix` | Cast the optimal helix spell based on current weather/day element. |

### Pact Categories

Used with `//box pact <category>`:

- `cure`, `curaga` — Healing pacts
- `buffoffense`, `buffdefense`, `buffspecial` — Buff pacts
- `debuff1`, `debuff2`, `sleep` — Debuff pacts
- `nuke2`, `nuke4` — Elemental nukes (tier II / tier IV)
- `bp70`, `bp75` — Physical/merit blood pacts
- `rage`, `rage2`, `rage3`, `finalrage` — Rage pacts
- `astralflow` — Astral Flow pacts (auto-activates Astral Flow JA if needed)
- `astralward`, `finalward` — Special ward pacts

### Timer Commands (Internal)

These are used internally by the addon for cross-character timer synchronization:

| Command | Usage | Description |
|---------|-------|-------------|
| `pretimer` | `//box pretimer <caster> <type> <castTime> <ability>` | Schedule a timer after cast time elapses. |
| `timer` | `//box timer <caster> <type> <ability>` | Query recast and create a timer bar. |
| `timerui` | `//box timerui <dur> <charge> <caster> <type> <col> <ability>` | Create a timer bar directly with explicit parameters. |

### Examples

```
//box setcaster Amaranti
//box target <t>
//box cast cure
//box ja "Divine Seal"
//box pact bp75
//box storm
//box helix
//box macro 2 main
//box target Makaria
//box cast haste
```

## Version History

- **1.2.0** — Documentation pass and dead code cleanup. No functional changes.
- **1.1.1** — Baseline version with full multi-box command routing, smart spell tier selection, Blood Pact system, and image-based recast timer UI.
