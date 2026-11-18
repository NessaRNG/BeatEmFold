# Power-Up Affinity Implementation Plan

> REQUIRED SUB-SKILL: superpowers:executing-plans.

**Goal:** Add stackable fighter power-ups with a Suit-Affinity card bridge and a free 1-of-3
wave-clear pick, without breaking the flat poker model or the 12 smoke tests.

**Architecture:** New `powerup_data.gd` (static defs + roll). `RunManager` owns counts.
`CombatManager` applies affinity/finisher on cash-in. `Player` applies fist/move effects.
`Dummy.break_guard()`. `ShopUI` shows a separate 3-button pick panel (rows stays 2).
`main.gd` wires player→run_manager and calls roll on shop open.

**Tech Stack:** Godot 4.7 GDScript.

**Spec:** `docs/superpowers/specs/2026-11-18-powerup-affinity-design.md`

## Global Constraints
- `shop.rows.size() == 2` (test_step4). Power-up buttons live in a separate node.
- Default no-powerup behaviour identical to current (all tests instantiate fresh RunManager).
- Flat TABLE damage unchanged; affinity adds small flat effects only.

### Task 1: Data + state
- [ ] Step 1: Create `scripts/powerup_data.gd` with defs + `roll(owned)`
- [ ] Step 2: Extend `run_manager.gd` with counts, `add_powerup`, `powerup_count`, `roll_choices`, `hands_per_wave`

### Task 2: Combat + player effects
- [ ] Step 1: `combat_manager.gd` — affinity per-card effects + finisher guard-break (skip sealed)
- [ ] Step 2: `dummy.gd` — `break_guard()`
- [ ] Step 3: `player.gd` — fist damage/reach/launch, move reflex/footwork/breath hooks

### Task 3: UI + wiring
- [ ] Step 1: `shop_ui.gd` — separate 3-button power-up panel, `on_powerup_picked`
- [ ] Step 2: `main.gd` — wire player.run_manager, roll choices on shop open, apply breath budget
- [ ] Step 3: Add a focused smoke test `tests/test_step13_powerups.gd`
- [ ] Step 4: Run all 13 suites, fix, commit
