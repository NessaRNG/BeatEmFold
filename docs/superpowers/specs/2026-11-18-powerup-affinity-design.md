# Power-Up System — "Afinitas Suit" Design

## Intent
Give the player real growth that answers enemy scaling, **without turning the game into Balatro**.
Power-ups upgrade the *fighter* (fists, movement) and add a light *bridge* that makes individual
cards matter — without touching the flat poker damage table, Chips×Mult, hand size, or poker rules.

## Decisions (approved by operator)
- Damage table stays flat (Pair = 25, Straight Flush = 200). No Chips×Mult.
- Bridge = **Suit Affinity**: power-ups bind a suit; each card of that suit in a cash-in gives a
  small flat physical effect (tipis-sedang values).
- High cards J/Q/K/A = finisher ammo → guard-break (0.5s stagger, cancels telegraph).
- Power-ups are chosen **1 of 3, free**, after each wave clear — this is the growth mechanism.

## Power-up pool (11, all stackable by count)
| id | category | effect per stack |
|---|---|---|
| fist_heavy | tinju | jab damage +2 |
| fist_launch | tinju | 3rd jab becomes launcher (heavy) |
| fist_reach | tinju | jab hitbox width +30px |
| move_reflex | gerak | dash i-frame +0.15s |
| move_footwork | gerak | dash cooldown -0.2s (floor 0.1) |
| move_breath | gerak | cash-in budget +1/wave |
| aff_heart | affinity | +3 heal per ♥ card in cash-in |
| aff_spade | affinity | +2 damage per ♠ card in cash-in |
| aff_club | affinity | +0.12s stagger per ♣ card in cash-in |
| aff_diamond | affinity | +0.25s shield per ♦ card in cash-in |
| finisher | finisher | J/Q/K/A in cash-in → guard-break 0.5s |

## Why this is not Balatro
- No second scoring layer, no rank value, no hand-size change, no poker rule change.
- Cards still determine damage tier + AoE shape exactly as before.
- Affinity only adds small **physical** effects (heal/stun/shield/+2 dmg) tied to suit identity.

## Integration points (verified)
- `run_manager.gd`: `powerups: Dictionary`, `add_powerup`, `powerup_count`, `roll_choices`,
  `hands_per_wave()` used by `reset_for_wave` (keeps default 4 for tests).
- `scripts/powerup_data.gd`: static defs + `roll()` (3 distinct picks, prefers unowned).
- `combat_manager.gd`: affinity effects + finisher in `try_cash_in()` (skip when sealed).
- `player.gd`: fist/move effects read from `run_manager` ref; `run_manager` wired in main.gd.
- `dummy.gd`: `break_guard()` cancels telegraph + staggers.
- `shop_ui.gd`: separate `powerup_panel` with 3 buttons — NOT in `rows` (test_step4 requires
  `rows.size() == 2`), does not block `close_shop()`.

## Constraints
- All 12 smoke tests stay green. Default RunManager (no powerups) behaves identically to today.
- `hit` stays frame 1; 29-frame sheets unchanged.
