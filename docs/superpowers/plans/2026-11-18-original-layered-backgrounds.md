# Original Layered Backgrounds Implementation Plan

> REQUIRED SUB-SKILL: superpowers:executing-plans.

**Goal:** Generate 9 original layered background PNGs (3 stages × far/mid/near), stack them in
stage_bg.gd, keep neon/lamp test nodes, all 13 suites green.

**Architecture:** `tools/generate_original_backgrounds.py` draws each layer with Pillow
(deterministic seeds). `stage_bg.gd` loads layers as TextureRects (NEAREST) per theme, keeps
`_neon_box()` + lamp nodes and flicker logic. Regenerate, import, screenshot, test, commit.

**Tech Stack:** Python 3 + Pillow, Godot 4.7.

**Spec:** `docs/superpowers/specs/2026-11-18-original-layered-backgrounds-design.md`

## Global Constraints
- Node names "Neon"/"Lamp" preserved; `set_theme(t, loop)` unchanged.
- Lane y 430–600 stays visually clean. asset_report passes. 13 suites green.

### Task 1: Generator
- [ ] Step 1: Write `tools/generate_original_backgrounds.py` with all 3 stages × 3 layers
- [ ] Step 2: Run it, asset_report all 9 PNGs, build contact sheet, inspect

### Task 2: Integration + validation
- [ ] Step 1: Rewrite `stage_bg.gd` `_build_*` to load original layers (keep neon/lamp)
- [ ] Step 2: Godot import, screenshot alley/rooftop/bar, inspect
- [ ] Step 3: Run 13 suites, commit
