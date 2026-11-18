# Per-Hand Attack Animation Director Implementation Plan

**Goal:** Distinct attack FX/pose/callout per poker hand on cash-in; 14 suites green.

**Architecture:** Extend CombatManager `cash_in_resolved` signal with `hand_type: int`. In main.gd
add `_play_hand_anim(type)` + helpers `_spawn_hand_slash`, `_burst`, `_callout_style`, mapping table.
`_on_cash_resolved` calls it. No gameplay change.

**Tech Stack:** Godot 4.7 GDScript (Sprite2D, Tween, ColorRect particles).
**Spec:** `docs/superpowers/specs/2026-11-18-per-hand-attack-animations-design.md`

### Task 1: Signal + director
- [ ] Step 1: Add hand_type to signal + emit in combat_manager.gd
- [ ] Step 2: Implement mapping + director helpers in main.gd
- [ ] Step 3: Add test_step15 (signal carries type, no crash on all 9), run 15 suites, commit
