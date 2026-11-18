# Simplify Player Status HUD Implementation Plan

**Goal:** Remove combo_label + deck_label from HUD (creation, refs, update sites), keep pips/seal/HP, all 13 suites green.

**Architecture:** In `main.gd` remove var declarations, _build creation blocks, `_fit_ui` positioning,
and text-setting sites for combo_label/deck_label. Keep `_refresh_counters` for pips (drop the
deck_label.text line). Screenshot + tests + commit.

**Spec:** `docs/superpowers/specs/2026-11-18-simple-status-hud-design.md`

### Task 1: Remove elements
- [ ] Step 1: Remove combo_label & deck_label declarations, creation, layout, and update sites
- [ ] Step 2: Screenshot game HUD, inspect; run 13 suites; commit
