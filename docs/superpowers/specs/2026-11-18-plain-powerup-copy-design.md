# Plain-Language Power-Up Copy — Design

## Intent
Power-up cards currently read like programmer notes ("Hitbox jab +30px", "Dash i-frame +0.15s",
"guard-break 0.5s"). Rewrite names/descriptions/category badges so a casual player understands
them instantly. No numerical values in descriptions — the "STACK x2" badge still shows stacks.

## Copy (approved)
| id | old desc | new desc |
|---|---|---|
| fist_heavy | Jab +2 damage | Punches hit harder |
| fist_launch | 3rd jab launches (heavy) | Final punch sends enemies flying |
| fist_reach | Hitbox jab +30px | Your fists reach farther |
| move_reflex | Dash i-frame +0.15s | More time to dodge after a hit |
| move_footwork | Dash cooldown -0.2s | Dash again sooner |
| move_breath | Cash-in +1 / wave | One extra cash-in each wave |
| aff_heart | +3 heal / ♥ card | ♥ cards heal you |
| aff_spade | +2 damage / ♠ card | ♠ cards hit harder |
| aff_club | +0.15s stun / ♣ card | ♣ cards freeze enemies |
| aff_diamond | +0.25s shield / ♦ card | ♦ cards protect you |
| finisher | J/Q/K/A = guard-break 0.5s | Face cards break enemy guard |

Category display badges: FIST→STRIKE, MOVEMENT→AGILITY, AFFINITY→SUIT POWER, FINISHER stays.

## Implementation
- `powerup_data.gd`: replace `desc` strings; add `cat_label` field per def.
- `shop_ui.gd`: `cbadge.text = def.get("cat_label", cat)`; keep `_cat_color(cat)` keyed on internal
  `cat` (FIST/MOVEMENT/AFFINITY/FINISHER) so color coding doesn't break.
- Keep `STACK x%d` / `NEW` badge numbers (operator chose no numbers in *description* only).

## Constraints
- No gameplay/effect change. No ID/cat key change (IDs used in run_manager powerups dict).
- All 16 suites green.
