# Original Vector-Drawn Brawler Sprites — Design

## Intent
Create 100% original character sprites from scratch with code: no downloaded packs, no AI generation.
Replace the stiff boxy procedural sprites with organic, proportional arcade-brawler characters drawn
with tapered polygons, joint circles, multi-tone shading, fabric folds, hair, and a full skeletal pose
system (anticipation / follow-through).

## Goals
- 3 characters (player / enemy / boss), each a 16-frame sheet: idle 4, walk 6, jab 2, hook 2, upper 2.
- Frame 128x96, feet aligned to bottom, sheet 2048x96, nearest-filter friendly.
- Proportional 6-7 head athletic anatomy, readable silhouette, no big heads.
- Distinct identity per character via palette + hair + outfit details.

## Non-goals
- Strict single-palette pixel art (we supersample and downsample for smooth arcs).
- New animation timing / gameplay (frames map to existing `idle`, `walk`, `jab`, `hook`, `upper`).

## Approach chosen
Skeleton-based vector drawing: define joint coordinates per pose, draw limbs as tapered polygons with
joint discs, torso as a shaped polygon with shading and folds, head with hair spikes / mohawk / sunglasses.
Supersample 4x then LANCZOS-downsample for anti-aliased curves. Border chroma key + normalize in
`tools/slice_ai_sprites.py` remains unused; generator writes final sheets directly.

## Constraints
- Names: `original_player_sheet.png`, `original_enemy_sheet.png`, `original_boss_sheet.png`.
- Grid 128x96; `scripts/char_sprites.gd` already reads 128x96 frames.
- All 12 smoke tests must stay green.
