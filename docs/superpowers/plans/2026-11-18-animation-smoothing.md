# Animation Smoothing Implementation Plan

> REQUIRED SUB-SKILL: superpowers:executing-plans.

**Goal:** Smooth the brawler animations via more eased in-between frames plus baked after-image smear, keep 12 suites green.

**Architecture:** Extend `tools/generate_original_brawler_assets.py` with interpolated intermediate poses and ghost after-images; regenerate 3 sheets (3712x96); update frame ranges + per-frame durations in `scripts/char_sprites.gd`; import + test + commit.

**Tech Stack:** Python 3 + Pillow, Godot 4.7.

**Spec:** `docs/superpowers/specs/2026-11-18-animation-smoothing-design.md`

## Global Constraints
- Frame 128x96, 29 frames, sheet 3712x96.
- Animation names unchanged. hit -> frame 1.

### Task 1: Generator with eased poses + smear
- [ ] Step 1: Add mid/recoil poses, ghost after-image rendering, expand frames() to 29 layouts
- [ ] Step 2: Regenerate and verify sheets 3712x96 with alpha
- [ ] Step 3: Contact sheet visual inspection

### Task 2: Engine integration
- [ ] Step 1: Update frame ranges + durations in char_sprites.gd
- [ ] Step 2: Godot import, 12 suites, commit
