# Animation Smoothing Design

## Intent
Eliminate the stiff/choppy feel of the original-vector brawler sprites.

## Root cause
Attacks had only 2 frames (windup -> snap): no acceleration, no follow-through.
Idle (4) and walk (6) had coarse transitions.

## Approach (chosen: 1 + 2 combo)
1. **More frames with eased timing**
   - idle: 4 -> 6 frames, sinusoidal breathing
   - walk: 6 -> 8 frames, smooth A/mid/B/mid cycle
   - jab / hook / upper: 2 -> 5 frames each (guard -> coil -> mid -> full -> recover)
   - per-frame durations in Godot: long windup, short snap, short follow-through, long recover
2. **Motion smear**
   - translucent after-image of the previous pose drawn behind fast attack frames
   - baked into the frame pixels (no engine blending, no blur/shimmer on pixel art)

## Constraints
- Animation names unchanged: idle/walk/jab/hook/upper/hit.
- `hit` keeps using a guard-ish frame (frame 1).
- 12 smoke tests stay green; no gameplay/timing logic changes.
- Sheet layout indices in `scripts/char_sprites.gd` must be updated to match new frame counts.

## New layout (29 frames @ 128x96 = 3712x96)
- idle 0-5 (6), walk 6-13 (8), jab 14-18 (5), hook 19-23 (5), upper 24-28 (5)
