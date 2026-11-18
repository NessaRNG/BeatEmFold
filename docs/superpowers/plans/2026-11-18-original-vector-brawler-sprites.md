# Original Vector Brawler Sprites Implementation Plan

> REQUIRED SUB-SKILL: superpowers:executing-plans. Steps use `- [ ]` tracking.

**Goal:** Generate 100% original 128x96 16-frame brawler sheets from scratch with a code vector generator, integrate into Godot, keep 12 suites green.

**Architecture:** Write `tools/generate_original_brawler_assets.py` with a Painter helper and a pose-driven skeletal drawing system. Output three sheets. Point `scripts/char_sprites.gd` at them. Import + test + commit.

**Tech Stack:** Python 3 + Pillow, Godot 4.7.

**Spec:** `docs/superpowers/specs/2026-11-18-original-vector-brawler-sprites-design.md`

## Global Constraints
- Frame 128x96, 16 frames, sheets 2048x96.
- Animations: idle/walk/jab/hook/upper. No gameplay/timing changes.

### Task 1: Write generator and produce three sheets
- [ ] Step 1: Implement Painter, palettes, limb/torso/head/pose drawing in `tools/generate_original_brawler_assets.py`
- [ ] Step 2: Run it, verify sheets are 2048x96 with alpha via asset_report
- [ ] Step 3: Build a contact sheet and visually inspect proportion/poses

### Task 2: Integrate and verify
- [ ] Step 1: Repoint `scripts/char_sprites.gd` to original sheets
- [ ] Step 2: Godot headless import
- [ ] Step 3: Run 12 smoke tests, confirm 100% pass
- [ ] Step 4: Commit
