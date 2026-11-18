# Original Layered Stage Backgrounds — Design

## Intent
Replace the flat single-image alley and the procedural ColorRect rooftop/bar with **100% original,
code-drawn, layered pixel-art backgrounds** for all 3 stages. No downloaded packs, no AI, no
third-party art. Match the neon-arcade identity established by the UI/character work.

## Stages & visual direction
- **ALLEY (0)** — night rain: deep indigo→violet gradient sky, moon + halo, distant skyline with
  lit windows, red/orange brick wall with mortar/soot/posters/fire-escape, wet asphalt with neon
  puddle reflections, rain streaks. Code neon "K.O. BAR"/"24H" + lamp stay on top (flicker).
- **ROOFTOP (1)** — sunset: orange→magenta gradient, hazy sun, city silhouette, water tower, AC
  units, railing, antenna, gravel floor. Code neon "ROOFTOP".
- **BAR (2)** — neon interior: dark wood panels, bottle shelves (colored bottles), hanging stage
  lights with cones, wooden floor planks with glow reflection. Code neon "K.O. CLUB".

## Layering (per stage)
Each layer is a full 1280×720 RGBA PNG with transparency, stacked in stage_bg.gd:
1. `<stage>_far.png` — sky + distant silhouettes
2. `<stage>_mid.png` — wall/buildings/props
3. `<stage>_near.png` — floor + reflections + near detail

9 PNGs total in `assets/backgrounds/original/`.

## Constraints / test contracts
- `stage_bg` node must keep children named **"Neon"** and **"Lamp"** (test_step8).
- `set_theme(t, loop)` signature unchanged; main.gd calls it unchanged.
- Gameplay lane (y 430–600) stays clear of baked collision cues; floor art only.
- Filtering NEAREST, no mipmaps (pixel art).
- asset_report must pass size/alpha on all 9 PNGs.
- All 13 smoke suites stay green.

## Approach rationale
Code generation chosen because AI credits are unavailable and the user picked "from scratch".
Structured pixel patterns (bricks, windows, planks, gradients) suit procedural drawing far better
than character anatomy did; richer noise, multi-tone bricks and reflections avoid the flat look.
