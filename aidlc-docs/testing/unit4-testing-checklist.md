# Unit 4 Testing Checklist - Intelligent Target Resolution

## FR-6a: Self-Only Abilities

- [ ] Cast a self-only spell (e.g., Sneak, Invisible, Stoneskin) while targeting an enemy → should cast on `<me>`
- [ ] Cast a self-only spell while targeting a party member → should cast on `<me>`
- [ ] Cast a self-only spell while targeting self → should work normally
- [ ] Use a self-only JA (e.g., Berserk, Defender) while targeting an enemy → should target `<me>`

## FR-6b: Enemy-Only Abilities

- [ ] Cast an enemy-only spell (e.g., Fire, Stone, Dia) while targeting a party member → should switch to `<bt>`
- [ ] Cast an enemy-only spell while targeting an enemy → should use current target
- [ ] Use an enemy-only JA while targeting a party member → should switch to `<bt>`

## FR-6c: Friendly-Only Abilities with Enemy Target

- [ ] Cast Cure while targeting an enemy (non-undead) → should fall back to `<me>` (can target self)
- [ ] Cast Protect/Shell while targeting an enemy → should fall back to `<me>` (can target self)
- [ ] Cast Haste while targeting an enemy → should fall back to `<me>` (can target self)
- [ ] Use a party-only JA that CAN target self (e.g., Cover, targets=5) while targeting enemy → should fall back to `<me>`
- [ ] Use a party-only JA that CANNOT target self (e.g., Devotion, targets=4) while targeting enemy → should fail naturally (no redirect)

## FR-6d: Healing on Undead (Toggle-Based)

- [ ] `//box undead` toggles mode and shows chat message
- [ ] Undead mode OFF: Cast Cure while targeting an enemy → should fall back to `<me>`
- [ ] Undead mode ON: Cast Cure while targeting an enemy → should cast on the enemy
- [ ] Undead mode ON: Cast non-healing spell (e.g., Haste) while targeting enemy → should still fall back to `<me>` (Haste can't target enemies)
- [ ] Undead mode persists across spell casts (doesn't reset after one use)
- [ ] Undead mode resets on addon reload (defaults to OFF)

## FR-6e: BST Pet Abilities Always Target Self

- [ ] Use `//box bstpet 1` while targeting an enemy → should use `<me>` (pet resolves own target)
- [ ] Use `//box bstpet Foot Kick` while targeting a party member → should use `<me>`
- [ ] Use `//box bstpet 2` while not engaged → verify no error, command goes through with `<me>`
- [ ] Verify Ready timer still appears correctly after bstpet use

## Mixed Scenarios

- [ ] Set target to a character name, then cast an enemy spell → should switch to `<bt>`
- [ ] Set target to `<bt>`, then cast a friendly spell → should fall back to `<me>`
- [ ] Verify pact commands (SMN) still resolve targets correctly (uses its own logic in handle_dynamic_pact)
- [ ] Verify stratagems (self-only, targets=1) always target `<me>`

## Edge Cases

- [ ] Cast spell with no target set (target = '') → verify no crash
- [ ] Cast spell while target is `<t>` but nothing is targeted in game → verify graceful handling
- [ ] Verify that Waltzes (targets=63, can hit self/party/enemy) still use current target as-is

## Regression Checks

- [ ] Timer bars still appear correctly for all spell types
- [ ] Charge timers (Ready, Stratagems) still work
- [ ] Timer file sync still works between boxes
- [ ] Menu hiding still works for all UI elements

## Weapon Skill Command (new)

- [ ] `//box ws Savage Blade` executes the weapon skill on the caster
- [ ] WS routes to the active caster via IPC when caster is a different box
- [ ] WS executes locally when caster is the local box
- [ ] WS targets `<bt>` / `<t>` correctly when an enemy is targeted (FR-6 resolution)
- [ ] WS with current target set to a party member resolves to `<bt>` (most WS are enemy-only)
- [ ] Multi-word WS names (e.g., "Savage Blade", "Resolution") parse correctly
- [ ] No recast timer is created for weapon skills (TP-based, expected)
