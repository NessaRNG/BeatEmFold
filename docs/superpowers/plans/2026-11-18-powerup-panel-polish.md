# Power-Up Panel Polish Implementation Plan

**Goal:** Rebuild the shop power-up section as a framed, color-coded, readable panel; keep all test contracts and 13 suites green.

**Architecture:** In `shop_ui.gd` add `powerup_frame: Panel`, rebuild `_mk_powerup_button` with
category colors + badges + stack, restructure `_build_powerup_panel` to host nodes in the frame,
retune `_layout_powerups` and `_layout` so the frame sits below buy cards and continue at bottom.

**Tech Stack:** Godot 4.7 GDScript.
**Spec:** `docs/superpowers/specs/2026-11-18-powerup-panel-polish-design.md`

### Task 1: Rebuild panel
- [ ] Step 1: Add `powerup_frame`, rebuild button/panel builders with colors + badges
- [ ] Step 2: Retune layout (frame below cards, continue at bottom)
- [ ] Step 3: Screenshot shop, inspect; run 13 suites; commit
