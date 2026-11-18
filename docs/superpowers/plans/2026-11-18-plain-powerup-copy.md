# Plain Power-Up Copy Implementation Plan

**Goal:** Rewrite power-up descriptions/category badges in plain English; no effect changes; 16 suites green.

**Architecture:** Edit `powerup_data.gd` desc strings + add `cat_label`; edit `shop_ui.gd` to display `cat_label` while `_cat_color` keeps internal cat keys.

**Spec:** `docs/superpowers/specs/2026-11-18-plain-powerup-copy-design.md`

### Task 1
- [ ] Step 1: Rewrite descs + add cat_label in powerup_data.gd; wire cat_label in shop_ui.gd
- [ ] Step 2: Screenshot shop, run 16 suites, commit
