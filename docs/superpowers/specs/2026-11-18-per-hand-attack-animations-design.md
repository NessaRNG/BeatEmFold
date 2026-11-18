# Per-Hand Attack Animation Director — Design

## Intent
Give each of the 9 poker hands a distinct attack visual when cashed in, so the player feels the
difference between a High Card and a Straight Flush. Pure presentation — no damage/target logic
change. Reuse existing character poses; no new sprite art (avoids the stiff code-drawn look).

## Decisions (approved)
FX + signature pose per hand. Each hand type defines:
- pose (existing sprite animation to play on player),
- slash FX count / frame / color / scale,
- particle burst color + count,
- flash color + strength, hitstop, callout color + tween style, and a small lunge/zoom.

## Hand → signature map (proposed, escalation by rank)
| Hand | Pose | Slash | FX color | Flash | Stop | Callout style |
|---|---|---|---|---|---|---|
| HIGH CARD | jab | 1, cyan | #7fdfff | faint | 0.12 | small, white |
| PAIR | hook | 1, blue | #5aa9ff | low | 0.14 | pop, blue |
| TWO PAIR | hook | 2 crossing, blue | #5ad9ff | low | 0.16 | pop x2, cyan |
| THREE | upper | 2, violet | #b06bff | med | 0.18 | pop, violet |
| STRAIGHT | upper | 3 piercing line, gold | #ffd94d | med | 0.2 | slide, gold |
| FLUSH | hook | 4 radial, teal | #5affd2 | med | 0.22 | spin, teal |
| FULL HOUSE | upper | 5 burst, magenta | #ff5fd2 | high | 0.24 | pulse, magenta |
| FOUR | upper | 6 radial, orange | #ff9f40 | high | 0.26 | shake-in, orange |
| STRAIGHT FLUSH | upper | 8 radial + big, white/gold | #fff3a0 | max | 0.3 | explode, gold |

## Constraints / test contracts
- `cash_in_resolved` signal already carries hand_name/damage/targets — main.gd's
  `_on_cash_resolved` is the hook. Need hand **type index** too: add `hand_type` param to the signal
  (test_step13 doesn't connect the signal; safe).
- Existing tests check: text names, no gameplay change, 14 suites green.
- FX queue_free after tween; no leaks. Guard `is_instance_valid(player)`.
- Sealed hands still resolve (may show muted FX) — no crash.
- Slow-mo controller (time_scale) is unaffected; hitstop goes through it.
